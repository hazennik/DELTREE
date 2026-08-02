import Foundation

enum OwnerAttribution: String, CaseIterable, Codable, Sendable {
    case codex
    case xcodeViaCodex
    case xcode
    case user
    case unknown

    nonisolated var displayName: String {
        switch self {
        case .codex:
            "Codex"
        case .xcodeViaCodex:
            "Xcode via Codex"
        case .xcode:
            "Xcode"
        case .user:
            "User"
        case .unknown:
            "Unknown"
        }
    }
}
