import SwiftUI

struct StorageSegmentedBarView: View {
    @Environment(\.appTheme) private var theme

    var breakdowns: [StorageDomainBreakdown]
    var totalBytes: Int64

    private let segmentSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let visibleBreakdowns = breakdowns.filter { $0.bytes > 0 }
            if theme.isClassic {
                classicBlockMeter(for: visibleBreakdowns, availableWidth: proxy.size.width)
            } else {
                let widths = segmentWidths(for: visibleBreakdowns, availableWidth: proxy.size.width)

                HStack(spacing: segmentSpacing) {
                    ForEach(Array(visibleBreakdowns.enumerated()), id: \.element.id) { index, breakdown in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(breakdown.domain.menuTint(in: theme))
                            .frame(width: widths[index])
                            .help("\(breakdown.domain.displayName): \(StorageFormatters.byteCount(breakdown.bytes))")
                    }
                }
                .frame(width: proxy.size.width, alignment: .leading)
                .clipped()
            }
        }
        .background(theme.isClassic ? Color.clear : theme.panelFill, in: RoundedRectangle(cornerRadius: theme.panelCornerRadius))
        .clipped()
        .accessibilityLabel("Storage breakdown")
    }

    private func classicBlockMeter(for breakdowns: [StorageDomainBreakdown], availableWidth: CGFloat) -> some View {
        let blockCount = max(10, min(42, Int(availableWidth / 8)))
        let counts = blockCounts(for: breakdowns, totalBlocks: blockCount)

        return ZStack(alignment: .leading) {
            Text(String(repeating: "░", count: blockCount))
                .foregroundStyle(theme.mutedText)

            HStack(spacing: 0) {
                ForEach(Array(breakdowns.enumerated()), id: \.element.id) { index, breakdown in
                    Text(String(repeating: "█", count: counts[index]))
                        .foregroundStyle(breakdown.domain.menuTint(in: theme))
                        .help("\(breakdown.domain.displayName): \(StorageFormatters.byteCount(breakdown.bytes))")
                }
            }
        }
        .font(theme.font(.caption))
        .monospaced()
        .frame(width: availableWidth, alignment: .leading)
        .clipped()
    }

    private func segmentWidths(for breakdowns: [StorageDomainBreakdown], availableWidth: CGFloat) -> [CGFloat] {
        guard totalBytes > 0, availableWidth > 0, breakdowns.isEmpty == false else {
            return []
        }

        let spacingWidth = CGFloat(max(0, breakdowns.count - 1)) * segmentSpacing
        let drawableWidth = max(0, availableWidth - spacingWidth)
        return breakdowns.map { max(0, drawableWidth * $0.share(of: totalBytes)) }
    }

    private func blockCounts(for breakdowns: [StorageDomainBreakdown], totalBlocks: Int) -> [Int] {
        guard totalBytes > 0, totalBlocks > 0, breakdowns.isEmpty == false else {
            return []
        }

        var counts = breakdowns.map { breakdown in
            Int((Double(totalBlocks) * breakdown.share(of: totalBytes)).rounded())
        }
        let total = counts.reduce(0, +)
        if total > totalBlocks, let maxIndex = counts.indices.max(by: { counts[$0] < counts[$1] }) {
            counts[maxIndex] = max(0, counts[maxIndex] - (total - totalBlocks))
        }
        return counts
    }

}
