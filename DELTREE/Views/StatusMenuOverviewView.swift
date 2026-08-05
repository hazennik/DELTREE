import SwiftUI

struct StatusMenuOverviewView: View {
    @Environment(\.appTheme) private var theme

    var footprint: StorageFootprint
    var lastCodexImpactBytes: Int64
    var hasRecentGrowth: Bool
    var isScanning: Bool
    var safeItemCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Label("DELTREE", systemImage: "leaf.fill")
                    .font(theme.font(.headline))
                    .foregroundStyle(theme.primaryText)

                Spacer(minLength: 8)

                Text(statusText)
                    .font(theme.font(.caption))
                    .foregroundStyle(statusTint)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusTint.opacity(theme.isClassic ? 0.22 : 0.14), in: RoundedRectangle(cornerRadius: theme.isClassic ? 0 : 10))
            }

            HStack(spacing: 8) {
                StatusMenuMetricTileView(
                    title: "Total",
                    value: StorageFormatters.byteCount(footprint.totalBytes),
                    systemImage: "externaldrive",
                    tint: theme.domainTint(.deviceSupport))

                StatusMenuMetricTileView(
                    title: "Cleanable",
                    value: StorageFormatters.byteCount(footprint.reclaimableBytes),
                    systemImage: "trash",
                    tint: theme.safe)
            }

            StatusMenuGaugeRowView(
                title: "Codex footprint",
                value: StorageFormatters.byteCount(footprint.codexAttributedBytes),
                detail: codexDetailText,
                systemImage: "terminal",
                tint: theme.safe,
                share: footprint.totalBytes > 0 ? Double(footprint.codexAttributedBytes) / Double(footprint.totalBytes) : 0)
        }
        .padding(12)
        .background(theme.background)
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
            return theme.accent
        }
        if footprint.hasLowDiskSpace {
            return theme.warning
        }
        return theme.safe
    }

    private var codexDetailText: String {
        if hasRecentGrowth {
            return "Last Codex run +\(StorageFormatters.byteCount(lastCodexImpactBytes))"
        }

        return "\(safeItemCount) \(safeItemCount == 1 ? "safe item" : "safe items") ready for review"
    }
}
