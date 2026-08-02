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
    var segments: [StatusMenuSegment]
    var totalBytes: Int64

    private let segmentSpacing: CGFloat = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            segmentedBar
                .frame(height: 8)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(visibleSegments) { segment in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
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
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                        }
                    }
                }
            }
            .font(.caption)
        }
    }

    private var visibleSegments: [StatusMenuSegment] {
        segments.filter { $0.bytes > 0 }
    }

    private var segmentedBar: some View {
        GeometryReader { proxy in
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
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
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
}
