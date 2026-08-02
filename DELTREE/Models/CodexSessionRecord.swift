import Foundation

struct CodexSessionRecord: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var title: String
    var workingDirectory: String?
    var sourcePath: String
    var startedAt: Date?
    var lastUpdatedAt: Date?

    var displayTitle: String {
        title.isEmpty ? id : title
    }
}
