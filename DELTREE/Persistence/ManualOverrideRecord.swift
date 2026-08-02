import Foundation
import SwiftData

@Model
final class ManualOverrideRecord {
    var id: UUID
    var path: String
    var owner: String?
    var isPinned: Bool
    var isIgnored: Bool
    var note: String
    var updatedAt: Date

    @MainActor
    init(override: ManualStorageOverride) {
        id = UUID()
        path = override.path
        owner = override.owner?.rawValue
        isPinned = override.isPinned
        isIgnored = override.isIgnored
        note = override.note
        updatedAt = override.updatedAt
    }

    @MainActor
    func update(from override: ManualStorageOverride) {
        owner = override.owner?.rawValue
        isPinned = override.isPinned
        isIgnored = override.isIgnored
        note = override.note
        updatedAt = override.updatedAt
    }

    @MainActor
    var manualOverride: ManualStorageOverride {
        ManualStorageOverride(
            path: path,
            owner: owner.flatMap(OwnerAttribution.init(rawValue:)),
            isPinned: isPinned,
            isIgnored: isIgnored,
            note: note,
            updatedAt: updatedAt)
    }
}
