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
                if theme.isClassic {
                    Text("[ DELTREE ]")
                        .font(theme.font(.headline))
                        .foregroundStyle(theme.selectionText)
                } else {
                    Label("DELTREE", systemImage: "leaf.fill")
                        .font(theme.font(.headline))
                        .foregroundStyle(theme.primaryText)
                }

                Spacer(minLength: 8)

                Text(theme.isClassic ? "[\(statusText.uppercased())]" : statusText)
                    .font(theme.font(.caption))
                    .foregroundStyle(statusTint)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background {
                        if theme.isClassic {
                            Rectangle()
                                .fill(theme.controlFill)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(statusTint.opacity(0.14))
                        }
                    }
                    .overlay {
                        if theme.isClassic {
                            Rectangle()
                                .stroke(statusTint, lineWidth: 1)
                        }
                    }
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
