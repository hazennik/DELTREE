import Foundation

struct DefaultCleanupExecutor: CleanupExecuting, @unchecked Sendable {
    private let fileManager: FileManager
    private let trashService: any TrashServicing
    private let simctlCommandClient: any SimctlCommanding
    private let simctlDeviceClient: any SimctlClient
    private let openFileChecker: any OpenFileChecking

    init(
        fileManager: FileManager = .default,
        trashService: any TrashServicing = FileManagerTrashService(),
        simctlClient: any SimctlCommanding = LiveSimctlCommandClient(),
        simctlDeviceClient: any SimctlClient = LiveSimctlClient(),
        openFileChecker: any OpenFileChecking = LiveLsofOpenFileChecker())
    {
        self.fileManager = fileManager
        self.trashService = trashService
        self.simctlCommandClient = simctlClient
        self.simctlDeviceClient = simctlDeviceClient
        self.openFileChecker = openFileChecker
    }

    func execute(_ plan: CleanupPlan) async -> CleanupExecutionResult {
        var completed: [CleanupPlanAction] = []
        var failed: [CleanupPlanAction: String] = [:]
        var skippedItems = plan.blockedItems
        let currentSimctlDevices = await currentSimctlDevicesIfNeeded(for: plan)

        for (index, action) in plan.actions.enumerated() {
            do {
                try Task.checkCancellation()
                try await revalidate(action, currentSimctlDevices: currentSimctlDevices)
                try Task.checkCancellation()
                try await execute(action)
                completed.append(action)
            } catch is CancellationError {
                skippedItems.append(contentsOf: plan.actions[index...].map(\.item))
                break
            } catch {
                failed[action] = error.localizedDescription
            }
        }

        return CleanupExecutionResult(
            performedAt: Date(),
            completedActions: completed,
            failedActions: failed,
            skippedItems: skippedItems)
    }

    private func execute(_ planAction: CleanupPlanAction) async throws {
        switch planAction.action {
        case .moveToTrash, .cleanDerivedData, .removeXCResult, .removeCodexWorkspace:
            try await trashService.moveToTrash(planAction.item)
        case .deleteUnavailableSimulator:
            let udid = try requiredUDID(from: planAction.item)
            try await simctlCommandClient.deleteDevice(udid: udid)
        case .eraseSimulator:
            let udid = try requiredUDID(from: planAction.item)
            try await simctlCommandClient.eraseDevice(udid: udid)
        case .none, .revealInFinder, .copyPath, .exportReport, .ignore, .markUserOwned, .resetAttribution:
            throw CleanupExecutionError.unsupportedAction(planAction.action)
        }
    }

    private func revalidate(
        _ planAction: CleanupPlanAction,
        currentSimctlDevices: [SimctlDevice]?) async throws
    {
        let item = planAction.item
        let action = planAction.action
        guard action.isCleanupExecutionAction else {
            throw CleanupExecutionError.unsupportedAction(action)
        }
        guard item.isActive == false else {
            throw CleanupExecutionError.itemBecameActive(item.path)
        }
        guard item.isPinned == false else {
            throw CleanupExecutionError.itemPinned(item.path)
        }
        guard item.isIgnored == false else {
            throw CleanupExecutionError.itemIgnored(item.path)
        }
        guard blockedDomain(item.domain) == false else {
            throw CleanupExecutionError.blockedDomain(item.domain)
        }
        guard safetyAllowsExecution(item: item, action: action) else {
            throw CleanupExecutionError.unsafeClassification(item.safety)
        }

        if item.domain == .coreSimulatorDevices,
           action != .deleteUnavailableSimulator,
           action != .eraseSimulator
        {
            throw CleanupExecutionError.invalidSimulatorAction(action)
        }

        if item.domain == .coreSimulatorDevices || action == .deleteUnavailableSimulator || action == .eraseSimulator {
            try validateSimulatorState(for: planAction, currentSimctlDevices: currentSimctlDevices ?? [])
        }

        if action.usesTrash {
            try await validateTrashAction(for: item)
        }
    }

    private func validateTrashAction(for item: StorageItem) async throws {
        let path = URL(fileURLWithPath: item.path).standardizedFileURL.path
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw CleanupExecutionError.pathMissing(path)
        }

        let result = await openFileChecker.checkOpenFiles(
            under: URL(fileURLWithPath: path, isDirectory: isDirectory.boolValue))
        try Task.checkCancellation()
        switch result {
        case .clear:
            return
        case .openFilesFound:
            throw CleanupExecutionError.pathHasOpenFiles(path)
        case let .unavailable(reason):
            throw CleanupExecutionError.openFileCheckUnavailable(path: path, reason: reason)
        }
    }

    private func validateSimulatorState(
        for planAction: CleanupPlanAction,
        currentSimctlDevices: [SimctlDevice]) throws
    {
        let item = planAction.item
        let udid = try requiredUDID(from: item)
        guard let device = currentDevice(udid: udid, item: item, devices: currentSimctlDevices) else {
            if planAction.action == .deleteUnavailableSimulator || planAction.action == .eraseSimulator {
                throw CleanupExecutionError.simulatorNotFound(udid)
            }
            return
        }

        guard device.isBooted == false else {
            throw CleanupExecutionError.simulatorBooted(udid)
        }

        switch planAction.action {
        case .deleteUnavailableSimulator:
            guard device.isAvailable == false else {
                throw CleanupExecutionError.simulatorNoLongerUnavailable(udid)
            }
        case .eraseSimulator:
            guard device.isAvailable else {
                throw CleanupExecutionError.simulatorUnavailable(udid)
            }
        case .moveToTrash, .cleanDerivedData, .removeXCResult, .removeCodexWorkspace,
             .none, .revealInFinder, .copyPath, .exportReport, .ignore, .markUserOwned, .resetAttribution:
            return
        }
    }

    private func currentDevice(udid: String, item: StorageItem, devices: [SimctlDevice]) -> SimctlDevice? {
        devices.first { device in
            if device.udid == udid {
                return true
            }
            guard let dataPath = device.dataPath else {
                return false
            }
            let devicePath = URL(fileURLWithPath: dataPath).standardizedFileURL.path
            let itemPath = URL(fileURLWithPath: item.path).standardizedFileURL.path
            return devicePath == itemPath || devicePath.hasPrefix(itemPath + "/")
        }
    }

    private func currentSimctlDevicesIfNeeded(for plan: CleanupPlan) async -> [SimctlDevice]? {
        guard plan.actions.contains(where: { action in
            action.item.domain == .coreSimulatorDevices ||
                action.action == .deleteUnavailableSimulator ||
                action.action == .eraseSimulator
        }) else {
            return nil
        }
        return await simctlDeviceClient.devices()
    }

    private func safetyAllowsExecution(item: StorageItem, action: StorageAction) -> Bool {
        item.safety == .safeToTrash ||
            item.safety == .probablySafe ||
            item.safety == .reviewRecommended ||
            action == .eraseSimulator
    }

    private func blockedDomain(_ domain: StorageDomain) -> Bool {
        switch domain {
        case .archives, .deviceSupport, .simulatorRuntimes, .simulatorImages:
            true
        case .codexHome, .codexWorkspaces, .coreSimulatorDevices, .xcTestDevices,
             .derivedData, .xcResults, .xcodeProducts, .coreSimulatorCaches, .swiftPackageCaches:
            false
        }
    }

    private func requiredUDID(from item: StorageItem) throws -> String {
        guard let udid = item.metadata["udid"], udid.isEmpty == false else {
            throw CleanupExecutionError.missingSimulatorUDID
        }
        return udid
    }
}

enum CleanupExecutionError: LocalizedError, Equatable {
    case unsupportedAction(StorageAction)
    case missingSimulatorUDID
    case itemBecameActive(String)
    case itemPinned(String)
    case itemIgnored(String)
    case blockedDomain(StorageDomain)
    case pathMissing(String)
    case pathHasOpenFiles(String)
    case openFileCheckUnavailable(path: String, reason: String)
    case unsafeClassification(SafetyClassification)
    case invalidSimulatorAction(StorageAction)
    case simulatorNotFound(String)
    case simulatorBooted(String)
    case simulatorNoLongerUnavailable(String)
    case simulatorUnavailable(String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedAction(action):
            "\(action.displayName) cannot be executed as a cleanup action."
        case .missingSimulatorUDID:
            "The simulator UDID is missing."
        case let .itemBecameActive(path):
            "\(path) is active and was skipped during final cleanup validation."
        case let .itemPinned(path):
            "\(path) is pinned and was skipped during final cleanup validation."
        case let .itemIgnored(path):
            "\(path) is ignored and was skipped during final cleanup validation."
        case let .blockedDomain(domain):
            "\(domain.displayName) is excluded from cleanup."
        case let .pathMissing(path):
            "\(path) no longer exists."
        case let .pathHasOpenFiles(path):
            "\(path) has open files and was skipped."
        case let .openFileCheckUnavailable(path, reason):
            "Open-file validation for \(path) could not be completed: \(reason)"
        case let .unsafeClassification(safety):
            "\(safety.displayName) items cannot be executed as cleanup actions."
        case let .invalidSimulatorAction(action):
            "\(action.displayName) cannot be used for a simulator device. Use an approved simctl action."
        case let .simulatorNotFound(udid):
            "Simulator \(udid) is no longer present in simctl."
        case let .simulatorBooted(udid):
            "Simulator \(udid) is booted and was skipped."
        case let .simulatorNoLongerUnavailable(udid):
            "Simulator \(udid) is no longer marked unavailable."
        case let .simulatorUnavailable(udid):
            "Simulator \(udid) is unavailable and cannot be erased."
        }
    }
}
