import Foundation

struct StorageScanConfiguration: Equatable, Sendable {
    var staleAgeDays: Int
    var staleXCTestDeviceDays: Int
    var staleXCResultDays: Int
    var staleCodexWorkspaceDays: Int
    var keepLastTestRuns: Int
    var keepSimulatorsUsedWithinDays: Int
    var neverTouchArchives: Bool
    var scanDocumentsCodex: Bool
    var excludedPaths: Set<String>
    var customScanRoots: [String]
    var manualOverrides: [String: ManualStorageOverride]

    static let standard = StorageScanConfiguration(
        staleAgeDays: 14,
        staleXCTestDeviceDays: 14,
        staleXCResultDays: 14,
        staleCodexWorkspaceDays: 7,
        keepLastTestRuns: 5,
        keepSimulatorsUsedWithinDays: 14,
        neverTouchArchives: true,
        scanDocumentsCodex: true,
        excludedPaths: [],
        customScanRoots: [],
        manualOverrides: [:])

    func isExcluded(_ path: String) -> Bool {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        return excludedPaths.contains { excludedPath in
            standardizedPath == excludedPath || standardizedPath.hasPrefix(excludedPath + "/")
        }
    }

    func manualOverride(for path: String) -> ManualStorageOverride? {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        if let exact = manualOverrides[standardizedPath] {
            return exact
        }
        return manualOverrides.values.first { override in
            standardizedPath.hasPrefix(override.path + "/")
        }
    }
}
