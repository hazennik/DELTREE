import Foundation

struct DefaultCleanupExecutor: CleanupExecuting {
    private let trashService: any TrashServicing
    private let simctlClient: any SimctlCommanding

    init(
        trashService: any TrashServicing = FileManagerTrashService(),
        simctlClient: any SimctlCommanding = LiveSimctlCommandClient())
    {
        self.trashService = trashService
        self.simctlClient = simctlClient
    }

    func execute(_ plan: CleanupPlan) async -> CleanupExecutionResult {
        var completed: [CleanupPlanAction] = []
        var failed: [CleanupPlanAction: String] = [:]

        for action in plan.actions {
            do {
                try await execute(action)
                completed.append(action)
            } catch {
                failed[action] = error.localizedDescription
            }
        }

        return CleanupExecutionResult(
            performedAt: Date(),
            completedActions: completed,
            failedActions: failed,
            skippedItems: plan.blockedItems)
    }

    private func execute(_ planAction: CleanupPlanAction) async throws {
        switch planAction.action {
        case .moveToTrash, .cleanDerivedData, .removeXCResult, .removeCodexWorkspace:
            try await trashService.moveToTrash(planAction.item)
        case .deleteUnavailableSimulator:
            let udid = try requiredUDID(from: planAction.item)
            try await simctlClient.deleteDevice(udid: udid)
        case .eraseSimulator:
            let udid = try requiredUDID(from: planAction.item)
            try await simctlClient.eraseDevice(udid: udid)
        case .none, .revealInFinder, .copyPath, .exportReport, .ignore, .markUserOwned, .resetAttribution:
            throw CleanupExecutionError.unsupportedAction(planAction.action)
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

    var errorDescription: String? {
        switch self {
        case let .unsupportedAction(action):
            "\(action.displayName) cannot be executed as a cleanup action."
        case .missingSimulatorUDID:
            "The simulator UDID is missing."
        }
    }
}
