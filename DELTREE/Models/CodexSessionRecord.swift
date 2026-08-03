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

    var briefDescription: String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? id : trimmedTitle
    }

    var projectName: String? {
        guard let workingDirectory,
              workingDirectory.isEmpty == false
        else {
            return nil
        }
        let name = URL(fileURLWithPath: workingDirectory).lastPathComponent
        return name.isEmpty ? nil : name
    }
}
