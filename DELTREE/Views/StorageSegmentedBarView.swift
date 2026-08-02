import SwiftUI

struct StorageSegmentedBarView: View {
    var breakdowns: [StorageDomainBreakdown]
    var totalBytes: Int64

    private let segmentSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let visibleBreakdowns = breakdowns.filter { $0.bytes > 0 }
            let widths = segmentWidths(for: visibleBreakdowns, availableWidth: proxy.size.width)

            HStack(spacing: segmentSpacing) {
                ForEach(Array(visibleBreakdowns.enumerated()), id: \.element.id) { index, breakdown in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(breakdown.domain.menuTint)
                        .frame(width: widths[index])
                        .help("\(breakdown.domain.displayName): \(StorageFormatters.byteCount(breakdown.bytes))")
                }
            }
            .frame(width: proxy.size.width, alignment: .leading)
            .clipped()
        }
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
        .clipped()
        .accessibilityLabel("Storage breakdown")
    }

    private func segmentWidths(for breakdowns: [StorageDomainBreakdown], availableWidth: CGFloat) -> [CGFloat] {
        guard totalBytes > 0, availableWidth > 0, breakdowns.isEmpty == false else {
            return []
        }

        let spacingWidth = CGFloat(max(0, breakdowns.count - 1)) * segmentSpacing
        let drawableWidth = max(0, availableWidth - spacingWidth)
        return breakdowns.map { max(0, drawableWidth * $0.share(of: totalBytes)) }
    }

}
