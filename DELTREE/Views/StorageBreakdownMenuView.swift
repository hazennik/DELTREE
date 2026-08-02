import SwiftUI

struct StorageBreakdownMenuView: View {
    var footprint: StorageFootprint

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StorageSegmentedBarView(
                breakdowns: visibleBreakdowns,
                totalBytes: footprint.totalBytes)
                .frame(height: 10)

            VStack(alignment: .leading, spacing: 7) {
                ForEach(visibleBreakdowns) { breakdown in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(breakdown.domain.menuTint)
                            .frame(width: 8, height: 18)

                        Label(breakdown.domain.displayName, systemImage: breakdown.domain.symbolName)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 1) {
                            Text(StorageFormatters.byteCount(breakdown.bytes))
                                .monospacedDigit()
                                .lineLimit(1)
                            Text(rowDetail(for: breakdown))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .clipped()
    }

    private var visibleBreakdowns: [StorageDomainBreakdown] {
        Array(footprint.domainBreakdowns.filter { $0.bytes > 0 }.prefix(6))
    }

    private func rowDetail(for breakdown: StorageDomainBreakdown) -> String {
        let percent = breakdown.share(of: footprint.totalBytes)
            .formatted(.percent.precision(.fractionLength(0)))
        return "\(breakdown.itemCount) \(breakdown.itemCount == 1 ? "item" : "items") - \(percent)"
    }
}
