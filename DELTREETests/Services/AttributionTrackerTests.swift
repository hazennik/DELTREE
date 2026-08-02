import Foundation
import Testing
@testable import DELTREE

struct AttributionTrackerTests {
    @Test func correlatesWatchedXcodeChangesToCodex() async {
        let tracker = LiveAttributionTracker(eventTTL: 60)
        let now = Date()
        let processes = ProcessSnapshot(
            sampledAt: now,
            processes: [
                ObservedProcess(pid: 1, command: "/opt/homebrew/bin/codex", arguments: "codex"),
                ObservedProcess(pid: 2, command: "/usr/bin/xcodebuild", arguments: "xcodebuild test"),
            ])

        await tracker.recordFilesystemEvents(paths: ["/tmp/DELTREE-Sim"], processes: processes, at: now)
        let result = await tracker.attribution(
            forPath: "/tmp/DELTREE-Sim/data/Containers",
            domain: .coreSimulatorDevices,
            kind: .simulatorDevice,
            metadata: [:],
            processes: ProcessSnapshot(sampledAt: now, processes: []),
            now: now)

        #expect(result.owner == .xcodeViaCodex)
        #expect(result.confidence >= 0.8)
    }
}
