import Foundation

struct ObservedProcess: Hashable, Codable, Sendable {
    var pid: Int32
    var command: String
    var arguments: String
}

struct ProcessSnapshot: Equatable, Codable, Sendable {
    var sampledAt: Date
    var processes: [ObservedProcess]

    nonisolated var hasCodexActivity: Bool {
        processes.contains { process in
            process.command.localizedCaseInsensitiveContains("codex") ||
                process.arguments.localizedCaseInsensitiveContains("codex")
        }
    }

    nonisolated var hasXcodeActivity: Bool {
        processes.contains { process in
            let haystack = "\(process.command) \(process.arguments)"
            return haystack.localizedCaseInsensitiveContains("xcodebuild") ||
                haystack.localizedCaseInsensitiveContains("simctl") ||
                haystack.localizedCaseInsensitiveContains("Simulator") ||
                haystack.localizedCaseInsensitiveContains("CoreSimulatorService")
        }
    }
}
