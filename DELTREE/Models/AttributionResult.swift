import Foundation

struct AttributionResult: Equatable, Sendable {
    var owner: OwnerAttribution
    var confidence: Double
    var reason: String
}
