import Foundation

struct CleanupPlanAction: Identifiable, Hashable, Sendable {
    var id = UUID()
    var item: StorageItem
    var action: StorageAction
    var reason: String

    var bytes: Int64 {
        max(0, item.bytes)
    }
}

struct CleanupExecutionResult: Hashable, Sendable {
    var performedAt: Date
    var completedActions: [CleanupPlanAction]
    var failedActions: [CleanupPlanAction: String]
    var skippedItems: [StorageItem]

    var reclaimedBytes: Int64 {
        completedActions.reduce(0) { $0 + $1.bytes }
    }

    var status: String {
        if failedActions.isEmpty && skippedItems.isEmpty {
            return "completed"
        }
        if completedActions.isEmpty {
            return "failed"
        }
        return "partialFailure"
    }
}

struct CleanupPlan: Identifiable, Hashable, Sendable {
    var id = UUID()
    var createdAt = Date()
    var actions: [CleanupPlanAction]
    var blockedItems: [StorageItem]

    init(actions: [CleanupPlanAction], blockedItems: [StorageItem]) {
        self.actions = actions
        self.blockedItems = blockedItems
    }

    init(items: [StorageItem], blockedItems: [StorageItem]) {
        actions = items.map { item in
            CleanupPlanAction(
                item: item,
                action: item.suggestedAction == .none ? .moveToTrash : item.suggestedAction,
                reason: item.safety.displayName)
        }
        self.blockedItems = blockedItems
    }

    var items: [StorageItem] {
        actions.map(\.item)
    }

    var reclaimableBytes: Int64 {
        actions.reduce(0) { $0 + $1.bytes }
    }

    var itemCount: Int {
        actions.count
    }

    var permanentlyRemovesSimulatorData: Bool {
        actions.contains { $0.action.permanentlyRemovesSimulatorData }
    }
}
