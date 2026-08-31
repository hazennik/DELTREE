import Foundation

struct StorageRootCatalog: Sendable {
    var homeDirectory: URL

    var documentsCodexRoot: URL {
        homeDirectory.appendingPathComponent("Documents/Codex", isDirectory: true)
    }

    static func live(fileManager: FileManager = .default) -> StorageRootCatalog {
        StorageRootCatalog(homeDirectory: fileManager.homeDirectoryForCurrentUser)
    }

    func roots(configuration: StorageScanConfiguration = .standard) -> [StorageDomain: [URL]] {
        var roots: [StorageDomain: [URL]] = [
            .codexHome: [
                homeDirectory.appendingPathComponent(".codex", isDirectory: true),
            ],
            .codexWorkspaces: [],
            .coreSimulatorDevices: [
                homeDirectory.appendingPathComponent("Library/Developer/CoreSimulator/Devices", isDirectory: true),
            ],
            .xcTestDevices: [
                homeDirectory.appendingPathComponent("Library/Developer/XCTestDevices", isDirectory: true),
            ],
            .derivedData: [
                homeDirectory.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true),
            ],
            .xcResults: [
                homeDirectory.appendingPathComponent("Library/Developer/Xcode/Products", isDirectory: true),
            ],
            .xcodeProducts: [
                homeDirectory.appendingPathComponent("Library/Developer/Xcode/Products", isDirectory: true),
            ],
            .deviceSupport: [
                homeDirectory.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport", isDirectory: true),
            ],
            .simulatorRuntimes: [
                URL(fileURLWithPath: "/Library/Developer/CoreSimulator/Profiles/Runtimes", isDirectory: true),
                homeDirectory.appendingPathComponent("Library/Developer/CoreSimulator/Profiles/Runtimes", isDirectory: true),
            ],
            .simulatorImages: [
                URL(fileURLWithPath: "/Library/Developer/CoreSimulator/Images", isDirectory: true),
                homeDirectory.appendingPathComponent("Library/Developer/CoreSimulator/Images", isDirectory: true),
            ],
            .coreSimulatorCaches: [
                homeDirectory.appendingPathComponent("Library/Developer/CoreSimulator/Caches", isDirectory: true),
            ],
            .archives: [
                homeDirectory.appendingPathComponent("Library/Developer/Xcode/Archives", isDirectory: true),
            ],
            .swiftPackageCaches: [
                homeDirectory.appendingPathComponent("Library/Caches/org.swift.swiftpm", isDirectory: true),
                homeDirectory.appendingPathComponent("Library/org.swift.swiftpm", isDirectory: true),
                homeDirectory.appendingPathComponent(".swiftpm", isDirectory: true),
            ],
        ]

        if configuration.scanDocumentsCodex {
            roots[.codexWorkspaces, default: []].append(documentsCodexRoot)
            roots[.xcResults, default: []].append(documentsCodexRoot)
        }

        let customRoots = configuration.customScanRoots.map { URL(fileURLWithPath: $0, isDirectory: true) }
        if customRoots.isEmpty == false {
            roots[.codexWorkspaces, default: []].append(contentsOf: customRoots)
        }

        return roots
    }

    func watchRoots(configuration: StorageScanConfiguration = .standard) -> [String] {
        Array(Set(roots(configuration: configuration).values
            .flatMap { $0 }
            .map { $0.standardizedFileURL.path }))
            .sorted()
    }
}
