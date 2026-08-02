import Foundation

struct StorageComponent: Identifiable, Hashable, Codable, Sendable {
    var id: String { path }
    var title: String
    var domain: StorageDomain
    var path: String
    var bytes: Int64
    var safety: SafetyClassification
}

struct StorageDomainBreakdown: Identifiable, Hashable, Codable, Sendable {
    var id: StorageDomain { domain }
    var domain: StorageDomain
    var bytes: Int64
    var reclaimableBytes: Int64
    var itemCount: Int

    func share(of totalBytes: Int64) -> Double {
        guard totalBytes > 0 else {
            return 0
        }
        return min(1, max(0, Double(bytes) / Double(totalBytes)))
    }
}

struct StorageFootprint: Equatable, Hashable, Codable, Sendable {
    var capturedAt: Date
    var totalBytes: Int64
    var codexAttributedBytes: Int64
    var xcodeRelatedBytes: Int64
    var reclaimableBytes: Int64
    var reviewBytes: Int64
    var activeBytes: Int64
    var recentGrowthBytes: Int64
    var availableDiskBytes: Int64?
    var lowDiskThresholdBytes: Int64
    var topComponents: [StorageComponent]
    var domainBreakdowns: [StorageDomainBreakdown]
    var missingPaths: [String]
    var unreadablePaths: [String]

    var hasLowDiskSpace: Bool {
        guard let availableDiskBytes else {
            return false
        }
        return availableDiskBytes <= lowDiskThresholdBytes
    }

    static func make(
        snapshot: StorageSnapshot,
        previousSnapshot: StorageSnapshot?,
        availableDiskBytes: Int64?,
        lowDiskThresholdBytes: Int64) -> StorageFootprint
    {
        let previousTotal = previousSnapshot?.totalBytes ?? snapshot.totalBytes
        let domainTotals = snapshot.groupedDomainTotals
        let breakdowns = StorageDomain.allCases.compactMap { domain -> StorageDomainBreakdown? in
            let domainItems = snapshot.items.filter { $0.domain == domain }
            guard domainItems.isEmpty == false else {
                return nil
            }
            return StorageDomainBreakdown(
                domain: domain,
                bytes: domainTotals[domain] ?? 0,
                reclaimableBytes: domainItems.filter(\.isCleanupEligible).reduce(0) { $0 + max(0, $1.bytes) },
                itemCount: domainItems.count)
        }
        .sorted { $0.bytes > $1.bytes }

        return StorageFootprint(
            capturedAt: snapshot.capturedAt,
            totalBytes: snapshot.totalBytes,
            codexAttributedBytes: snapshot.codexAttributedBytes,
            xcodeRelatedBytes: snapshot.xcodeRelatedBytes,
            reclaimableBytes: snapshot.reclaimableBytes,
            reviewBytes: snapshot.reviewBytes,
            activeBytes: snapshot.activeBytes,
            recentGrowthBytes: max(0, snapshot.totalBytes - previousTotal),
            availableDiskBytes: availableDiskBytes,
            lowDiskThresholdBytes: lowDiskThresholdBytes,
            topComponents: snapshot.items.prefix(8).map {
                StorageComponent(
                    title: $0.displayName,
                    domain: $0.domain,
                    path: $0.path,
                    bytes: $0.bytes,
                    safety: $0.safety)
            },
            domainBreakdowns: breakdowns,
            missingPaths: snapshot.missingPaths,
            unreadablePaths: snapshot.unreadablePaths)
    }
}
