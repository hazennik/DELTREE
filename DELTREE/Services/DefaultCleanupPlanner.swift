import Foundation

struct DefaultCleanupPlanner: CleanupPlanning, @unchecked Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func planSafeCleanup(from snapshot: StorageSnapshot) -> CleanupPlan {
        var actions: [CleanupPlanAction] = []
        var blocked: [StorageItem] = []

        for item in snapshot.items where item.safety == .safeToTrash {
            if let action = preflightAction(
                for: item,
                requestedAction: item.suggestedAction == .none ? .moveToTrash : item.suggestedAction,
                allowReviewItems: false)
            {
                actions.append(action)
            } else {
                blocked.append(item)
            }
        }

        return CleanupPlan(actions: actions, blockedItems: blocked)
    }

    func planCleanup(for item: StorageItem, action: StorageAction, in snapshot: StorageSnapshot) -> CleanupPlan {
        if let current = snapshot.items.first(where: { $0.path == item.path }),
           let preflightAction = preflightAction(for: current, requestedAction: action, allowReviewItems: true)
        {
            return CleanupPlan(actions: [preflightAction], blockedItems: [])
        }
        return CleanupPlan(actions: [], blockedItems: [item])
    }

    private func preflightAction(
        for item: StorageItem,
        requestedAction: StorageAction,
        allowReviewItems: Bool) -> CleanupPlanAction?
    {
        guard item.isActive == false,
              item.isPinned == false,
              item.isIgnored == false,
              blockedDomain(item.domain) == false,
              requestedAction.isCleanupExecutionAction
        else {
            return nil
        }

        if requestedAction == .deleteUnavailableSimulator || requestedAction == .eraseSimulator {
            guard item.metadata["udid"]?.isEmpty == false else {
                return nil
            }
        } else {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) else {
                return nil
            }
        }

        let allowedBySafety = item.safety == .safeToTrash ||
            (allowReviewItems && (item.safety == .probablySafe || item.safety == .reviewRecommended)) ||
            requestedAction == .eraseSimulator
        guard allowedBySafety else {
            return nil
        }

        return CleanupPlanAction(
            item: item,
            action: requestedAction,
            reason: item.cleanupImpact.isEmpty ? item.safety.displayName : item.cleanupImpact)
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
}
