import SwiftUI

struct StatusMenuSafetyChartView: View {
    var footprint: StorageFootprint
    var safeItemCount: Int

    var body: some View {
        StatusMenuSegmentedListView(
            segments: safetySegments,
            totalBytes: safetyTotalBytes)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var safetyTotalBytes: Int64 {
        max(1, footprint.reclaimableBytes + footprint.reviewBytes + footprint.activeBytes)
    }

    private var safetySegments: [StatusMenuSegment] {
        [
            StatusMenuSegment(
                id: "safe-to-clean",
                title: "Safe to clean",
                value: StorageFormatters.byteCount(footprint.reclaimableBytes),
                detail: "\(safeItemCount) \(safeItemCount == 1 ? "item" : "items")",
                systemImage: "checkmark.circle",
                tint: .green,
                bytes: footprint.reclaimableBytes),
            StatusMenuSegment(
                id: "needs-review",
                title: "Needs review",
                value: StorageFormatters.byteCount(footprint.reviewBytes),
                detail: nil,
                systemImage: "exclamationmark.triangle",
                tint: .orange,
                bytes: footprint.reviewBytes),
            StatusMenuSegment(
                id: "active-or-kept",
                title: "Active or kept",
                value: StorageFormatters.byteCount(footprint.activeBytes),
                detail: nil,
                systemImage: "lock",
                tint: .blue,
                bytes: footprint.activeBytes),
        ]
    }
}
