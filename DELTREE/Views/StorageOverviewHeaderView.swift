import SwiftUI

struct StorageOverviewHeaderView: View {
    @Environment(\.appTheme) private var theme

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

                if theme.isClassic {
                    Button("[SCAN]", action: scanAction)
                        .buttonStyle(ClassicButtonStyle())
                        .disabled(isScanning)

                    Button("[CLEAN SAFE]", action: cleanupAction)
                        .buttonStyle(ClassicButtonStyle())
                        .disabled(snapshot.reclaimableBytes == 0 || isScanning)
                } else {
                    Button("Scan", systemImage: "arrow.clockwise", action: scanAction)
                        .disabled(isScanning)

                    Button("Clean Safe", systemImage: "trash", action: cleanupAction)
                        .disabled(snapshot.reclaimableBytes == 0 || isScanning)
                }
            }
        }
        .padding(14)
        .background(theme.background)
    }

    @ViewBuilder
    private var metrics: some View {
        MetricView(
            title: "Total",
            value: StorageFormatters.byteCount(snapshot.totalBytes),
            symbolName: "externaldrive",
            tint: theme.domainTint(.deviceSupport))
        MetricView(
            title: "Reclaimable",
            value: StorageFormatters.byteCount(snapshot.reclaimableBytes),
            symbolName: "trash",
            tint: theme.safe)
        MetricView(
            title: "Codex",
            value: StorageFormatters.byteCount(footprint.codexAttributedBytes),
            symbolName: "terminal",
            tint: theme.safe)
        MetricView(
            title: "Xcode",
            value: StorageFormatters.byteCount(footprint.xcodeRelatedBytes),
            symbolName: "hammer",
            tint: theme.warning)
        MetricView(
            title: "Recent Growth",
            value: StorageFormatters.byteCount(lastDelta.growthBytes),
            symbolName: "plus.circle",
            tint: theme.review)
        if let available = footprint.availableDiskBytes {
            MetricView(
                title: "Free Disk",
                value: StorageFormatters.byteCount(available),
                symbolName: footprint.hasLowDiskSpace ? "exclamationmark.triangle" : "internaldrive",
                tint: footprint.hasLowDiskSpace ? theme.warning : theme.mutedText)
        }
        MetricView(
            title: "Items",
            value: "\(snapshot.items.count)",
            symbolName: "list.bullet.rectangle",
            tint: theme.mutedText)
        MetricView(
            title: "Last Scan",
            value: snapshot.capturedAt == .distantPast ? "Never" : StorageFormatters.ageString(from: snapshot.capturedAt),
            symbolName: "clock",
            tint: theme.mutedText)
    }
}
