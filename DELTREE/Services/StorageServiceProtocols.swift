import Foundation

protocol FileSizeScanning: Sendable {
    func size(of url: URL) -> FileSizeResult
}

protocol SimctlClient: Sendable {
    func devices() async -> [SimctlDevice]
}

protocol SimctlCommanding: Sendable {
    func deleteDevice(udid: String) async throws
    func eraseDevice(udid: String) async throws
}

protocol ProcessSampling: Sendable {
    func sample() async -> ProcessSnapshot
}

protocol CodexSessionScanning: Sendable {
    func sessions(now: Date) async -> [CodexSessionRecord]
}

protocol DiskSpaceProviding: Sendable {
    func availableBytes(for url: URL) -> Int64?
}

protocol NotificationServicing: Sendable {
    func requestAuthorization() async -> Bool
    func notify(identifier: String, title: String, body: String) async
}

protocol AttributionTracking: Sendable {
    func recordFilesystemEvents(paths: [String], processes: ProcessSnapshot, at date: Date) async
    func attribution(
        forPath path: String,
        domain: StorageDomain,
        kind: StorageKind,
        metadata: [String: String],
        processes: ProcessSnapshot,
        now: Date) async -> AttributionResult
}

protocol DomainScanning: Sendable {
    var domain: StorageDomain { get }
    func scan(context: DomainScanContext) async -> DomainScanResult
}

protocol StorageScanning: Sendable {
    func scan(configuration: StorageScanConfiguration, now: Date) async -> StorageSnapshot
}

protocol CleanupPlanning: Sendable {
    func planSafeCleanup(from snapshot: StorageSnapshot) -> CleanupPlan
    func planCleanup(for item: StorageItem, action: StorageAction, in snapshot: StorageSnapshot) -> CleanupPlan
}

protocol TrashServicing: Sendable {
    func moveToTrash(_ item: StorageItem) async throws
}

protocol CleanupExecuting: Sendable {
    func execute(_ plan: CleanupPlan) async -> CleanupExecutionResult
}

protocol StorageWatching: AnyObject, Sendable {
    var onChange: (@Sendable ([String]) -> Void)? { get set }
    func start(paths: [String])
    func stop()
}
