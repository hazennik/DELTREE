import SwiftUI

struct StorageOverviewHeaderView: View {
    var snapshot: StorageSnapshot
    var footprint: StorageFootprint
    var lastDelta: StorageDelta
    var isScanning: Bool
    var scanAction: () -> Void
    var cleanupAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    metrics
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()

            HStack {
                Spacer()

                Button("Scan", systemImage: "arrow.clockwise", action: scanAction)
                    .disabled(isScanning)

                Button("Clean Safe", systemImage: "trash", action: cleanupAction)
                    .disabled(snapshot.reclaimableBytes == 0 || isScanning)
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private var metrics: some View {
        MetricView(
            title: "Total",
            value: StorageFormatters.byteCount(snapshot.totalBytes),
            symbolName: "externaldrive",
            tint: AppPalette.device)
        MetricView(
            title: "Reclaimable",
            value: StorageFormatters.byteCount(snapshot.reclaimableBytes),
            symbolName: "trash",
            tint: AppPalette.codex)
        MetricView(
            title: "Codex",
            value: StorageFormatters.byteCount(footprint.codexAttributedBytes),
            symbolName: "terminal",
            tint: AppPalette.codex)
        MetricView(
            title: "Xcode",
            value: StorageFormatters.byteCount(footprint.xcodeRelatedBytes),
            symbolName: "hammer",
            tint: AppPalette.xcode)
        MetricView(
            title: "Recent Growth",
            value: StorageFormatters.byteCount(lastDelta.growthBytes),
            symbolName: "plus.circle",
            tint: AppPalette.caution)
        if let available = footprint.availableDiskBytes {
            MetricView(
                title: "Free Disk",
                value: StorageFormatters.byteCount(available),
                symbolName: footprint.hasLowDiskSpace ? "exclamationmark.triangle" : "internaldrive",
                tint: footprint.hasLowDiskSpace ? AppPalette.xcode : AppPalette.neutral)
        }
        MetricView(
            title: "Items",
            value: "\(snapshot.items.count)",
            symbolName: "list.bullet.rectangle",
            tint: AppPalette.neutral)
        MetricView(
            title: "Last Scan",
            value: snapshot.capturedAt == .distantPast ? "Never" : StorageFormatters.ageString(from: snapshot.capturedAt),
            symbolName: "clock",
            tint: AppPalette.neutral)
    }
}
