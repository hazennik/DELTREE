import Foundation

struct LiveSimctlCommandClient: SimctlCommanding {
    func deleteDevice(udid: String) async throws {
        try await run(arguments: ["simctl", "delete", udid])
    }

    func eraseDevice(udid: String) async throws {
        try await run(arguments: ["simctl", "erase", udid])
    }

    private func run(arguments: [String]) async throws {
        let output = try await ProcessRunner.run(
            executableURL: URL(fileURLWithPath: "/usr/bin/xcrun"),
            arguments: arguments)

        guard output.terminationStatus == 0 else {
            let message = String(decoding: output.stderr, as: UTF8.self)
            throw SimctlCommandError.failed(status: output.terminationStatus, message: message)
        }
    }
}

enum SimctlCommandError: LocalizedError, Equatable {
    case failed(status: Int32, message: String)

    var errorDescription: String? {
        switch self {
        case let .failed(status, message):
            "simctl failed with status \(status): \(message)"
        }
    }
}
