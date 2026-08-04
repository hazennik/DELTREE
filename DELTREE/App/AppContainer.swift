import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let settings: AppSettingsStore
    let dashboardViewModel: DashboardViewModel
    let mainThreadHangWatchdog: MainThreadHangWatchdog
    let memoryPressureMonitor: MemoryPressureMonitor
    let updateService: AppUpdateService

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer

        let settings = AppSettingsStore()
        let mainThreadHangWatchdog = MainThreadHangWatchdog.makeDefault()
        let rootCatalog = StorageRootCatalog.live()
        let attributionTracker = LiveAttributionTracker()
        let processSampler = LiveProcessSampler()
        let trashService = FileManagerTrashService()
        let powerStateProvider = LivePowerStateProvider()
        let storageScanner = DefaultStorageScanner(
            rootCatalog: rootCatalog,
            codexSessionScanner: CodexThreadCatalogReader(homeDirectory: rootCatalog.homeDirectory),
            processSampler: processSampler,
            attributionTracker: attributionTracker)
        let persistence = SwiftDataSnapshotStore(container: modelContainer)

        self.settings = settings
        let dashboardViewModel = DashboardViewModel(
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
            notificationService: UserNotificationService(),
            mainThreadHangWatchdog: mainThreadHangWatchdog,
            powerStateProvider: powerStateProvider,
            backgroundScanPolicy: .production)
        self.dashboardViewModel = dashboardViewModel
        self.mainThreadHangWatchdog = mainThreadHangWatchdog
        updateService = AppUpdateService(
            distributionChannel: .current(),
            configuration: .current(),
            makeUpdater: SparkleAppUpdater.init)
        memoryPressureMonitor = MemoryPressureMonitor { [weak dashboardViewModel] level in
            Task { @MainActor in
                dashboardViewModel?.trimTransientStateForMemoryPressure(level: level)
            }
        }
    }
}
