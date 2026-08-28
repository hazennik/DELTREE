import Foundation
import Testing
@testable import DELTREE

struct CleanupPlannerTests {
    @Test func preflightKeepsOnlyExistingInactiveSafeItems() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-cleanup-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)

        let allowedURL = root.appendingPathComponent("allowed")
        try Data("fixture".utf8).write(to: allowedURL)

        var allowed = Self.item(path: allowedURL.path)
        var active = Self.item(path: root.appendingPathComponent("active").path)
        active.isActive = true
        let missing = Self.item(path: root.appendingPathComponent("missing").path)
        allowed.safety = .safeToTrash
        active.safety = .safeToTrash

        let snapshot = StorageSnapshot(
            capturedAt: Date(),
            items: [allowed, active, missing],
            missingPaths: [],
            unreadablePaths: [])
        let plan = DefaultCleanupPlanner(fileManager: fileManager).planSafeCleanup(from: snapshot)

        #expect(plan.items.map(\.path) == [allowedURL.path])
        #expect(plan.blockedItems.count == 2)
    }

    @Test func preflightBlocksDirectFilesystemCleanupForSimulatorDevices() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-simulator-plan-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)

        var simulator = Self.item(path: root.path)
        simulator.domain = .coreSimulatorDevices
        simulator.kind = .simulatorDevice
        simulator.suggestedAction = .moveToTrash
        simulator.metadata["udid"] = "SIM-123"
        let snapshot = StorageSnapshot(
            capturedAt: Date(),
            items: [simulator],
            missingPaths: [],
            unreadablePaths: [])
        let planner = DefaultCleanupPlanner(fileManager: fileManager)

        let safePlan = planner.planSafeCleanup(from: snapshot)
        let individualPlan = planner.planCleanup(for: simulator, action: .moveToTrash, in: snapshot)

        #expect(safePlan.actions.isEmpty)
        #expect(safePlan.blockedItems == [simulator])
        #expect(individualPlan.actions.isEmpty)
        #expect(individualPlan.blockedItems == [simulator])
    }

    @Test func cleanupPlanReportsIrreversibleSimulatorActions() {
        let item = Self.item(path: "/tmp/simulator")
        let deletePlan = CleanupPlan(
            actions: [CleanupPlanAction(item: item, action: .deleteUnavailableSimulator, reason: "Fixture")],
            blockedItems: [])
        let trashPlan = CleanupPlan(
            actions: [CleanupPlanAction(item: item, action: .moveToTrash, reason: "Fixture")],
            blockedItems: [])

        #expect(deletePlan.permanentlyRemovesSimulatorData)
        #expect(trashPlan.permanentlyRemovesSimulatorData == false)
    }

    private static func item(path: String) -> StorageItem {
        StorageItem(
            id: path,
            domain: .xcResults,
            kind: .xcResult,
            path: path,
            displayName: URL(fileURLWithPath: path).lastPathComponent,
            bytes: 10,
            createdAt: Date(),
            modifiedAt: Date(),
            lastUsedAt: Date(),
            attribution: .xcodeViaCodex,
            attributionConfidence: 0.8,
            safety: .safeToTrash,
            isActive: false,
            explanation: "Fixture",
            metadata: [:])
    }
}
