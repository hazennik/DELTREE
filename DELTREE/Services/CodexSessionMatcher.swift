import Foundation

enum CodexSessionMatcher {
    struct Index: Sendable {
        fileprivate struct Entry: Sendable {
            var session: CodexSessionRecord
            var standardizedWorkingDirectory: String?
            var standardizedSourcePath: String
            var titleSlug: String

            func matches(path standardizedPath: String, lastComponent pathLastComponent: String) -> Bool {
                if let standardizedWorkingDirectory {
                    if standardizedPath == standardizedWorkingDirectory ||
                        standardizedPath.hasPrefix(standardizedWorkingDirectory + "/")
                    {
                        return true
                    }
                }

                if standardizedPath.localizedCaseInsensitiveContains(session.id) {
                    return true
                }

                return titleSlug.count > 4 && pathLastComponent.contains(titleSlug)
            }
        }

        fileprivate var entries: [Entry]

        init(sessions: [CodexSessionRecord]) {
            entries = sessions.map { session in
                Entry(
                    session: session,
                    standardizedWorkingDirectory: session.workingDirectory.map {
                        URL(fileURLWithPath: $0).standardizedFileURL.path
                    },
                    standardizedSourcePath: URL(fileURLWithPath: session.sourcePath).standardizedFileURL.path,
                    titleSlug: slug(for: session.displayTitle))
            }
        }
    }

    struct PathMetadata: Sendable {
        var directMetadata: [String: String]
        var storageMetadata: [String: String]
        var latestSessionActivityDate: Date?
    }

    static func metadata(for path: String, sessions: [CodexSessionRecord]) -> [String: String] {
        metadata(for: path, index: Index(sessions: sessions))
    }

    static func metadata(for path: String, index: Index) -> [String: String] {
        guard let session = match(path: path, index: index) else {
            return [:]
        }

        return metadata(for: session)
    }

    static func sessionStorageMetadata(
        for path: String,
        sessions: [CodexSessionRecord],
        now: Date,
        staleAgeDays: Int) -> [String: String]
    {
        sessionStorageMetadata(
            for: path,
            index: Index(sessions: sessions),
            now: now,
            staleAgeDays: staleAgeDays)
    }

    static func sessionStorageMetadata(
        for path: String,
        index: Index,
        now: Date,
        staleAgeDays: Int) -> [String: String]
    {
        let storedSessions = sessionsStored(under: path, index: index)
        return sessionStorageMetadata(
            for: storedSessions,
            now: now,
            staleAgeDays: staleAgeDays)
    }

    static func pathMetadata(
        for path: String,
        index: Index,
        now: Date,
        staleAgeDays: Int) -> PathMetadata
    {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let pathLastComponent = URL(fileURLWithPath: standardizedPath).lastPathComponent.lowercased()
        var directMatch: CodexSessionRecord?
        var storedSessions: [CodexSessionRecord] = []

        for entry in index.entries {
            if directMatch == nil, entry.matches(path: standardizedPath, lastComponent: pathLastComponent) {
                directMatch = entry.session
            }
            if entry.standardizedSourcePath == standardizedPath ||
                entry.standardizedSourcePath.hasPrefix(standardizedPath + "/")
            {
                storedSessions.append(entry.session)
            }
        }

        return PathMetadata(
            directMetadata: directMatch.map(metadata(for:)) ?? [:],
            storageMetadata: sessionStorageMetadata(
                for: storedSessions,
                now: now,
                staleAgeDays: staleAgeDays),
            latestSessionActivityDate: storedSessions.compactMap(\.lastUpdatedAt).max())
    }

    private static func sessionStorageMetadata(
        for storedSessions: [CodexSessionRecord],
        now: Date,
        staleAgeDays: Int) -> [String: String]
    {
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
        latestSessionActivityDate(for: path, index: Index(sessions: sessions))
    }

    static func latestSessionActivityDate(for path: String, index: Index) -> Date? {
        sessionsStored(under: path, index: index)
            .compactMap(\.lastUpdatedAt)
            .max()
    }

    static func match(path: String, sessions: [CodexSessionRecord]) -> CodexSessionRecord? {
        match(path: path, index: Index(sessions: sessions))
    }

    static func match(path: String, index: Index) -> CodexSessionRecord? {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let pathLastComponent = URL(fileURLWithPath: standardizedPath).lastPathComponent.lowercased()

        return index.entries.first {
            $0.matches(path: standardizedPath, lastComponent: pathLastComponent)
        }?.session
    }

    private static func sessionsStored(under path: String, index: Index) -> [CodexSessionRecord] {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        return index.entries.compactMap { entry in
            guard entry.standardizedSourcePath == standardizedPath ||
                entry.standardizedSourcePath.hasPrefix(standardizedPath + "/")
            else {
                return nil
            }
            return entry.session
        }
    }

    private static func slug(for title: String) -> String {
        title
            .lowercased()
            .split { $0.isLetter == false && $0.isNumber == false }
            .joined(separator: "-")
    }

    private static func metadata(for session: CodexSessionRecord) -> [String: String] {
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
