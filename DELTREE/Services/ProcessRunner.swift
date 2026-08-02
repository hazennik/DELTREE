import Foundation

struct ProcessOutput: Sendable {
    var terminationStatus: Int32
    var stdout: Data
    var stderr: Data
}

enum ProcessRunner {
    nonisolated static func run(
        executableURL: URL,
        arguments: [String],
        priority: TaskPriority = .utility) async throws -> ProcessOutput
    {
        try await Task.detached(priority: priority) {
            try runSynchronously(executableURL: executableURL, arguments: arguments)
        }.value
    }

    nonisolated private static func runSynchronously(executableURL: URL, arguments: [String]) throws -> ProcessOutput {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        let stdout = LockedDataBox()
        let stderr = LockedDataBox()
        let group = DispatchGroup()

        readAsync(from: stdoutPipe.fileHandleForReading, into: stdout, group: group)
        readAsync(from: stderrPipe.fileHandleForReading, into: stderr, group: group)

        process.waitUntilExit()
        group.wait()

        return ProcessOutput(
            terminationStatus: process.terminationStatus,
            stdout: stdout.data,
            stderr: stderr.data)
    }

    nonisolated private static func readAsync(from fileHandle: FileHandle, into output: LockedDataBox, group: DispatchGroup) {
        let handle = SendableFileHandle(fileHandle)
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            output.append(handle.fileHandle.readDataToEndOfFile())
            group.leave()
        }
    }
}

private final class SendableFileHandle: @unchecked Sendable {
    let fileHandle: FileHandle

    nonisolated init(_ fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }
}

private final class LockedDataBox: @unchecked Sendable {
    private let lock = NSLock()
    nonisolated(unsafe) private var storage = Data()

    nonisolated init() {}

    nonisolated var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    nonisolated func append(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(data)
    }
}
