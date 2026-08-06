import SwiftUI

struct StorageBreakdownMenuView: View {
    @Environment(\.appTheme) private var theme

    var footprint: StorageFootprint

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StorageSegmentedBarView(
                breakdowns: visibleBreakdowns,
                totalBytes: footprint.totalBytes)
                .frame(height: theme.isClassic ? 18 : 10)

            VStack(alignment: .leading, spacing: 7) {
                ForEach(visibleBreakdowns) { breakdown in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: theme.isClassic ? 0 : 2)
                            .fill(theme.domainFillTint(breakdown.domain))
                            .frame(width: 8, height: 18)

                        if theme.isClassic {
                            HStack(spacing: 6) {
                                Text(theme.classicGlyph(for: breakdown.domain.symbolName))
                                    .foregroundStyle(breakdown.domain.menuTint(in: theme))
                                Text(breakdown.domain.displayName.uppercased())
                            }
                            .lineLimit(1)
                        } else {
                            Label(breakdown.domain.displayName, systemImage: breakdown.domain.symbolName)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(StorageFormatters.byteCount(breakdown.bytes))
                                .monospacedDigit()
                                .lineLimit(1)
                            Text(rowDetail(for: breakdown))
                                .font(theme.font(.caption))
                                .foregroundStyle(theme.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.primaryText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .clipped()
        .background(theme.background)
    }

    private var visibleBreakdowns: [StorageDomainBreakdown] {
        Array(footprint.domainBreakdowns.filter { $0.bytes > 0 }.prefix(6))
    }

    private func rowDetail(for breakdown: StorageDomainBreakdown) -> String {
        let percent = breakdown.share(of: footprint.totalBytes)
            .formatted(.percent.precision(.fractionLength(0)))
        let itemText = breakdown.itemCount == 1 ? "item" : "items"
        let detail = "\(breakdown.itemCount) \(itemText) - \(percent)"
        return theme.isClassic ? detail.uppercased() : detail
    }
}
