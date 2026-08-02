import SwiftUI

struct StorageOverviewHeaderView: View {
    var snapshot: StorageSnapshot
    var footprint: StorageFootprint
    var lastDelta: StorageDelta
    var isScanning: Bool
    var scanAction: () -> Void
    var cleanupAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            MetricView(
                title: "Total",
                value: StorageFormatters.byteCount(snapshot.totalBytes),
                symbolName: "externaldrive")
            MetricView(
                title: "Reclaimable",
                value: StorageFormatters.byteCount(snapshot.reclaimableBytes),
                symbolName: "trash")
            MetricView(
                title: "Codex",
                value: StorageFormatters.byteCount(footprint.codexAttributedBytes),
                symbolName: "terminal")
            MetricView(
                title: "Xcode",
                value: StorageFormatters.byteCount(footprint.xcodeRelatedBytes),
                symbolName: "hammer")
            MetricView(
                title: "Recent Growth",
                value: StorageFormatters.byteCount(lastDelta.growthBytes),
                symbolName: "plus.circle")
            if let available = footprint.availableDiskBytes {
                MetricView(
                    title: "Free Disk",
                    value: StorageFormatters.byteCount(available),
                    symbolName: footprint.hasLowDiskSpace ? "exclamationmark.triangle" : "internaldrive")
            }
            MetricView(
                title: "Items",
                value: "\(snapshot.items.count)",
                symbolName: "list.bullet.rectangle")
            MetricView(
                title: "Last Scan",
                value: snapshot.capturedAt == .distantPast ? "Never" : StorageFormatters.ageString(from: snapshot.capturedAt),
                symbolName: "clock")

            Spacer()

            Button("Scan", systemImage: "arrow.clockwise", action: scanAction)
                .disabled(isScanning)

            Button("Clean Safe", systemImage: "trash", action: cleanupAction)
                .disabled(snapshot.reclaimableBytes == 0 || isScanning)
        }
        .padding(14)
    }
}
