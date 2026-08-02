import SwiftUI

struct StorageBreakdownMenuView: View {
    var footprint: StorageFootprint

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StorageSegmentedBarView(
                breakdowns: Array(footprint.domainBreakdowns.prefix(6)),
                totalBytes: footprint.totalBytes)
                .frame(height: 10)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(footprint.domainBreakdowns.prefix(4)) { breakdown in
                    StatusMenuGaugeRowView(
                        title: breakdown.domain.displayName,
                        value: StorageFormatters.byteCount(breakdown.bytes),
                        detail: nil,
                        systemImage: breakdown.domain.symbolName,
                        tint: color(for: breakdown.domain),
                        share: breakdown.share(of: footprint.totalBytes))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .clipped()
    }

    private func color(for domain: StorageDomain) -> Color {
        switch domain {
        case .codexHome, .codexWorkspaces:
            .green
        case .coreSimulatorDevices, .xcTestDevices:
            .blue
        case .derivedData, .swiftPackageCaches, .coreSimulatorCaches:
            .orange
        case .xcResults:
            .purple
        case .xcodeProducts:
            .mint
        case .deviceSupport, .simulatorRuntimes, .simulatorImages:
            .teal
        case .archives:
            .gray
        }
    }
}
