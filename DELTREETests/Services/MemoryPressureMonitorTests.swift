import Foundation
import Testing
@testable import DELTREE

struct MemoryPressureMonitorTests {
    @Test func memoryPressureEventMappingPrefersCritical() {
        #expect(MemoryPressureMonitor.level(for: [.warning]) == .warning)
        #expect(MemoryPressureMonitor.level(for: [.warning, .critical]) == .critical)
    }

    @Test func handlingMemoryPressureRunsReliefAndHandler() {
        let recorder = MemoryPressureRecorder()
        let monitor = MemoryPressureMonitor(
            reliefHandler: {
                recorder.reliefCallCount += 1
                return 4_096
            },
            eventHandler: { level in
                recorder.levels.append(level)
            })

        monitor.handle(level: .critical)

        #expect(recorder.reliefCallCount == 1)
        #expect(recorder.levels == [.critical])
    }
}

private final class MemoryPressureRecorder {
    var reliefCallCount = 0
    var levels: [MemoryPressureLevel] = []
}
