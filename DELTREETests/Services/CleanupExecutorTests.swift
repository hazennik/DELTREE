import Foundation
import Testing
@testable import DELTREE

struct CleanupExecutorTests {
    @Test @MainActor func executorRoutesTrashAndSimctlActionsAfterFinalValidation() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-cleanup-executor-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let resultBundle = root.appendingPathComponent("result.xcresult")
        try Data("fixture".utf8).write(to: resultBundle)
        let trash = RecordingTrashService()
        let simctl = RecordingSimctlCommandClient()
        let executor = DefaultCleanupExecutor(
            fileManager: fileManager,
            trashService: trash,
            simctlClient: simctl,
            simctlDeviceClient: StaticSimctlClient(devices: [
                Self.simulatorDevice(udid: "SIM-123", state: "Shutdown", isAvailable: false),
            ]),
            openFileChecker: RecordingOpenFileChecker(result: .clear))
        let file = Self.item(path: resultBundle.path, metadata: [:])
        let simulator = Self.item(
            path: "/tmp/device",
            domain: .coreSimulatorDevices,
            kind: .simulatorDevice,
            metadata: ["udid": "SIM-123"])
        let plan = CleanupPlan(
            actions: [
                CleanupPlanAction(item: file, action: .removeXCResult, reason: "Trash result bundle."),
                CleanupPlanAction(item: simulator, action: .deleteUnavailableSimulator, reason: "Delete unavailable simulator."),
            ],
            blockedItems: [])

        let result = await executor.execute(plan)

        #expect(result.completedActions.count == 2)
        #expect(result.failedActions.isEmpty)
        #expect(await trash.trashedPaths() == [resultBundle.path])
        #expect(await simctl.deletedUDIDs() == ["SIM-123"])
        #expect(await simctl.erasedUDIDs().isEmpty)
    }

    @Test @MainActor func executorFailsSimulatorActionWithoutUDID() async {
        let trash = RecordingTrashService()
        let simctl = RecordingSimctlCommandClient()
        let executor = DefaultCleanupExecutor(
            trashService: trash,
            simctlClient: simctl,
            simctlDeviceClient: StaticSimctlClient(devices: []),
            openFileChecker: RecordingOpenFileChecker(result: .clear))
        let simulator = Self.item(
            path: "/tmp/device",
            domain: .coreSimulatorDevices,
            kind: .simulatorDevice,
            metadata: [:])
        let action = CleanupPlanAction(item: simulator, action: .eraseSimulator, reason: "Erase simulator.")
        let plan = CleanupPlan(actions: [action], blockedItems: [])

        let result = await executor.execute(plan)

        #expect(result.completedActions.isEmpty)
        #expect(result.failedActions[action] == CleanupExecutionError.missingSimulatorUDID.localizedDescription)
        #expect(await trash.trashedPaths().isEmpty)
        #expect(await simctl.deletedUDIDs().isEmpty)
        #expect(await simctl.erasedUDIDs().isEmpty)
    }

    @Test @MainActor func executorBlocksOpenFilesDuringFinalValidation() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-cleanup-open-file-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let resultBundle = root.appendingPathComponent("result.xcresult")
        try Data("fixture".utf8).write(to: resultBundle)
        let trash = RecordingTrashService()
        let simctl = RecordingSimctlCommandClient()
        let executor = DefaultCleanupExecutor(
            fileManager: fileManager,
            trashService: trash,
            simctlClient: simctl,
            simctlDeviceClient: StaticSimctlClient(devices: []),
            openFileChecker: RecordingOpenFileChecker(result: .openFilesFound))
        let item = Self.item(path: resultBundle.path, metadata: [:])
        let action = CleanupPlanAction(item: item, action: .removeXCResult, reason: "Trash result bundle.")
        let plan = CleanupPlan(actions: [action], blockedItems: [])

        let result = await executor.execute(plan)

        #expect(result.completedActions.isEmpty)
        #expect(result.failedActions[action] == CleanupExecutionError.pathHasOpenFiles(resultBundle.path).localizedDescription)
        #expect(await trash.trashedPaths().isEmpty)
        #expect(await simctl.deletedUDIDs().isEmpty)
    }

    @Test @MainActor func executorBlocksBootedSimulatorBeforeSimctlCommand() async {
        let trash = RecordingTrashService()
        let simctl = RecordingSimctlCommandClient()
        let executor = DefaultCleanupExecutor(
            trashService: trash,
            simctlClient: simctl,
            simctlDeviceClient: StaticSimctlClient(devices: [
                Self.simulatorDevice(udid: "SIM-123", state: "Booted", isAvailable: false),
            ]),
            openFileChecker: RecordingOpenFileChecker(result: .clear))
        let simulator = Self.item(
            path: "/tmp/device",
            domain: .coreSimulatorDevices,
            kind: .simulatorDevice,
            metadata: ["udid": "SIM-123"])
        let action = CleanupPlanAction(item: simulator, action: .deleteUnavailableSimulator, reason: "Delete unavailable simulator.")
        let plan = CleanupPlan(actions: [action], blockedItems: [])

        let result = await executor.execute(plan)

        #expect(result.completedActions.isEmpty)
        #expect(result.failedActions[action] == CleanupExecutionError.simulatorBooted("SIM-123").localizedDescription)
        #expect(await trash.trashedPaths().isEmpty)
        #expect(await simctl.deletedUDIDs().isEmpty)
    }

    @Test @MainActor func executorRejectsDirectFilesystemCleanupForSimulatorDevice() async {
        let trash = RecordingTrashService()
        let simctl = RecordingSimctlCommandClient()
        let executor = DefaultCleanupExecutor(
            trashService: trash,
            simctlClient: simctl,
            simctlDeviceClient: StaticSimctlClient(devices: [
                Self.simulatorDevice(udid: "SIM-123", state: "Shutdown", isAvailable: true),
            ]),
            openFileChecker: RecordingOpenFileChecker(result: .clear))
        let simulator = Self.item(
            path: "/tmp/device",
            domain: .coreSimulatorDevices,
            kind: .simulatorDevice,
            metadata: ["udid": "SIM-123"])
        let action = CleanupPlanAction(item: simulator, action: .moveToTrash, reason: "Invalid direct cleanup.")
        let plan = CleanupPlan(actions: [action], blockedItems: [])

        let result = await executor.execute(plan)

        #expect(result.completedActions.isEmpty)
        #expect(result.failedActions[action] == CleanupExecutionError.invalidSimulatorAction(.moveToTrash).localizedDescription)
        #expect(await trash.trashedPaths().isEmpty)
        #expect(await simctl.deletedUDIDs().isEmpty)
        #expect(await simctl.erasedUDIDs().isEmpty)
    }

    @Test @MainActor func executorRechecksSimulatorStateBeforeEveryMutation() async {
        let trash = RecordingTrashService()
        let simctl = RecordingSimctlCommandClient()
        let simulatorClient = SequencedSimctlClient(responses: [
            [Self.simulatorDevice(udid: "SIM-123", state: "Shutdown", isAvailable: false)],
            [Self.simulatorDevice(udid: "SIM-456", state: "Booted", isAvailable: false)],
        ])
        let executor = DefaultCleanupExecutor(
            trashService: trash,
            simctlClient: simctl,
            simctlDeviceClient: simulatorClient,
            openFileChecker: RecordingOpenFileChecker(result: .clear))
        let first = Self.item(
            path: "/tmp/device",
            domain: .coreSimulatorDevices,
            kind: .simulatorDevice,
            metadata: ["udid": "SIM-123"])
        let second = Self.item(
            path: "/tmp/device-2",
            domain: .coreSimulatorDevices,
            kind: .simulatorDevice,
            metadata: ["udid": "SIM-456"])
        let firstAction = CleanupPlanAction(item: first, action: .deleteUnavailableSimulator, reason: "Delete unavailable simulator.")
        let secondAction = CleanupPlanAction(item: second, action: .deleteUnavailableSimulator, reason: "Delete unavailable simulator.")

        let result = await executor.execute(CleanupPlan(actions: [firstAction, secondAction], blockedItems: []))

        #expect(result.completedActions == [firstAction])
        #expect(result.failedActions[secondAction] == CleanupExecutionError.simulatorBooted("SIM-456").localizedDescription)
        #expect(await simulatorClient.requestCount() == 2)
        #expect(await simctl.deletedUDIDs() == ["SIM-123"])
    }

    @Test @MainActor func executorBlocksAPathThatChangedAfterScanning() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("DELTREE-cleanup-changed-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let resultBundle = root.appendingPathComponent("result.xcresult")
        try Data("fixture".utf8).write(to: resultBundle)
        let original = Self.item(path: resultBundle.path, metadata: [:])
        try Data(repeating: 1, count: 32_768).write(to: resultBundle)
        let action = CleanupPlanAction(item: original, action: .removeXCResult, reason: "Trash result bundle.")
        let trash = RecordingTrashService()
        let executor = DefaultCleanupExecutor(
            fileManager: fileManager,
            trashService: trash,
            openFileChecker: RecordingOpenFileChecker(result: .clear))

        let result = await executor.execute(CleanupPlan(actions: [action], blockedItems: []))

        #expect(result.completedActions.isEmpty)
        #expect(result.failedActions[action] != nil)
        #expect(await trash.trashedPaths().isEmpty)
    }

    @Test @MainActor func executorBlocksIncompleteFinalSizeValidation() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("DELTREE-cleanup-incomplete-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let resultBundle = root.appendingPathComponent("result.xcresult")
        try Data("fixture".utf8).write(to: resultBundle)
        let item = Self.item(path: resultBundle.path, metadata: [:])
        let action = CleanupPlanAction(item: item, action: .removeXCResult, reason: "Trash result bundle.")
        let trash = RecordingTrashService()
        let executor = DefaultCleanupExecutor(
            fileManager: fileManager,
            trashService: trash,
            openFileChecker: RecordingOpenFileChecker(result: .clear),
            fileSizeScanner: IncompleteFileSizeScanner())

        let result = await executor.execute(CleanupPlan(actions: [action], blockedItems: []))

        #expect(result.completedActions.isEmpty)
        #expect(result.failedActions[action] == CleanupExecutionError.incompleteRevalidation(resultBundle.path).localizedDescription)
        #expect(await trash.trashedPaths().isEmpty)
    }

    @Test @MainActor func executorTreatsCancellationAsSkippedInsteadOfFailed() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("DELTREE-cleanup-cancellation-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let resultBundle = root.appendingPathComponent("result.xcresult")
        try Data("fixture".utf8).write(to: resultBundle)
        let trash = RecordingTrashService()
        let executor = DefaultCleanupExecutor(
            fileManager: fileManager,
            trashService: trash,
            openFileChecker: CancellingOpenFileChecker())
        let item = Self.item(path: resultBundle.path, metadata: [:])
        let action = CleanupPlanAction(item: item, action: .removeXCResult, reason: "Trash result bundle.")
        let plan = CleanupPlan(actions: [action], blockedItems: [])

        let execution = Task { await executor.execute(plan) }
        let result = await execution.value

        #expect(result.completedActions.isEmpty)
        #expect(result.failedActions.isEmpty)
        #expect(result.skippedItems == [item])
        #expect(result.status == "skipped")
        #expect(await trash.trashedPaths().isEmpty)
    }

    private static func item(
        path: String,
        domain: StorageDomain = .xcResults,
        kind: StorageKind = .xcResult,
        metadata: [String: String]) -> StorageItem
    {
        let url = URL(fileURLWithPath: path)
        let scannedSize = LiveFileSizeScanner().size(of: url)
        return StorageItem(
            id: path,
            domain: domain,
            kind: kind,
            path: path,
            displayName: URL(fileURLWithPath: path).lastPathComponent,
            bytes: scannedSize.bytes > 0 ? scannedSize.bytes : 1_000,
            createdAt: Date(),
            modifiedAt: Date(),
            fileSystemIdentity: FileSystemIdentityReader.identity(for: url),
            lastUsedAt: Date(),
            attribution: .xcodeViaCodex,
            attributionConfidence: 0.8,
            safety: .safeToTrash,
            isActive: false,
            explanation: "Fixture",
            metadata: metadata)
    }

    private static func simulatorDevice(udid: String, state: String, isAvailable: Bool) -> SimctlDevice {
        SimctlDevice(
            udid: udid,
            name: "iPhone",
            state: state,
            isAvailable: isAvailable,
            availabilityError: isAvailable ? nil : "runtime unavailable",
            runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-18-0",
            dataPath: "/tmp/device",
            logPath: nil,
            lastBootedAt: nil)
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

private struct StaticSimctlClient: SimctlClient {
    var storedDevices: [SimctlDevice]

    init(devices: [SimctlDevice]) {
        storedDevices = devices
    }

    func devices() async -> [SimctlDevice] {
        storedDevices
    }
}

private actor SequencedSimctlClient: SimctlClient {
    private var responses: [[SimctlDevice]]
    private var requests = 0

    init(responses: [[SimctlDevice]]) {
        self.responses = responses
    }

    func devices() async -> [SimctlDevice] {
        defer { requests += 1 }
        guard responses.isEmpty == false else {
            return []
        }
        return responses.removeFirst()
    }

    func requestCount() -> Int {
        requests
    }
}

private struct IncompleteFileSizeScanner: FileSizeScanning {
    func size(of url: URL) -> FileSizeResult {
        FileSizeResult(
            bytes: 0,
            unreadablePaths: [url.path],
            isComplete: false,
            incompleteReason: "Fixture is unreadable.")
    }
}

private struct RecordingOpenFileChecker: OpenFileChecking {
    var result: OpenFileCheckResult

    func checkOpenFiles(under url: URL) async -> OpenFileCheckResult {
        result
    }
}

private struct CancellingOpenFileChecker: OpenFileChecking {
    func checkOpenFiles(under url: URL) async -> OpenFileCheckResult {
        withUnsafeCurrentTask { task in
            task?.cancel()
        }
        return .unavailable("Cancelled")
    }
}
