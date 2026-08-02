import Foundation

enum StorageKind: String, Codable, Sendable {
    case codexData
    case codexWorkspace
    case simulatorDevice
    case xcTestDevice
    case derivedData
    case xcResult
    case xcodeProduct
    case deviceSupport
    case simulatorRuntime
    case simulatorImage
    case archive
    case swiftPackageCache
    case coreSimulatorCache
    case codexLog
    case codexTemp
    case cache
    case unknown

    nonisolated var displayName: String {
        switch self {
        case .codexData:
            "Codex data"
        case .codexWorkspace:
            "Codex workspace"
        case .simulatorDevice:
            "Simulator device"
        case .xcTestDevice:
            "XCTest device"
        case .derivedData:
            "DerivedData"
        case .xcResult:
            "Test result"
        case .xcodeProduct:
            "Xcode product"
        case .deviceSupport:
            "Device support"
        case .simulatorRuntime:
            "Simulator runtime"
        case .simulatorImage:
            "Simulator image"
        case .archive:
            "Archive"
        case .swiftPackageCache:
            "SwiftPM cache"
        case .coreSimulatorCache:
            "Simulator cache"
        case .codexLog:
            "Codex log"
        case .codexTemp:
            "Codex temporary data"
        case .cache:
            "Cache"
        case .unknown:
            "Unknown"
        }
    }
}
