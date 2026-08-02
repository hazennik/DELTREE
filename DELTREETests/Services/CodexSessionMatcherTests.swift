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
}
