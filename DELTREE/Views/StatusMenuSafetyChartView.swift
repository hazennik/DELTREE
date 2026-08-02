import SwiftUI

struct StatusMenuSafetyChartView: View {
    var footprint: StorageFootprint
    var safeItemCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            StatusMenuGaugeRowView(
                title: "Safe to clean",
                value: StorageFormatters.byteCount(footprint.reclaimableBytes),
                detail: "\(safeItemCount) \(safeItemCount == 1 ? "item" : "items")",
                systemImage: "checkmark.circle",
                tint: .green,
                share: share(for: footprint.reclaimableBytes))

            StatusMenuGaugeRowView(
                title: "Needs review",
                value: StorageFormatters.byteCount(footprint.reviewBytes),
                detail: nil,
                systemImage: "exclamationmark.triangle",
                tint: .orange,
                share: share(for: footprint.reviewBytes))

            StatusMenuGaugeRowView(
                title: "Active or kept",
                value: StorageFormatters.byteCount(footprint.activeBytes),
                detail: nil,
                systemImage: "lock",
                tint: .blue,
                share: share(for: footprint.activeBytes))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var safetyTotalBytes: Int64 {
        max(1, footprint.reclaimableBytes + footprint.reviewBytes + footprint.activeBytes)
    }

    private func share(for bytes: Int64) -> Double {
        Double(max(0, bytes)) / Double(safetyTotalBytes)
    }
}
