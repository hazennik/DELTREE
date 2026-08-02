import Foundation

struct ManualStorageOverride: Codable, Equatable, Hashable, Sendable {
    var path: String
    var owner: OwnerAttribution?
    var isPinned: Bool
    var isIgnored: Bool
    var note: String
    var updatedAt: Date

    init(
        path: String,
        owner: OwnerAttribution? = nil,
        isPinned: Bool = false,
        isIgnored: Bool = false,
        note: String = "",
        updatedAt: Date = Date())
    {
        self.path = URL(fileURLWithPath: path).standardizedFileURL.path
        self.owner = owner
        self.isPinned = isPinned
        self.isIgnored = isIgnored
        self.note = note
        self.updatedAt = updatedAt
    }
}
