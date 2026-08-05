import SwiftUI

struct StorageBreakdownPanelView: View {
    @Environment(\.appTheme) private var theme

    var footprint: StorageFootprint

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StorageSegmentedBarView(breakdowns: footprint.domainBreakdowns, totalBytes: footprint.totalBytes)
                .frame(height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()

            ScrollView(.horizontal) {
                HStack(spacing: 18) {
                    ForEach(footprint.domainBreakdowns.prefix(6)) { breakdown in
                        Label {
                            Text("\(breakdown.domain.displayName) \(StorageFormatters.byteCount(breakdown.bytes))")
                                .lineLimit(1)
                        } icon: {
                            Rectangle()
                                .fill(breakdown.domain.menuTint(in: theme))
                                .frame(width: 8, height: 8)
                        }
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .background(theme.background)
    }
}
