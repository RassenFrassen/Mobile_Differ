import SwiftUI

struct NotificationLogView: View {
    @EnvironmentObject var appState: AppState
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if appState.mdmNotificationLog.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
            .navigationTitle("Updates")
            .toolbar {
                if !appState.mdmNotificationLog.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Clear notification log")
                    }
                }
            }
            .confirmationDialog(
                "Clear update history?",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) {
                    Task {
                        await MDMNotificationService.shared.clearLog()
                        appState.mdmNotificationLog = []
                    }
                }
            } message: {
                Text("This will remove all recorded MDM catalog update entries.")
            }
        }
        .task {
            appState.mdmNotificationLog = await MDMNotificationService.shared.loadLog()
            await appState.markNotificationsRead()
        }
    }

    private var logList: some View {
        List(appState.mdmNotificationLog) { entry in
            NavigationLink {
                NotificationEntryDetailView(entry: entry)
            } label: {
                NotificationEntryRowView(entry: entry)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Updates Yet", systemImage: "bell.slash")
        } description: {
            Text("When the MDM catalog changes, notifications will appear here.\n\nRefresh the catalog from the Keys tab to check for updates.")
        }
    }
}

// MARK: - Entry Row

struct NotificationEntryRowView: View {
    let entry: MDMNotificationLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(entry.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if entry.addedCount > 0 {
                    changeChip(count: entry.addedCount, label: "added", color: .green)
                }
                if entry.updatedCount > 0 {
                    changeChip(count: entry.updatedCount, label: "updated", color: .blue)
                }
                if entry.removedCount > 0 {
                    changeChip(count: entry.removedCount, label: "removed", color: .red)
                }
            }

            if !entry.sources.isEmpty {
                Text(entry.sources.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func changeChip(count: Int, label: String, color: Color) -> some View {
        Text("\(count) \(label)")
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Entry Detail

struct NotificationEntryDetailView: View {
    let entry: MDMNotificationLogEntry

    private var addedChanges: [MDMNotificationLogChange] {
        entry.changes.filter { $0.changeType == .added }
    }
    private var updatedChanges: [MDMNotificationLogChange] {
        entry.changes.filter { $0.changeType == .updated }
    }
    private var removedChanges: [MDMNotificationLogChange] {
        entry.changes.filter { $0.changeType == .removed }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.title)
                        .font(.title3.weight(.bold))
                    Text(entry.createdAt, format: .dateTime.day().month().year().hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        if entry.addedCount > 0 {
                            countBadge(count: entry.addedCount, label: "Added", color: .green, icon: "plus.circle.fill")
                        }
                        if entry.updatedCount > 0 {
                            countBadge(count: entry.updatedCount, label: "Updated", color: .blue, icon: "arrow.triangle.2.circlepath")
                        }
                        if entry.removedCount > 0 {
                            countBadge(count: entry.removedCount, label: "Removed", color: .red, icon: "minus.circle.fill")
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if !entry.platforms.isEmpty {
                Section("Platforms") {
                    Text(entry.platforms.joined(separator: ", "))
                        .font(.subheadline)
                }
            }

            if !entry.sources.isEmpty {
                Section("Sources") {
                    ForEach(entry.sources, id: \.self) { source in
                        Text(source)
                            .font(.subheadline)
                    }
                }
            }

            if !addedChanges.isEmpty {
                Section("Added (\(addedChanges.count))") {
                    ForEach(addedChanges) { change in
                        ChangeRowView(change: change)
                    }
                }
            }

            if !updatedChanges.isEmpty {
                Section("Updated (\(updatedChanges.count))") {
                    ForEach(updatedChanges) { change in
                        ChangeRowView(change: change)
                    }
                }
            }

            if !removedChanges.isEmpty {
                Section("Removed (\(removedChanges.count))") {
                    ForEach(removedChanges) { change in
                        ChangeRowView(change: change)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func countBadge(count: Int, label: String, color: Color, icon: String) -> some View {
        Label("\(count) \(label)", systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Change Row

struct ChangeRowView: View {
    let change: MDMNotificationLogChange

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: changeIcon)
                    .foregroundStyle(changeColor)
                    .font(.caption)
                Text(change.keyPath)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)
            }
            if let payloadName = change.payloadName {
                Text(payloadName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let detail = change.detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private var changeIcon: String {
        switch change.changeType {
        case .added: return "plus.circle"
        case .updated: return "arrow.triangle.2.circlepath"
        case .removed: return "minus.circle"
        }
    }

    private var changeColor: Color {
        switch change.changeType {
        case .added: return .green
        case .updated: return .blue
        case .removed: return .red
        }
    }
}
