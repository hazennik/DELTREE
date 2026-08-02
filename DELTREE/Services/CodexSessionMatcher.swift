import Foundation

enum CodexSessionMatcher {
    static func metadata(for path: String, sessions: [CodexSessionRecord]) -> [String: String] {
        guard let session = match(path: path, sessions: sessions) else {
            return [:]
        }

        var metadata = [
            "codexSessionID": session.id,
            "codexTaskTitle": session.displayTitle,
            "codexSessionSource": session.sourcePath,
        ]
        if let workingDirectory = session.workingDirectory {
            metadata["codexWorkingDirectory"] = workingDirectory
        }
        if let lastUpdatedAt = session.lastUpdatedAt {
            metadata["codexSessionLastUpdatedAt"] = ISO8601DateFormatter().string(from: lastUpdatedAt)
        }
        return metadata
    }

    static func match(path: String, sessions: [CodexSessionRecord]) -> CodexSessionRecord? {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let pathLastComponent = URL(fileURLWithPath: standardizedPath).lastPathComponent.lowercased()

        return sessions.first { session in
            if let workingDirectory = session.workingDirectory {
                let standardizedWorkingDirectory = URL(fileURLWithPath: workingDirectory).standardizedFileURL.path
                if standardizedPath == standardizedWorkingDirectory || standardizedPath.hasPrefix(standardizedWorkingDirectory + "/") {
                    return true
                }
            }

            if standardizedPath.localizedCaseInsensitiveContains(session.id) {
                return true
            }

            let titleSlug = session.displayTitle
                .lowercased()
                .split { $0.isLetter == false && $0.isNumber == false }
                .joined(separator: "-")
            return titleSlug.count > 4 && pathLastComponent.contains(titleSlug)
        }
    }
}
