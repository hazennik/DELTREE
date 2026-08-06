import Foundation
import Testing
@testable import DELTREECore

struct DiagnosticRedactorTests {
    @Test func redactsShareSensitivePathAndIdentifierSegments() {
        let redactor = DiagnosticRedactor(
            homeDirectory: "/Users/ryan",
            username: "ryan")
        let raw = """
        /Users/ryan/Documents/GitHub/SecretProject/Build
        ryan@example.com
        task-1234567890abcdef
        8B4E7664-4E91-4E2D-9FA1-41F49869D64D
        /Users/ryan/Library/Developer/Xcode/DerivedData/SecretProject-abcd1234EFGH5678/Index.noindex
        /var/folders/s7/private-cache/path
        """

        let redacted = redactor.redact(raw)

        #expect(redacted.contains("/Users/ryan") == false)
        #expect(redacted.contains("ryan@example.com") == false)
        #expect(redacted.contains("1234567890abcdef") == false)
        #expect(redacted.contains("8B4E7664-4E91-4E2D-9FA1-41F49869D64D") == false)
        #expect(redacted.contains("abcd1234EFGH5678") == false)
        #expect(redacted.contains("/var/folders") == false)
        #expect(redacted.contains("~") == true)
        #expect(redacted.contains("<email>") == true)
        #expect(redacted.contains("task-<codex-session>") == true)
        #expect(redacted.contains("SecretProject-<derived-data-id>") == true)
        #expect(redacted.contains("<temp>") == true)
    }

    @Test func redactsArraysWithoutChangingOrder() {
        let redactor = DiagnosticRedactor(homeDirectory: "/Users/dev", username: "dev")

        let values = redactor.redact([
            "/Users/dev/.codex",
            "/Users/dev/Library/Developer/Xcode/DerivedData/App-1234567890abcdef",
        ])

        #expect(values == [
            "~/.codex",
            "~/Library/Developer/Xcode/DerivedData/App-<derived-data-id>",
        ])
    }
}
