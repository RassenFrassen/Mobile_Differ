import SwiftUI

struct CustomSourcesView: View {
    @State private var customSources: [CustomMDMSource] = []
    @State private var showAddSheet = false
    @State private var editingSource: CustomMDMSource?
    
    var body: some View {
        List {
            Section {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Custom Source", systemImage: "plus.circle.fill")
                }
            }
            
            if customSources.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Custom Sources",
                        systemImage: "doc.badge.plus",
                        description: Text("Add your own MDM documentation repositories to supplement the built-in sources.")
                    )
                }
            } else {
                Section("Your Sources") {
                    ForEach(customSources) { source in
                        CustomSourceRow(source: source) {
                            editingSource = source
                        } onToggle: {
                            Task {
                                await CustomSourceService.shared.toggleEnabled(source.id)
                                await loadSources()
                            }
                        } onDelete: {
                            Task {
                                await CustomSourceService.shared.removeSource(source.id)
                                await loadSources()
                            }
                        }
                    }
                }
            }
            
            Section {
                Text("Custom sources allow you to add your own MDM documentation repositories. The app will attempt to parse and index compatible documentation formats.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About Custom Sources")
            }
        }
        .navigationTitle("Custom Sources")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet) {
            AddCustomSourceView { newSource in
                Task {
                    try? await CustomSourceService.shared.addSource(newSource)
                    await loadSources()
                }
            }
        }
        .sheet(item: $editingSource) { source in
            EditCustomSourceView(source: source) { updatedSource in
                Task {
                    try? await CustomSourceService.shared.updateSource(updatedSource)
                    await loadSources()
                }
            }
        }
        .task {
            await loadSources()
        }
    }
    
    private func loadSources() async {
        customSources = await CustomSourceService.shared.getSources()
    }
}

// MARK: - Custom Source Row

struct CustomSourceRow: View {
    let source: CustomMDMSource
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: source.icon)
                .font(.title3)
                .foregroundStyle(source.isEnabled ? .blue : .secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name)
                    .font(.body.weight(.medium))
                
                Text(source.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                if let lastFetched = source.lastFetched {
                    Text("Last updated: \(lastFetched, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { source.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}

// MARK: - Add Custom Source

struct AddCustomSourceView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (CustomMDMSource) -> Void
    
    @State private var name = ""
    @State private var repoURL = ""
    @State private var description = ""
    @State private var selectedIcon = "doc.text"
    @State private var sourceType: CustomSourceType = .github
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let iconOptions = [
        "doc.text", "doc.badge.gearshape", "link", "globe",
        "externaldrive.badge.checkmark", "folder", "server.rack"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Source Information") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("Repository URL", text: $repoURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Type") {
                    Picker("Source Type", selection: $sourceType) {
                        Text("GitHub Repository").tag(CustomSourceType.github)
                        Text("Web URL").tag(CustomSourceType.url)
                        Text("Local Files").tag(CustomSourceType.local)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                    HapticService.lightImpact()
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(selectedIcon == icon ? .blue : .secondary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            selectedIcon == icon ? Color.blue.opacity(0.15) : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add Custom Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveSource()
                    }
                    .disabled(name.isEmpty || repoURL.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveSource() {
        guard !name.isEmpty, !repoURL.isEmpty else { return }
        
        // Basic URL validation
        guard URL(string: repoURL) != nil else {
            errorMessage = "Please enter a valid URL"
            showError = true
            return
        }
        
        let source = CustomMDMSource(
            name: name,
            repoURL: repoURL,
            description: description,
            icon: selectedIcon,
            sourceType: sourceType
        )
        
        onSave(source)
        dismiss()
    }
}

// MARK: - Edit Custom Source

struct EditCustomSourceView: View {
    @Environment(\.dismiss) private var dismiss
    let source: CustomMDMSource
    let onSave: (CustomMDMSource) -> Void
    
    @State private var name: String
    @State private var repoURL: String
    @State private var description: String
    @State private var selectedIcon: String
    @State private var sourceType: CustomSourceType
    
    private let iconOptions = [
        "doc.text", "doc.badge.gearshape", "link", "globe",
        "externaldrive.badge.checkmark", "folder", "server.rack"
    ]
    
    init(source: CustomMDMSource, onSave: @escaping (CustomMDMSource) -> Void) {
        self.source = source
        self.onSave = onSave
        _name = State(initialValue: source.name)
        _repoURL = State(initialValue: source.repoURL)
        _description = State(initialValue: source.description)
        _selectedIcon = State(initialValue: source.icon)
        _sourceType = State(initialValue: source.sourceType)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Source Information") {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("Repository URL", text: $repoURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Type") {
                    Picker("Source Type", selection: $sourceType) {
                        Text("GitHub Repository").tag(CustomSourceType.github)
                        Text("Web URL").tag(CustomSourceType.url)
                        Text("Local Files").tag(CustomSourceType.local)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                    HapticService.lightImpact()
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(selectedIcon == icon ? .blue : .secondary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            selectedIcon == icon ? Color.blue.opacity(0.15) : Color.clear,
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Edit Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSource()
                    }
                    .disabled(name.isEmpty || repoURL.isEmpty)
                }
            }
        }
    }
    
    private func saveSource() {
        var updatedSource = source
        updatedSource.name = name
        updatedSource.repoURL = repoURL
        updatedSource.description = description
        updatedSource.icon = selectedIcon
        updatedSource.sourceType = sourceType
        
        onSave(updatedSource)
        dismiss()
    }
}
