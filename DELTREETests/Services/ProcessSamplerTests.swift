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
}
