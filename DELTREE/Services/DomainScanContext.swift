import Foundation

struct DomainScanContext: Sendable {
    var fileManager: FileManager
    var fileSizeScanner: any FileSizeScanning
    var simctlDevices: [SimctlDevice]
    var codexSessions: [CodexSessionRecord]
    var processSnapshot: ProcessSnapshot
    var attributionTracker: any AttributionTracking
    var configuration: StorageScanConfiguration
    var now: Date
}
