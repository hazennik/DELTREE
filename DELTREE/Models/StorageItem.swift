import Foundation

struct StorageItem: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var domain: StorageDomain
    var kind: StorageKind
    var path: String
    var displayName: String
    var bytes: Int64
    var createdAt: Date?
    var modifiedAt: Date?
    var lastUsedAt: Date?
    var attribution: OwnerAttribution
    var attributionConfidence: Double
    var safety: SafetyClassification
    var isActive: Bool
    var suggestedAction: StorageAction = .none
    var cleanupImpact: String = ""
    var isPinned: Bool = false
    var isIgnored: Bool = false
    var explanation: String
    var metadata: [String: String]

    var isCleanupEligible: Bool {
        safety == .safeToTrash &&
            isActive == false &&
            isPinned == false &&
            isIgnored == false &&
            bytes > 0 &&
            (suggestedAction == .none || suggestedAction.isOneClickSafeCleanupAction)
    }

    var lastActivityAt: Date? {
        lastUsedAt ?? modifiedAt ?? createdAt
    }

    var lastActivitySortValue: Date {
        lastActivityAt ?? .distantPast
    }

    var createdBy: String {
        attribution.displayName
    }

    var relatedProject: String {
        metadata["relatedProject"] ?? metadata["projectName"] ?? ""
    }

    var relatedCodexTask: String {
        metadata["codexTaskTitle"] ?? metadata["codexSessionID"] ?? ""
    }

    var runtimeOrDevice: String {
        metadata["runtime"] ?? metadata["deviceName"] ?? metadata["runtimeName"] ?? ""
    }

    var stateDescription: String {
        if isActive {
            return "Active"
        }
        return metadata["state"] ?? metadata["availability"] ?? ""
    }
}
