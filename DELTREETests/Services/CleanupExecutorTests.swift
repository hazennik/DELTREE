import Foundation
import Testing
@testable import DELTREE

struct CleanupExecutorTests {
    @Test @MainActor func executorRoutesTrashAndSimctlActions() async {
        let trash = RecordingTrashService()
        let simctl = RecordingSimctlCommandClient()
        let executor = DefaultCleanupExecutor(trashService: trash, simctlClient: simctl)
        let file = Self.item(path: "/tmp/result.xcresult", metadata: [:])
        let simulator = Self.item(path: "/tmp/device", metadata: ["udid": "SIM-123"])
        let plan = CleanupPlan(
            actions: [
                CleanupPlanAction(item: file, action: .removeXCResult, reason: "Trash result bundle."),
                CleanupPlanAction(item: simulator, action: .deleteUnavailableSimulator, reason: "Delete unavailable simulator."),
            ],
            blockedItems: [])

        let result = await executor.execute(plan)

        #expect(result.completedActions.count == 2)
        #expect(result.failedActions.isEmpty)
        #expect(await trash.trashedPaths() == ["/tmp/result.xcresult"])
        #expect(await simctl.deletedUDIDs() == ["SIM-123"])
        #expect(await simctl.erasedUDIDs().isEmpty)
    }

    @Test @MainActor func executorFailsSimulatorActionWithoutUDID() async {
        let trash = RecordingTrashService()
        let simctl = RecordingSimctlCommandClient()
        let executor = DefaultCleanupExecutor(trashService: trash, simctlClient: simctl)
        let simulator = Self.item(path: "/tmp/device", metadata: [:])
        let action = CleanupPlanAction(item: simulator, action: .eraseSimulator, reason: "Erase simulator.")
        let plan = CleanupPlan(actions: [action], blockedItems: [])

        let result = await executor.execute(plan)

        #expect(result.completedActions.isEmpty)
        #expect(result.failedActions[action] == CleanupExecutionError.missingSimulatorUDID.localizedDescription)
        #expect(await trash.trashedPaths().isEmpty)
        #expect(await simctl.deletedUDIDs().isEmpty)
        #expect(await simctl.erasedUDIDs().isEmpty)
    }

    private static func item(path: String, metadata: [String: String]) -> StorageItem {
        StorageItem(
            id: path,
            domain: .xcResults,
            kind: .xcResult,
            path: path,
            displayName: URL(fileURLWithPath: path).lastPathComponent,
            bytes: 1_000,
            createdAt: Date(),
            modifiedAt: Date(),
            lastUsedAt: Date(),
            attribution: .xcodeViaCodex,
            attributionConfidence: 0.8,
            safety: .safeToTrash,
            isActive: false,
            explanation: "Fixture",
            metadata: metadata)
    }
}

private actor RecordingTrashService: TrashServicing {
    private var paths: [String] = []

    func moveToTrash(_ item: StorageItem) async throws {
        let path = await MainActor.run { item.path }
        paths.append(path)
    }

    func trashedPaths() -> [String] {
        paths
    }
}

private actor RecordingSimctlCommandClient: SimctlCommanding {
    private var deletes: [String] = []
    private var erases: [String] = []

    func deleteDevice(udid: String) async throws {
        deletes.append(udid)
    }

    func eraseDevice(udid: String) async throws {
        erases.append(udid)
    }

    func deletedUDIDs() -> [String] {
        deletes
    }

    func erasedUDIDs() -> [String] {
        erases
    }
}
