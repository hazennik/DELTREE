import Foundation
import SwiftData

@Model
final class ScanHistoryRecord {
    var id: UUID
    var capturedAt: Date
    var totalBytes: Int64
    var reclaimableBytes: Int64
    var itemCount: Int
    var encodedSnapshot: Data?

    @MainActor
    init(snapshot: StorageSnapshot) {
        id = UUID()
        capturedAt = snapshot.capturedAt
        totalBytes = snapshot.totalBytes
        reclaimableBytes = snapshot.reclaimableBytes
        itemCount = snapshot.items.count
        encodedSnapshot = try? JSONEncoder.storage.encode(snapshot)
    }
}
