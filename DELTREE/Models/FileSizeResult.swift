import Foundation

struct FileSizeScanBudget: Equatable, Sendable {
    var maxEntryCount: Int?

    static let unbounded = FileSizeScanBudget(maxEntryCount: nil)
}

struct FileSizeResult: Equatable, Sendable {
    var bytes: Int64
    var unreadablePaths: [String]
    var scannedEntryCount: Int = 0
    var isComplete: Bool = true
    var incompleteReason: String?
}
