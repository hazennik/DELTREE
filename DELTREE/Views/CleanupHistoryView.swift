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
                        HStack {
                            Label(record.status, systemImage: "trash")
                            Text(record.performedAt, format: .dateTime.month().day().hour().minute())
                            Spacer()
                            Text("\(record.itemCount) action(s)")
                                .foregroundStyle(theme.secondaryText)
                            if record.failedCount > 0 || record.skippedCount > 0 {
                                Text("\(record.failedCount) failed, \(record.skippedCount) skipped")
                                    .foregroundStyle(theme.secondaryText)
                            }
                            Text(StorageFormatters.byteCount(record.totalBytes))
                                .monospacedDigit()
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
                            HStack {
                                Text(theme.classicGlyph(for: "trash"))
                                    .foregroundStyle(theme.secondaryText)
                                Text(record.status.uppercased())
                                Text(record.performedAt, format: .dateTime.month().day().hour().minute())
                                Spacer()
                                Text("\(record.itemCount) ACTION(S)")
                                    .foregroundStyle(theme.secondaryText)
                                if record.failedCount > 0 || record.skippedCount > 0 {
                                    Text("\(record.failedCount) FAILED, \(record.skippedCount) SKIPPED")
                                        .foregroundStyle(theme.secondaryText)
                                }
                                Text(StorageFormatters.byteCount(record.totalBytes))
                                    .monospacedDigit()
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
                                    .foregroundStyle(theme.review)
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
