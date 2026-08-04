import Foundation

enum DistributionChannel: String, CaseIterable, Equatable, Sendable {
    case developerID = "developer-id"
    case homebrew
    case debug
    case unknown

    static let infoPlistKey = "DELTREEDistributionChannel"

    init(infoDictionaryValue value: String?) {
        guard let value else {
            self = .unknown
            return
        }

        switch value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
        {
        case "developer-id", "developerid":
            self = .developerID
        case "homebrew":
            self = .homebrew
        case "debug":
            self = .debug
        default:
            self = .unknown
        }
    }

    static func current(bundle: Bundle = .main) -> DistributionChannel {
        let value = bundle.object(forInfoDictionaryKey: infoPlistKey) as? String
        let channel = DistributionChannel(infoDictionaryValue: value)
        if channel != .unknown {
            return channel
        }

        #if DEBUG
        return .debug
        #else
        return .unknown
        #endif
    }

    var allowsSparkleUpdates: Bool {
        switch self {
        case .developerID, .debug:
            true
        case .homebrew, .unknown:
            false
        }
    }
}
