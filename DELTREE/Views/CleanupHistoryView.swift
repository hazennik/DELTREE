import SwiftUI

struct CleanupHistoryView: View {
    @Environment(\.appTheme) private var theme

    var cleanupHistory: [CleanupHistoryRecord]
    var deltaHistory: [StorageDeltaRecord]

    var body: some View {
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
        .navigationTitle("Cleanup History")
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .foregroundStyle(theme.primaryText)
    }
}
