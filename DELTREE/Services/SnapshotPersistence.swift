import Foundation
import SwiftData

@MainActor
protocol SnapshotPersisting: AnyObject {
    func saveSnapshot(_ snapshot: StorageSnapshot) throws
    func mostRecentSnapshot() -> StorageSnapshot?
    func saveDelta(_ delta: StorageDelta) throws
    func saveCleanup(
        performedAt: Date,
        totalBytes: Int64,
        itemCount: Int,
        status: String,
        paths: [String],
        skippedPaths: [String],
        errors: [String: String],
        initiator: String) throws
    func saveAttributionEvent(owner: OwnerAttribution, confidence: Double, paths: [String], observedAt: Date) throws
    func saveManualOverride(_ override: ManualStorageOverride) throws
    func clearManualOverride(path: String) throws
    func manualOverrides() -> [String: ManualStorageOverride]
    func recentCleanupRecords(limit: Int) -> [CleanupHistoryRecord]
    func recentScanRecords(limit: Int) -> [ScanHistoryRecord]
    func recentDeltaRecords(limit: Int) -> [StorageDeltaRecord]
}

@MainActor
final class SwiftDataSnapshotStore: SnapshotPersisting {
    struct RetentionLimits: Sendable {
        var scanHistory: Int
        var deltaHistory: Int
        var cleanupHistory: Int
        var attributionEvents: Int

        nonisolated static let production = RetentionLimits(
            scanHistory: 500,
            deltaHistory: 500,
            cleanupHistory: 200,
            attributionEvents: 500)
    }

    private let container: ModelContainer
    private let retentionLimits: RetentionLimits

    init(container: ModelContainer, retentionLimits: RetentionLimits = .production) {
        self.container = container
        self.retentionLimits = retentionLimits
    }

    func saveSnapshot(_ snapshot: StorageSnapshot) throws {
        let context = ModelContext(container)
        context.insert(ScanHistoryRecord(snapshot: snapshot))
        try pruneScanHistory(in: context, keeping: retentionLimits.scanHistory)
        try context.save()
    }

    func mostRecentSnapshot() -> StorageSnapshot? {
        var descriptor = FetchDescriptor<ScanHistoryRecord>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        guard let record = try? ModelContext(container).fetch(descriptor).first,
              let data = record.encodedSnapshot
        else {
            return nil
        }
        return try? JSONDecoder.storage.decode(StorageSnapshot.self, from: data)
    }

    func saveDelta(_ delta: StorageDelta) throws {
        guard delta.isEmpty == false else {
            return
        }

        let context = ModelContext(container)
        context.insert(StorageDeltaRecord(delta: delta))
        try pruneDeltaHistory(in: context, keeping: retentionLimits.deltaHistory)
        try context.save()
    }

    func saveCleanup(
        performedAt: Date,
        totalBytes: Int64,
        itemCount: Int,
        status: String,
        paths: [String],
        skippedPaths: [String],
        errors: [String: String],
        initiator: String) throws
    {
        let context = ModelContext(container)
        context.insert(CleanupHistoryRecord(
            performedAt: performedAt,
            totalBytes: totalBytes,
            itemCount: itemCount,
            status: status,
            paths: paths,
            skippedPaths: skippedPaths,
            errors: errors,
            initiator: initiator))
        try pruneCleanupHistory(in: context, keeping: retentionLimits.cleanupHistory)
        try context.save()
    }

    func saveAttributionEvent(owner: OwnerAttribution, confidence: Double, paths: [String], observedAt: Date) throws {
        let context = ModelContext(container)
        context.insert(AttributionEventRecord(
            observedAt: observedAt,
            owner: owner,
            confidence: confidence,
            paths: paths))
        try pruneAttributionEvents(in: context, keeping: retentionLimits.attributionEvents)
        try context.save()
    }

    func saveManualOverride(_ override: ManualStorageOverride) throws {
        let context = ModelContext(container)
        let standardizedPath = URL(fileURLWithPath: override.path).standardizedFileURL.path
        let descriptor = FetchDescriptor<ManualOverrideRecord>(
            predicate: #Predicate { $0.path == standardizedPath })

        if let existing = try context.fetch(descriptor).first {
            existing.update(from: override)
        } else {
            context.insert(ManualOverrideRecord(override: override))
        }
        try context.save()
    }

    func clearManualOverride(path: String) throws {
        let context = ModelContext(container)
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let descriptor = FetchDescriptor<ManualOverrideRecord>(
            predicate: #Predicate { $0.path == standardizedPath })
        let records = try context.fetch(descriptor)
        for record in records {
            context.delete(record)
        }
        try context.save()
    }

    func manualOverrides() -> [String: ManualStorageOverride] {
        let descriptor = FetchDescriptor<ManualOverrideRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let records = (try? ModelContext(container).fetch(descriptor)) ?? []
        return Dictionary(uniqueKeysWithValues: records.map { ($0.path, $0.manualOverride) })
    }

    func recentCleanupRecords(limit: Int = 20) -> [CleanupHistoryRecord] {
        var descriptor = FetchDescriptor<CleanupHistoryRecord>(
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? ModelContext(container).fetch(descriptor)) ?? []
    }

    func recentScanRecords(limit: Int = 20) -> [ScanHistoryRecord] {
        var descriptor = FetchDescriptor<ScanHistoryRecord>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? ModelContext(container).fetch(descriptor)) ?? []
    }

    func recentDeltaRecords(limit: Int = 20) -> [StorageDeltaRecord] {
        var descriptor = FetchDescriptor<StorageDeltaRecord>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)])
        descriptor.fetchLimit = limit
        return (try? ModelContext(container).fetch(descriptor)) ?? []
    }

    private func pruneScanHistory(in context: ModelContext, keeping limit: Int) throws {
        var descriptor = FetchDescriptor<ScanHistoryRecord>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)])
        descriptor.includePendingChanges = true
        let records = try context.fetch(descriptor)
        for record in records.dropFirst(max(0, limit)) {
            context.delete(record)
        }
    }

    private func pruneDeltaHistory(in context: ModelContext, keeping limit: Int) throws {
        var descriptor = FetchDescriptor<StorageDeltaRecord>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)])
        descriptor.includePendingChanges = true
        let records = try context.fetch(descriptor)
        for record in records.dropFirst(max(0, limit)) {
            context.delete(record)
        }
    }

    private func pruneCleanupHistory(in context: ModelContext, keeping limit: Int) throws {
        var descriptor = FetchDescriptor<CleanupHistoryRecord>(
            sortBy: [SortDescriptor(\.performedAt, order: .reverse)])
        descriptor.includePendingChanges = true
        let records = try context.fetch(descriptor)
        for record in records.dropFirst(max(0, limit)) {
            context.delete(record)
        }
    }

    private func pruneAttributionEvents(in context: ModelContext, keeping limit: Int) throws {
        var descriptor = FetchDescriptor<AttributionEventRecord>(
            sortBy: [SortDescriptor(\.observedAt, order: .reverse)])
        descriptor.includePendingChanges = true
        let records = try context.fetch(descriptor)
        for record in records.dropFirst(max(0, limit)) {
            context.delete(record)
        }
    }
}
