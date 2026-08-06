import Foundation

struct DiagnosticRedactor: Sendable {
    var homeDirectory: String
    var username: String

    init(
        homeDirectory: String = NSHomeDirectory(),
        username: String = NSUserName())
    {
        self.homeDirectory = URL(fileURLWithPath: homeDirectory).standardizedFileURL.path
        self.username = username
    }

    func redact(_ value: String) -> String {
        var redacted = value
        redacted = Self.replace(pattern: Self.emailPattern, in: redacted, with: "<email>")
        redacted = redacted.replacingOccurrences(of: homeDirectory, with: "~")
        if username.isEmpty == false {
            redacted = redacted.replacingOccurrences(of: "/Users/\(username)", with: "~")
            redacted = redacted.replacingOccurrences(of: username, with: "<user>")
        }
        redacted = Self.replace(pattern: Self.uuidPattern, in: redacted, with: "<uuid>")
        redacted = Self.replace(pattern: Self.codexSessionPattern, in: redacted, with: "$1<codex-session>")
        redacted = Self.replace(pattern: Self.derivedDataPattern, in: redacted, with: "$1-<derived-data-id>")
        redacted = Self.replace(pattern: Self.tempPathPattern, in: redacted, with: "<temp>")
        return redacted
    }

    func redact(_ values: [String]) -> [String] {
        values.map { redact($0) }
    }

    private static let emailPattern = #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#
    private static let uuidPattern = #"\b[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\b"#
    private static let codexSessionPattern = #"\b((?:task|session|thread|conversation)-)[A-Za-z0-9_-]{6,}\b"#
    private static let derivedDataPattern = #"([A-Za-z0-9_. -]+)-[A-Za-z0-9]{16,}(?=/|$)"#
    private static let tempPathPattern = #"/(?:private/)?var/folders/[^\s"']+"#

    private static func replace(pattern: String, in value: String, with replacement: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return value
        }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return expression.stringByReplacingMatches(
            in: value,
            options: [],
            range: range,
            withTemplate: replacement)
    }
}
