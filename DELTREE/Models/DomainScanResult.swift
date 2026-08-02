import Foundation

struct DomainScanResult: Sendable {
    var items: [StorageItem]
    var missingPaths: [String]
    var unreadablePaths: [String]

    static let empty = DomainScanResult(items: [], missingPaths: [], unreadablePaths: [])
}
