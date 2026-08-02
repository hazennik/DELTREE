import Foundation

enum SafetyClassification: String, CaseIterable, Codable, Sendable {
    case safeToTrash
    case probablySafe
    case reviewRecommended
    case keep
    case unknown

    nonisolated var displayName: String {
        switch self {
        case .safeToTrash:
            "Safe to Remove"
        case .probablySafe:
            "Probably Safe"
        case .reviewRecommended:
            "Review First"
        case .keep:
            "Do Not Remove"
        case .unknown:
            "Unknown"
        }
    }

    nonisolated var sortPriority: Int {
        switch self {
        case .safeToTrash:
            0
        case .probablySafe:
            1
        case .reviewRecommended:
            2
        case .unknown:
            3
        case .keep:
            4
        }
    }
}
