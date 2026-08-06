import Darwin
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
        priority: TaskPriority = .utility,
        timeoutSeconds: TimeInterval? = nil) async throws -> ProcessOutput
    {
        let cancellation = ProcessCancellationState()
        return try await withTaskCancellationHandler {
            try await Task.detached(priority: priority) {
                try runSynchronously(
                    executableURL: executableURL,
                    arguments: arguments,
                    timeoutSeconds: timeoutSeconds,
                    cancellation: cancellation)
            }.value
        } onCancel: {
            cancellation.cancel()
        }
    }

    nonisolated private static func runSynchronously(
        executableURL: URL,
        arguments: [String],
        timeoutSeconds: TimeInterval?,
        cancellation: ProcessCancellationState) throws -> ProcessOutput
    {
        try cancellation.checkCancellation()

        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        let termination = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            termination.signal()
        }
        defer { process.terminationHandler = nil }
        cancellation.attach(process)
        defer { cancellation.detach(process) }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        if cancellation.isCancelled {
            process.terminate()
        }

        let stdout = LockedDataBox()
        let stderr = LockedDataBox()
        let group = DispatchGroup()

        readAsync(from: stdoutPipe.fileHandleForReading, into: stdout, group: group)
        readAsync(from: stderrPipe.fileHandleForReading, into: stderr, group: group)

        let completedBeforeTimeout = waitForExit(
            of: process,
            termination: termination,
            timeoutSeconds: timeoutSeconds)
        if completedBeforeTimeout == false {
            terminate(process, termination: termination)
        }

        group.wait()
        try cancellation.checkCancellation()

        guard completedBeforeTimeout else {
            throw ProcessRunnerError.timedOut(
                executablePath: executableURL.path,
                timeoutSeconds: timeoutSeconds ?? 0)
        }

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

    nonisolated private static func waitForExit(
        of process: Process,
        termination: DispatchSemaphore,
        timeoutSeconds: TimeInterval?) -> Bool
    {
        guard let timeoutSeconds else {
            process.waitUntilExit()
            return true
        }

        if process.isRunning == false {
            return true
        }

        return termination.wait(timeout: deadline(after: timeoutSeconds)) == .success
    }

    nonisolated private static func terminate(_ process: Process, termination: DispatchSemaphore) {
        if process.isRunning {
            process.terminate()
        }

        guard termination.wait(timeout: deadline(after: 2)) == .timedOut,
              process.isRunning
        else {
            return
        }

        kill(process.processIdentifier, SIGKILL)
        _ = termination.wait(timeout: deadline(after: 2))
    }

    nonisolated private static func deadline(after seconds: TimeInterval) -> DispatchTime {
        let milliseconds = max(1, Int((max(0, seconds) * 1_000).rounded(.up)))
        return .now() + .milliseconds(milliseconds)
    }
}

enum ProcessRunnerError: LocalizedError, Equatable {
    case timedOut(executablePath: String, timeoutSeconds: TimeInterval)

    var errorDescription: String? {
        switch self {
        case let .timedOut(executablePath, timeoutSeconds):
            "\(executablePath) timed out after \(String(format: "%.1f", timeoutSeconds)) seconds."
        }
    }
}

private final class ProcessCancellationState: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func attach(_ process: Process) {
        let shouldTerminate: Bool
        lock.lock()
        self.process = process
        shouldTerminate = cancelled
        lock.unlock()

        if shouldTerminate, process.isRunning {
            process.terminate()
        }
    }

    func detach(_ process: Process) {
        lock.lock()
        if self.process === process {
            self.process = nil
        }
        lock.unlock()
    }

    func cancel() {
        let runningProcess: Process?
        lock.lock()
        cancelled = true
        runningProcess = process
        lock.unlock()

        if runningProcess?.isRunning == true {
            runningProcess?.terminate()
        }
    }

    func checkCancellation() throws {
        if isCancelled {
            throw CancellationError()
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
