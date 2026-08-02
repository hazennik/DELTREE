import Foundation
import SwiftData

@Model
final class AttributionEventRecord {
    var id: UUID
    var observedAt: Date
    var owner: String
    var confidence: Double
    var encodedPaths: Data?

    @MainActor
    init(observedAt: Date, owner: OwnerAttribution, confidence: Double, paths: [String]) {
        id = UUID()
        self.observedAt = observedAt
        self.owner = owner.rawValue
        self.confidence = confidence
        encodedPaths = try? JSONEncoder.storage.encode(paths)
    }
}
