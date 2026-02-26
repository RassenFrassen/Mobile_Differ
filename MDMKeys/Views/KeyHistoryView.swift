import SwiftUI

struct KeyHistoryView: View {
    let keyID: String
    let keyPath: String

    @State private var historyEntries: [KeyHistoryEntry] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading history...")
            } else if historyEntries.isEmpty {
                ContentUnavailableView(
                    "No History Available",
                    systemImage: "clock",
                    description: Text("No historical changes recorded for this key yet.")
                )
            } else {
                List {
                    ForEach(historyEntries) { entry in
                        HistoryEntryRow(entry: entry)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Version History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHistory()
        }
    }

    private func loadHistory() async {
        isLoading = true
        historyEntries = await KeyHistoryService.shared.getHistory(for: keyID)
        isLoading = false
    }
}

struct HistoryEntryRow: View {
    let entry: KeyHistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                changeTypeLabel
                Spacer()
                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(entry.keyPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            if let fields = entry.changedFields, !fields.isEmpty {
                HStack(spacing: 4) {
                    Text("Modified:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(fields, id: \.self) { field in
                        Text(field)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.12), in: Capsule())
                    }
                }
            }

            if !entry.snapshot.platforms.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.snapshot.platforms.prefix(4), id: \.self) { platform in
                        PlatformBadge(platform: platform)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var changeTypeLabel: some View {
        Group {
            switch entry.changeType {
            case .added:
                Label("Added", systemImage: "plus.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            case .updated:
                Label("Updated", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            case .removed:
                Label("Removed", systemImage: "minus.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Recent Changes View

struct RecentChangesView: View {
    @State private var recentEntries: [KeyHistoryEntry] = []
    @State private var isLoading = true
    @State private var daysFilter: Int = 30

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading recent changes...")
                } else if recentEntries.isEmpty {
                    ContentUnavailableView(
                        "No Recent Changes",
                        systemImage: "clock",
                        description: Text("No changes recorded in the last \(daysFilter) days.")
                    )
                } else {
                    List {
                        Section {
                            Picker("Time Period", selection: $daysFilter) {
                                Text("7 days").tag(7)
                                Text("30 days").tag(30)
                                Text("90 days").tag(90)
                            }
                            .pickerStyle(.segmented)
                        }

                        Section {
                            Text("\(recentEntries.count) changes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(groupedByDate.keys.sorted(by: >), id: \.self) { date in
                            Section(header: Text(dateHeader(for: date))) {
                                ForEach(groupedByDate[date] ?? []) { entry in
                                    HistoryEntryRow(entry: entry)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Recent Changes")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: daysFilter) {
                await loadRecentChanges()
            }
        }
    }

    private var groupedByDate: [Date: [KeyHistoryEntry]] {
        Dictionary(grouping: recentEntries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
    }

    private func dateHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return formatter.string(from: date)
        }
    }

    private func loadRecentChanges() async {
        isLoading = true
        recentEntries = await KeyHistoryService.shared.getRecentChanges(days: daysFilter)
        isLoading = false
    }
}
