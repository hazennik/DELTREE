import Foundation

struct FileSizeScanBudget: Equatable, Sendable {
    var maxEntryCount: Int?

    static let production = FileSizeScanBudget(maxEntryCount: 100_000)
    static let unbounded = FileSizeScanBudget(maxEntryCount: nil)
}

struct FileSizeResult: Equatable, Sendable {
    var bytes: Int64
    var unreadablePaths: [String]
    var scannedEntryCount: Int = 0
    var isComplete: Bool = true
    var incompleteReason: String?
}
