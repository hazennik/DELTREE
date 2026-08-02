import SwiftUI

struct StorageBreakdownPanelView: View {
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
                            Circle()
                                .fill(color(for: breakdown.domain))
                                .frame(width: 8, height: 8)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
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
