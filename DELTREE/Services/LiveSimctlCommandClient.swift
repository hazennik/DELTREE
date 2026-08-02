import Foundation

struct LiveSimctlCommandClient: SimctlCommanding {
    func deleteDevice(udid: String) async throws {
        try await run(arguments: ["simctl", "delete", udid])
    }

    func eraseDevice(udid: String) async throws {
        try await run(arguments: ["simctl", "erase", udid])
    }

    private func run(arguments: [String]) async throws {
        try await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = arguments
            process.standardOutput = Pipe()
            let errorOutput = Pipe()
            process.standardError = errorOutput

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let data = errorOutput.fileHandleForReading.readDataToEndOfFile()
                let message = String(decoding: data, as: UTF8.self)
                throw SimctlCommandError.failed(status: process.terminationStatus, message: message)
            }
        }.value
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
