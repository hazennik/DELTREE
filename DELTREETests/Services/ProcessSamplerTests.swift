import Foundation
import Testing
@testable import DELTREE

struct ProcessSamplerTests {
    @Test(.timeLimit(.minutes(1))) func liveSamplerReturnsWithoutPipeDeadlock() async {
        let snapshot = await LiveProcessSampler().sample()

        #expect(snapshot.sampledAt <= Date.now)
    }

    @Test(.timeLimit(.minutes(1))) func cancellingProcessRunnerTerminatesChildProcess() async throws {
        let startedAt = Date()
        let task = Task {
            try await ProcessRunner.run(
                executableURL: URL(fileURLWithPath: "/bin/sleep"),
                arguments: ["5"])
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected process runner cancellation.")
        } catch is CancellationError {
            #expect(Date().timeIntervalSince(startedAt) < 2)
        }
    }

    @Test(.timeLimit(.minutes(1))) func processRunnerTimeoutTerminatesChildProcess() async {
        let startedAt = Date()

        do {
            _ = try await ProcessRunner.run(
                executableURL: URL(fileURLWithPath: "/bin/sleep"),
                arguments: ["5"],
                timeoutSeconds: 0.1)
            Issue.record("Expected process runner timeout.")
        } catch let error as ProcessRunnerError {
            #expect(error == .timedOut(executablePath: "/bin/sleep", timeoutSeconds: 0.1))
            #expect(Date().timeIntervalSince(startedAt) < 2)
        } catch {
            Issue.record("Wrong error thrown: \(error)")
        }
    }
}
