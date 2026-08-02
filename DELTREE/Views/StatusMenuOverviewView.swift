import SwiftUI

struct StatusMenuOverviewView: View {
    var footprint: StorageFootprint
    var lastCodexImpactBytes: Int64
    var hasRecentGrowth: Bool
    var isScanning: Bool
    var safeItemCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Label("DELTREE", systemImage: "leaf.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusTint)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusTint.opacity(0.14), in: Capsule())
            }

            HStack(spacing: 8) {
                StatusMenuMetricTileView(
                    title: "Total",
                    value: StorageFormatters.byteCount(footprint.totalBytes),
                    systemImage: "externaldrive",
                    tint: AppPalette.device)

                StatusMenuMetricTileView(
                    title: "Cleanable",
                    value: StorageFormatters.byteCount(footprint.reclaimableBytes),
                    systemImage: "trash",
                    tint: AppPalette.codex)
            }

            StatusMenuGaugeRowView(
                title: "Codex footprint",
                value: StorageFormatters.byteCount(footprint.codexAttributedBytes),
                detail: codexDetailText,
                systemImage: "terminal",
                tint: AppPalette.codex,
                share: footprint.totalBytes > 0 ? Double(footprint.codexAttributedBytes) / Double(footprint.totalBytes) : 0)
        }
        .padding(12)
    }

    private var statusText: String {
        if isScanning {
            return "Scanning"
        }
        if footprint.hasLowDiskSpace {
            return "Low Disk"
        }
        return "Ready"
    }

    private var statusTint: Color {
        if isScanning {
            return AppPalette.simulator
        }
        if footprint.hasLowDiskSpace {
            return AppPalette.xcode
        }
        return AppPalette.codex
    }

    private var codexDetailText: String {
        if hasRecentGrowth {
            return "Last Codex run +\(StorageFormatters.byteCount(lastCodexImpactBytes))"
        }

        return "\(safeItemCount) \(safeItemCount == 1 ? "safe item" : "safe items") ready for review"
    }
}
