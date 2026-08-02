import Foundation
import SwiftData

@Model
final class CleanupHistoryRecord {
    var id: UUID
    var performedAt: Date
    var totalBytes: Int64
    var itemCount: Int
    var status: String
    var skippedCount: Int
    var failedCount: Int
    var initiator: String
    var encodedPaths: Data?
    var encodedSkippedPaths: Data?
    var encodedErrors: Data?

    @MainActor
    init(
        performedAt: Date,
        totalBytes: Int64,
        itemCount: Int,
        status: String,
        paths: [String],
        skippedPaths: [String] = [],
        errors: [String: String] = [:],
        initiator: String = "User")
    {
        id = UUID()
        self.performedAt = performedAt
        self.totalBytes = totalBytes
        self.itemCount = itemCount
        self.status = status
        skippedCount = skippedPaths.count
        failedCount = errors.count
        self.initiator = initiator
        encodedPaths = try? JSONEncoder.storage.encode(paths)
        encodedSkippedPaths = try? JSONEncoder.storage.encode(skippedPaths)
        encodedErrors = try? JSONEncoder.storage.encode(errors)
    }
}
