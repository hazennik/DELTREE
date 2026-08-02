import SwiftUI

struct StorageBreakdownMenuView: View {
    var footprint: StorageFootprint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StorageSegmentedBarView(breakdowns: Array(footprint.domainBreakdowns.prefix(6)), totalBytes: footprint.totalBytes)
                .frame(height: 10)

            HStack(spacing: 12) {
                Label(StorageFormatters.byteCount(footprint.reclaimableBytes), systemImage: "trash")
                    .help("Safe to remove after confirmation")
                Label(StorageFormatters.byteCount(footprint.reviewBytes), systemImage: "exclamationmark.triangle")
                    .help("Review before cleanup")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 300)
    }
}
