import SwiftUI

extension StorageDomain {
    var menuTint: Color {
        switch self {
        case .codexHome, .codexWorkspaces:
            AppPalette.codex
        case .coreSimulatorDevices, .xcTestDevices:
            AppPalette.simulator
        case .derivedData, .xcodeProducts, .swiftPackageCaches, .coreSimulatorCaches:
            AppPalette.xcode
        case .xcResults:
            AppPalette.results
        case .deviceSupport, .simulatorRuntimes, .simulatorImages:
            AppPalette.device
        case .archives:
            AppPalette.archive
        }
    }
}
