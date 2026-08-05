import Foundation
import Testing
@testable import DELTREE

struct CodexSessionMatcherTests {
    @Test func matchesByWorkingDirectoryAndExportsMetadata() {
        let session = CodexSessionRecord(
            id: "task-123",
            title: "Build Storage Inspector",
            workingDirectory: "/Users/ryan/Documents/GitHub/DELTREE",
            sourcePath: "/Users/ryan/.codex/sessions/task-123.json",
            startedAt: Date(timeIntervalSince1970: 100),
            lastUpdatedAt: Date(timeIntervalSince1970: 200))

        let metadata = CodexSessionMatcher.metadata(
            for: "/Users/ryan/Documents/GitHub/DELTREE/Build/Result.xcresult",
            sessions: [session])

        #expect(metadata["codexSessionID"] == "task-123")
        #expect(metadata["codexTaskTitle"] == "Build Storage Inspector")
        #expect(metadata["codexWorkingDirectory"] == "/Users/ryan/Documents/GitHub/DELTREE")
        #expect(metadata["codexSessionSource"] == "/Users/ryan/.codex/sessions/task-123.json")
        #expect(metadata["codexSessionLastUpdatedAt"] != nil)
    }

    @Test func matchesBySessionIDInPath() {
        let session = CodexSessionRecord(
            id: "abc-456",
            title: "",
            workingDirectory: nil,
            sourcePath: "/Users/ryan/.codex/sessions/abc-456.json",
            startedAt: nil,
            lastUpdatedAt: nil)

        let match = CodexSessionMatcher.match(path: "/tmp/abc-456-artifacts", sessions: [session])

        #expect(match?.id == "abc-456")
    }

    @Test func sessionStorageMetadataSummarizesProjectDateAndDescription() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let lastUpdatedAt = now.addingTimeInterval(-30 * 86_400)
        let sessionRoot = "/Users/ryan/.codex/sessions"
        let session = CodexSessionRecord(
            id: "session-1",
            title: "Update Mac storage cleanup guard",
            workingDirectory: "/Users/ryan/Documents/GitHub/DELTREE",
            sourcePath: "\(sessionRoot)/2026/08/02/session-1.jsonl",
            startedAt: nil,
            lastUpdatedAt: lastUpdatedAt)
        let outsideSession = CodexSessionRecord(
            id: "session-2",
            title: "Unrelated work",
            workingDirectory: "/Users/ryan/Documents/GitHub/Other",
            sourcePath: "/Users/ryan/.codex/tasks/session-2.jsonl",
            startedAt: nil,
            lastUpdatedAt: lastUpdatedAt)

        let metadata = CodexSessionMatcher.sessionStorageMetadata(
            for: sessionRoot,
            sessions: [session, outsideSession],
            now: now,
            staleAgeDays: 14)

        #expect(metadata["codexSessionCount"] == "1")
        #expect(metadata["staleCodexSessionCount"] == "1")
        #expect(metadata["codexSessionProjectSummary"] == "DELTREE")
        #expect(metadata["codexSessionProjects"] == "DELTREE")
        #expect(metadata["codexSessionSummary"] == "Update Mac storage cleanup guard")
        #expect(metadata["codexSessionCleanupEffect"] == "Removes local Codex chat/session history, not project files.")
        #expect(metadata["codexSessionLastUpdatedAt"]?.isEmpty == false)
        #expect(CodexSessionMatcher.latestSessionActivityDate(for: sessionRoot, sessions: [session]) == lastUpdatedAt)
    }

    @Test func codexHomeScannerAddsSessionContextToSessionsFolder() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-session-context-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let codexRoot = root.appendingPathComponent(".codex", isDirectory: true)
        let sessionsRoot = codexRoot.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionsRoot.appendingPathComponent("2026/session-1.jsonl")
        try fileManager.createDirectory(at: sessionFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("fixture".utf8).write(to: sessionFile)

        let lastUpdatedAt = Date(timeIntervalSince1970: 2_000_000)
        let session = CodexSessionRecord(
            id: "session-1",
            title: "Explain stale Codex session storage",
            workingDirectory: "/Users/ryan/Documents/GitHub/DELTREE",
            sourcePath: sessionFile.path,
            startedAt: nil,
            lastUpdatedAt: lastUpdatedAt)
        let context = DomainScanContext(
            fileManager: fileManager,
            fileSizeScanner: LiveFileSizeScanner(fileManager: fileManager),
            simctlDevices: [],
            codexSessions: [session],
            processSnapshot: ProcessSnapshot(sampledAt: lastUpdatedAt, processes: []),
            attributionTracker: LiveAttributionTracker(),
            configuration: .standard,
            now: lastUpdatedAt.addingTimeInterval(30 * 86_400))

        let result = await CodexWorkspaceDomainScanner(
            domain: .codexHome,
            kind: .codexData,
            roots: [codexRoot])
            .scan(context: context)
        let item = try #require(result.items.first { $0.displayName == "sessions" })

        #expect(item.safety == .unknown)
        #expect(item.suggestedAction == .none)
        #expect(item.relatedProject == "DELTREE")
        #expect(item.codexSessionDescription == "Explain stale Codex session storage")
        #expect(item.codexSessionCleanupEffect == "Removes local Codex chat/session history, not project files.")
        #expect(item.lastUsedAt == lastUpdatedAt)
        #expect(item.metadata["state"] == "Stale")
    }

    @Test func catalogReaderIncludesArchivedSessionsAndTextDescription() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-archived-session-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let archivedRoot = root.appendingPathComponent(".codex/archived_sessions", isDirectory: true)
        try fileManager.createDirectory(at: archivedRoot, withIntermediateDirectories: true)
        let sessionFile = archivedRoot.appendingPathComponent("archived-1.jsonl")
        let json = """
        {"id":"archived-1","cwd":"/Users/ryan/Documents/GitHub/DELTREE","updated_at":"2026-06-01T12:00:00Z","text":"Review old Codex session cleanup"}
        """
        try Data(json.utf8).write(to: sessionFile)

        let records = await CodexThreadCatalogReader(homeDirectory: root, fileManager: fileManager)
            .sessions(now: Date(timeIntervalSince1970: 2_000_000))
        let record = try #require(records.first { $0.id == "archived-1" })

        #expect(URL(fileURLWithPath: record.sourcePath).standardizedFileURL.path == sessionFile.standardizedFileURL.path)
        #expect(record.projectName == "DELTREE")
        #expect(record.briefDescription == "Review old Codex session cleanup")
        #expect(record.lastUpdatedAt != nil)
    }

    @Test func catalogReaderInvalidatesCacheWhenSessionFileChanges() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-session-cache-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let sessionsRoot = root.appendingPathComponent(".codex/sessions", isDirectory: true)
        try fileManager.createDirectory(at: sessionsRoot, withIntermediateDirectories: true)
        let sessionFile = sessionsRoot.appendingPathComponent("session-1.jsonl")
        try Self.writeSessionFixture(
            title: "Initial scan cache title",
            updatedAt: "2026-08-01T12:00:00Z",
            to: sessionFile,
            modifiedAt: Date(timeIntervalSince1970: 2_000_000))

        let reader = CodexThreadCatalogReader(homeDirectory: root, fileManager: fileManager)
        let firstRecords = await reader.sessions(now: Date(timeIntervalSince1970: 2_000_000))
        let firstRecord = try #require(firstRecords.first { $0.id == "session-1" })
        #expect(firstRecord.displayTitle == "Initial scan cache title")

        try Self.writeSessionFixture(
            title: "Updated scan cache title",
            updatedAt: "2026-08-02T12:00:00Z",
            to: sessionFile,
            modifiedAt: Date(timeIntervalSince1970: 2_000_100))

        let secondRecords = await reader.sessions(now: Date(timeIntervalSince1970: 2_000_100))
        let secondRecord = try #require(secondRecords.first { $0.id == "session-1" })
        #expect(secondRecord.displayTitle == "Updated scan cache title")
    }

    private static func writeSessionFixture(title: String, updatedAt: String, to url: URL, modifiedAt: Date) throws {
        let json = #"{"id":"session-1","title":"\#(title)","updated_at":"\#(updatedAt)"}"#
        try Data(json.utf8).write(to: url)
        try FileManager.default.setAttributes([.modificationDate: modifiedAt], ofItemAtPath: url.path)
    }
}
