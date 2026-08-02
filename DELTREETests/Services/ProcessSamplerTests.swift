import Foundation
import Testing
@testable import DELTREE

struct ProcessSamplerTests {
    @Test(.timeLimit(.minutes(1))) func liveSamplerReturnsWithoutPipeDeadlock() async {
        let snapshot = await LiveProcessSampler().sample()

        #expect(snapshot.sampledAt <= Date.now)
    }
}
