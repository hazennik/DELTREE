import Foundation
import SwiftData

@Model
final class StorageDeltaRecord {
    var id: UUID
    var capturedAt: Date
    var addedBytes: Int64
    var changedBytes: Int64
    var removedBytes: Int64
    var codexImpactBytes: Int64
    var encodedDelta: Data?

    @MainActor
    init(delta: StorageDelta) {
        id = delta.id
        capturedAt = delta.toDate
        addedBytes = delta.addedBytes
        changedBytes = delta.changedBytes
        removedBytes = delta.removedBytes
        codexImpactBytes = delta.codexImpactBytes
        encodedDelta = try? JSONEncoder.storage.encode(delta)
    }
}
