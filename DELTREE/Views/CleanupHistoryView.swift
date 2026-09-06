import SwiftUI

struct CleanupHistoryView: View {
    @Environment(\.appTheme) private var theme

    var cleanupHistory: [CleanupHistoryRecord]
    var deltaHistory: [StorageDeltaRecord]

    var body: some View {
        Group {
            if theme.isClassic {
                classicHistory
            } else {
                modernHistory
            }
        }
        .navigationTitle("Cleanup History")
        .background(theme.background)
        .foregroundStyle(theme.primaryText)
    }

    private var modernHistory: some View {
        List {
            Section("Cleanup History") {
                if cleanupHistory.isEmpty {
                    ContentUnavailableView("No Cleanup History", systemImage: "trash", description: Text("Cleanup records will appear after approved actions run."))
                } else {
                    ForEach(cleanupHistory) { record in
                        DisclosureGroup {
                            CleanupRecordDetailsView(record: record)
                        } label: {
                            CleanupRecordSummaryView(record: record)
                        }
                    }
                }
            }

            Section("Recent Growth") {
                if deltaHistory.isEmpty {
                    Text("No growth records yet.")
                        .foregroundStyle(theme.secondaryText)
                } else {
                    ForEach(deltaHistory) { record in
                        HStack {
                            Label("Storage delta", systemImage: "plus.circle")
                            Text(record.capturedAt, format: .dateTime.month().day().hour().minute())
                            Spacer()
                            Text("Codex impact \(StorageFormatters.byteCount(record.codexImpactBytes))")
                                .foregroundStyle(theme.secondaryText)
                            Text("+\(StorageFormatters.byteCount(record.addedBytes + record.changedBytes))")
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var classicHistory: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ClassicSection("Cleanup History") {
                    if cleanupHistory.isEmpty {
                        Text("NO CLEANUP HISTORY.")
                            .font(theme.font(.caption))
                            .foregroundStyle(theme.secondaryText)
                    } else {
                        ForEach(cleanupHistory) { record in
                            DisclosureGroup {
                                CleanupRecordDetailsView(record: record, isClassic: true)
                            } label: {
                                CleanupRecordSummaryView(record: record, isClassic: true)
                            }
                        }
                    }
                }

                ClassicSection("Recent Growth") {
                    if deltaHistory.isEmpty {
                        Text("NO GROWTH RECORDS.")
                            .font(theme.font(.caption))
                            .foregroundStyle(theme.secondaryText)
                    } else {
                        ForEach(deltaHistory) { record in
                            HStack {
                                Text(theme.classicGlyph(for: "plus.circle"))
                                    .foregroundStyle(theme.normalTint)
                                Text("STORAGE DELTA")
                                Text(record.capturedAt, format: .dateTime.month().day().hour().minute())
                                Spacer()
                                Text("CODEX IMPACT \(StorageFormatters.byteCount(record.codexImpactBytes))")
                                    .foregroundStyle(theme.secondaryText)
                                Text("+\(StorageFormatters.byteCount(record.addedBytes + record.changedBytes))")
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CleanupRecordSummaryView: View {
    @Environment(\.appTheme) private var theme

    var record: CleanupHistoryRecord
    var isClassic = false

    var body: some View {
        HStack(spacing: 8) {
            if isClassic {
                Text(theme.classicGlyph(for: "trash"))
                    .foregroundStyle(theme.secondaryText)
            } else {
                Image(systemName: "trash")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(isClassic ? record.status.uppercased() : record.status)
                Text(record.performedAt, format: .dateTime.month().day().hour().minute())
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(StorageFormatters.byteCount(record.totalBytes))
                    .monospacedDigit()
                Text(summaryCount)
                    .font(theme.font(.caption))
                    .foregroundStyle(record.failedCount > 0 ? theme.warning : theme.secondaryText)
            }
        }
    }

    private var summaryCount: String {
        let value = "\(record.itemCount) action(s), \(record.failedCount) failed, \(record.skippedCount) skipped"
        return isClassic ? value.uppercased() : value
    }
}

struct CleanupRecordDetailsView: View {
    @Environment(\.appTheme) private var theme

    var record: CleanupHistoryRecord
    var isClassic = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailSection(title: "Completed", paths: record.completedPaths, tint: theme.normalTint)
            detailSection(title: "Skipped", paths: record.skippedPaths, tint: theme.warning)
            if record.errors.isEmpty == false {
                detailHeading("Failed")
                ForEach(record.errors.sorted(by: { $0.key < $1.key }), id: \.key) { path, reason in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(path)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                        Text(reason)
                            .font(theme.font(.caption))
                            .foregroundStyle(theme.warning)
                            .textSelection(.enabled)
                    }
                }
            }
            if record.completedPaths.isEmpty, record.skippedPaths.isEmpty, record.errors.isEmpty {
                Text(isClassic ? "NO PATH DETAILS WERE RECORDED." : "No path details were recorded.")
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .padding(.vertical, 6)
        .padding(.leading, 20)
    }

    @ViewBuilder
    private func detailSection(title: String, paths: [String], tint: Color) -> some View {
        if paths.isEmpty == false {
            detailHeading(title)
            ForEach(paths, id: \.self) { path in
                Text(path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(tint)
                    .textSelection(.enabled)
            }
        }
    }

    private func detailHeading(_ title: String) -> some View {
        Text(isClassic ? title.uppercased() : title)
            .font(theme.font(.caption).weight(.semibold))
            .foregroundStyle(theme.secondaryText)
    }
}
