import SwiftUI

extension StorageDomain {
    var menuTint: Color {
        switch self {
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
