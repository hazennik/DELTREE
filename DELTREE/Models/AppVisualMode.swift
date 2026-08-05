import Foundation

enum AppVisualMode: String, CaseIterable, Identifiable, Sendable {
    case classic
    case modern

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .classic:
            "Classic"
        case .modern:
            "Modern"
        }
    }
}
