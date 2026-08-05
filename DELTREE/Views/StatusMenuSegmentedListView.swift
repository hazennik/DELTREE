import SwiftUI

struct StatusMenuSegment: Identifiable {
    var id: String
    var title: String
    var value: String
    var detail: String?
    var systemImage: String
    var tint: Color
    var bytes: Int64
}

struct StatusMenuSegmentedListView: View {
    @Environment(\.appTheme) private var theme

    var segments: [StatusMenuSegment]
    var totalBytes: Int64

    private let segmentSpacing: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            segmentedBar
                .frame(height: theme.isClassic ? 18 : 8)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(visibleSegments) { segment in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: theme.isClassic ? 0 : 2)
                            .fill(segment.tint)
                            .frame(width: 8, height: 16)

                        Label(segment.title, systemImage: segment.systemImage)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 0) {
                            Text(segment.value)
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            if let detail = segment.detail {
                                Text(detail)
                                    .foregroundStyle(theme.secondaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                        }
                    }
                }
            }
            .font(theme.font(.caption))
            .foregroundStyle(theme.primaryText)
        }
    }

    private var visibleSegments: [StatusMenuSegment] {
        segments.filter { $0.bytes > 0 }
    }

    private var segmentedBar: some View {
        GeometryReader { proxy in
            if theme.isClassic {
                classicBlockMeter(availableWidth: proxy.size.width)
            } else {
                let widths = segmentWidths(availableWidth: proxy.size.width)

                HStack(spacing: segmentSpacing) {
                    ForEach(Array(visibleSegments.enumerated()), id: \.element.id) { index, segment in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(segment.tint)
                            .frame(width: widths[index])
                            .help("\(segment.title): \(segment.value)")
                    }
                }
                .frame(width: proxy.size.width, alignment: .leading)
                .clipped()
            }
        }
        .background(theme.isClassic ? Color.clear : theme.panelFill, in: RoundedRectangle(cornerRadius: theme.panelCornerRadius))
        .clipped()
    }

    private func classicBlockMeter(availableWidth: CGFloat) -> some View {
        let blockCount = max(10, min(38, Int(availableWidth / 8)))
        let counts = blockCounts(totalBlocks: blockCount)

        return ZStack(alignment: .leading) {
            Text(String(repeating: "░", count: blockCount))
                .foregroundStyle(theme.mutedText)

            HStack(spacing: 0) {
                ForEach(Array(visibleSegments.enumerated()), id: \.element.id) { index, segment in
                    Text(String(repeating: "█", count: counts[index]))
                        .foregroundStyle(segment.tint)
                        .help("\(segment.title): \(segment.value)")
                }
            }
        }
        .font(theme.font(.caption))
        .monospaced()
        .frame(width: availableWidth, alignment: .leading)
        .clipped()
    }

    private func segmentWidths(availableWidth: CGFloat) -> [CGFloat] {
        guard totalBytes > 0, availableWidth > 0, visibleSegments.isEmpty == false else {
            return []
        }

        let spacingWidth = CGFloat(max(0, visibleSegments.count - 1)) * segmentSpacing
        let drawableWidth = max(0, availableWidth - spacingWidth)
        return visibleSegments.map { segment in
            max(0, drawableWidth * Double(segment.bytes) / Double(totalBytes))
        }
    }

    private func blockCounts(totalBlocks: Int) -> [Int] {
        guard totalBytes > 0, totalBlocks > 0, visibleSegments.isEmpty == false else {
            return []
        }

        var counts = visibleSegments.map { segment in
            Int((Double(totalBlocks) * Double(segment.bytes) / Double(totalBytes)).rounded())
        }
        let total = counts.reduce(0, +)
        if total > totalBlocks, let maxIndex = counts.indices.max(by: { counts[$0] < counts[$1] }) {
            counts[maxIndex] = max(0, counts[maxIndex] - (total - totalBlocks))
        }
        return counts
    }
}
