import Foundation

enum StorageDomain: String, CaseIterable, Codable, Identifiable, Sendable {
    case codexHome
    case codexWorkspaces
    case coreSimulatorDevices
    case xcTestDevices
    case derivedData
    case xcResults
    case xcodeProducts
    case deviceSupport
    case simulatorRuntimes
    case simulatorImages
    case coreSimulatorCaches
    case archives
    case swiftPackageCaches

    var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .codexHome:
            "Codex Home"
        case .codexWorkspaces:
            "Codex Workspaces"
        case .coreSimulatorDevices:
            "Simulator Devices"
        case .xcTestDevices:
            "XCTest Devices"
        case .derivedData:
            "DerivedData"
        case .xcResults:
            "Test Results"
        case .xcodeProducts:
            "Xcode Products"
        case .deviceSupport:
            "DeviceSupport"
        case .simulatorRuntimes:
            "Simulator Runtimes"
        case .simulatorImages:
            "Simulator Images"
        case .coreSimulatorCaches:
            "Simulator Caches"
        case .archives:
            "Archives"
        case .swiftPackageCaches:
            "SwiftPM Caches"
        }
    }

    nonisolated var symbolName: String {
        switch self {
        case .codexHome, .codexWorkspaces:
            "terminal"
        case .coreSimulatorDevices, .xcTestDevices:
            "iphone"
        case .derivedData, .swiftPackageCaches:
            "hammer"
        case .xcResults:
            "checklist"
        case .xcodeProducts:
            "shippingbox"
        case .deviceSupport:
            "externaldrive"
        case .simulatorRuntimes, .simulatorImages:
            "square.stack.3d.up"
        case .coreSimulatorCaches:
            "externaldrive.badge.icloud"
        case .archives:
            "archivebox"
        }
    }

    nonisolated var isCodexDomain: Bool {
        switch self {
        case .codexHome, .codexWorkspaces:
            true
        case .coreSimulatorDevices, .xcTestDevices, .derivedData, .xcResults, .xcodeProducts,
             .deviceSupport, .simulatorRuntimes, .simulatorImages, .coreSimulatorCaches,
             .archives, .swiftPackageCaches:
            false
        }
    }

    nonisolated var isXcodeGeneratedDomain: Bool {
        switch self {
        case .coreSimulatorDevices, .xcTestDevices, .derivedData, .xcResults, .xcodeProducts,
             .deviceSupport, .simulatorRuntimes, .simulatorImages, .coreSimulatorCaches,
             .archives, .swiftPackageCaches:
            true
        case .codexHome, .codexWorkspaces:
            false
        }
    }

    nonisolated var dashboardSection: DashboardSection {
        switch self {
        case .coreSimulatorDevices, .xcTestDevices:
            .simulators
        case .derivedData, .xcodeProducts, .swiftPackageCaches, .coreSimulatorCaches:
            .buildArtifacts
        case .xcResults:
            .testArtifacts
        case .simulatorRuntimes, .simulatorImages, .deviceSupport, .archives:
            .runtimesComponents
        case .codexHome, .codexWorkspaces:
            .codexTasks
        }
    }
}
