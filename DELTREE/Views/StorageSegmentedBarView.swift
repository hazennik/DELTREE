import SwiftUI

struct StorageSegmentedBarView: View {
    var breakdowns: [StorageDomainBreakdown]
    var totalBytes: Int64

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(breakdowns) { breakdown in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(for: breakdown.domain))
                        .frame(width: max(4, proxy.size.width * breakdown.share(of: totalBytes)))
                        .help("\(breakdown.domain.displayName): \(StorageFormatters.byteCount(breakdown.bytes))")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
        .accessibilityLabel("Storage breakdown")
    }

    private func color(for domain: StorageDomain) -> Color {
        switch domain {
        case .codexHome, .codexWorkspaces:
            .green
        case .coreSimulatorDevices, .xcTestDevices:
            .blue
        case .derivedData, .xcodeProducts, .swiftPackageCaches, .coreSimulatorCaches:
            .orange
        case .xcResults:
            .purple
        case .deviceSupport, .simulatorRuntimes, .simulatorImages:
            .teal
        case .archives:
            .gray
        }
    }
}
