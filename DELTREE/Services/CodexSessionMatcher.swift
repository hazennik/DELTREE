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
            metadata["codexSessionLastUpdatedAt"] = formatted(date: lastUpdatedAt)
        }
        return metadata
    }

    static func sessionStorageMetadata(
        for path: String,
        sessions: [CodexSessionRecord],
        now: Date,
        staleAgeDays: Int) -> [String: String]
    {
        let storedSessions = sessionsStored(under: path, sessions: sessions)
        guard storedSessions.isEmpty == false else {
            return [:]
        }

        let sortedSessions = storedSessions.sorted {
            ($0.lastUpdatedAt ?? .distantPast) > ($1.lastUpdatedAt ?? .distantPast)
        }
        let staleSessions = sortedSessions.filter { session in
            guard let lastUpdatedAt = session.lastUpdatedAt else {
                return false
            }
            return now.timeIntervalSince(lastUpdatedAt) >= Double(staleAgeDays) * 86_400
        }
        let representativeSession = staleSessions.first ?? sortedSessions[0]
        let projectNames = uniqueProjectNames(from: sortedSessions)

        var metadata: [String: String] = [
            "codexSessionCount": "\(storedSessions.count)",
            "staleCodexSessionCount": "\(staleSessions.count)",
            "codexSessionSummary": clipped(representativeSession.briefDescription, limit: 120),
            "codexSessionSource": representativeSession.sourcePath,
            "codexSessionCleanupEffect": "Removes local Codex chat/session history, not project files.",
        ]

        if let lastUpdatedAt = representativeSession.lastUpdatedAt {
            metadata["codexSessionLastUpdatedAt"] = formatted(date: lastUpdatedAt)
        }

        if projectNames.isEmpty == false {
            metadata["codexSessionProjects"] = projectNames.prefix(4).joined(separator: ", ")
            metadata["codexSessionProjectSummary"] = projectSummary(from: projectNames)
        }

        return metadata
    }

    static func latestSessionActivityDate(for path: String, sessions: [CodexSessionRecord]) -> Date? {
        sessionsStored(under: path, sessions: sessions)
            .compactMap(\.lastUpdatedAt)
            .max()
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

    private static func sessionsStored(under path: String, sessions: [CodexSessionRecord]) -> [CodexSessionRecord] {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        return sessions.filter { session in
            let sourcePath = URL(fileURLWithPath: session.sourcePath).standardizedFileURL.path
            return sourcePath == standardizedPath || sourcePath.hasPrefix(standardizedPath + "/")
        }
    }

    private static func uniqueProjectNames(from sessions: [CodexSessionRecord]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for session in sessions {
            guard let projectName = session.projectName,
                  seen.insert(projectName).inserted
            else {
                continue
            }
            result.append(projectName)
        }
        return result
    }

    private static func projectSummary(from projects: [String]) -> String {
        guard let first = projects.first else {
            return ""
        }
        if projects.count == 1 {
            return first
        }
        return "\(first) + \(projects.count - 1) more"
    }

    private static func clipped(_ value: String, limit: Int) -> String {
        guard value.count > limit else {
            return value
        }
        return "\(value.prefix(limit - 1))..."
    }

    private static func formatted(date: Date) -> String {
        date.formatted(.iso8601)
    }
}
