import Foundation

struct StorageSnapshot: Equatable, Codable, Sendable {
    var capturedAt: Date
    var items: [StorageItem]
    var missingPaths: [String]
    var unreadablePaths: [String]

    static let empty = StorageSnapshot(
        capturedAt: .distantPast,
        items: [],
        missingPaths: [],
        unreadablePaths: [])

    var totalBytes: Int64 {
        items.reduce(0) { $0 + max(0, $1.bytes) }
    }

    var reclaimableBytes: Int64 {
        items.filter(\.isCleanupEligible).reduce(0) { $0 + max(0, $1.bytes) }
    }

    var codexAttributedBytes: Int64 {
        items
            .filter { $0.attribution == .codex || $0.attribution == .xcodeViaCodex }
            .reduce(0) { $0 + max(0, $1.bytes) }
    }

    var xcodeRelatedBytes: Int64 {
        items
            .filter { $0.domain.isXcodeGeneratedDomain }
            .reduce(0) { $0 + max(0, $1.bytes) }
    }

    var reviewBytes: Int64 {
        items
            .filter { $0.safety == .probablySafe || $0.safety == .reviewRecommended }
            .reduce(0) { $0 + max(0, $1.bytes) }
    }

    var activeBytes: Int64 {
        items
            .filter(\.isActive)
            .reduce(0) { $0 + max(0, $1.bytes) }
    }

    var groupedDomainTotals: [StorageDomain: Int64] {
        Dictionary(grouping: items, by: \.domain).mapValues { domainItems in
            domainItems.reduce(0) { $0 + max(0, $1.bytes) }
        }
    }

    var displayFingerprint: String {
        let itemFingerprints = items
            .sorted { $0.path < $1.path }
            .map { "\($0.path)|\($0.bytes)|\($0.safety.rawValue)|\($0.attribution.rawValue)|\($0.isActive)|\($0.suggestedAction.rawValue)" }
            .joined(separator: "\n")
        let skipped = (missingPaths + unreadablePaths).sorted().joined(separator: "\n")
        return "\(itemFingerprints)\n--skipped--\n\(skipped)"
    }
}
