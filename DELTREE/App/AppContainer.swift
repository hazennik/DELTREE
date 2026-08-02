import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let settings: AppSettingsStore
    let dashboardViewModel: DashboardViewModel

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer

        let settings = AppSettingsStore()
        let rootCatalog = StorageRootCatalog.live()
        let attributionTracker = LiveAttributionTracker()
        let processSampler = LiveProcessSampler()
        let trashService = FileManagerTrashService()
        let storageScanner = DefaultStorageScanner(
            rootCatalog: rootCatalog,
            codexSessionScanner: CodexThreadCatalogReader(homeDirectory: rootCatalog.homeDirectory),
            processSampler: processSampler,
            attributionTracker: attributionTracker)
        let persistence = SwiftDataSnapshotStore(container: modelContainer)

        self.settings = settings
        dashboardViewModel = DashboardViewModel(
            scanner: storageScanner,
            cleanupPlanner: DefaultCleanupPlanner(),
            cleanupExecutor: DefaultCleanupExecutor(trashService: trashService),
            persistence: persistence,
            settings: settings,
            watcher: FSEventsStorageWatcher(),
            rootCatalog: rootCatalog,
            processSampler: processSampler,
            attributionTracker: attributionTracker,
            diskSpaceProvider: LiveDiskSpaceProvider(),
            notificationService: UserNotificationService())
    }
}
