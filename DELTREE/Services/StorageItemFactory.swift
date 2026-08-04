import Foundation

enum StorageItemFactory {
    static func makeItem(
        url: URL,
        domain: StorageDomain,
        kind: StorageKind,
        size: FileSizeResult,
        metadata: [String: String],
        isActive: Bool,
        explicitLastUsedAt: Date?,
        context: DomainScanContext) async -> StorageItem
    {
        let fileMetadata = FileMetadataReader.metadata(for: url)
        var metadata = metadata
        if size.isComplete == false {
            metadata["scanComplete"] = "false"
            metadata["scannedEntryCount"] = "\(size.scannedEntryCount)"
            if let incompleteReason = size.incompleteReason {
                metadata["scanIncompleteReason"] = incompleteReason
            }
        }
        let override = context.configuration.manualOverride(for: url.path)
        let suggestedAction = StorageAction(rawValue: metadata["suggestedAction"] ?? "") ?? .none
        let attribution = await context.attributionTracker.attribution(
            forPath: url.path,
            domain: domain,
            kind: kind,
            metadata: metadata,
            processes: context.processSnapshot,
            now: context.now)
        let owner = override?.owner ?? attribution.owner
        let confidence = override?.owner == nil ? attribution.confidence : 1.0
        if let override, override.owner != nil {
            metadata["manualOverride"] = "Owner"
        }

        return StorageItem(
            id: url.standardizedFileURL.path,
            domain: domain,
            kind: kind,
            path: url.standardizedFileURL.path,
            displayName: displayName(for: url, metadata: metadata),
            bytes: size.bytes,
            createdAt: fileMetadata.createdAt,
            modifiedAt: fileMetadata.modifiedAt,
            lastUsedAt: explicitLastUsedAt ?? fileMetadata.accessedAt ?? fileMetadata.modifiedAt,
            attribution: owner,
            attributionConfidence: confidence,
            safety: .unknown,
            isActive: isActive,
            suggestedAction: suggestedAction,
            cleanupImpact: cleanupImpact(for: suggestedAction, bytes: size.bytes),
            isPinned: override?.isPinned ?? false,
            isIgnored: override?.isIgnored ?? false,
            explanation: domainExplanation(domain: domain, attributionReason: attribution.reason),
            metadata: metadata)
    }

    private static func displayName(for url: URL, metadata: [String: String]) -> String {
        if let name = metadata["deviceName"], let udid = metadata["udid"] {
            return "\(name) (\(String(udid.prefix(8))))"
        }
        if let project = metadata["relatedProject"], project.isEmpty == false {
            return project
        }
        let lastPathComponent = url.lastPathComponent
        return lastPathComponent.isEmpty ? url.path : lastPathComponent
    }

    private static func cleanupImpact(for action: StorageAction, bytes: Int64) -> String {
        guard action.isCleanupExecutionAction else {
            return action.explanation
        }
        return "\(action.explanation) Expected reclaim: \(StorageFormatters.byteCount(bytes))."
    }

    private static func domainExplanation(domain: StorageDomain, attributionReason: String) -> String {
        let domainReason: String
        switch domain {
        case .codexHome:
            domainReason = "Codex stores local session, cache, log, and configuration data here."
        case .codexWorkspaces:
            domainReason = "Codex task workspaces and generated local artifacts can accumulate here."
        case .coreSimulatorDevices:
            domainReason = "Xcode stores simulator device data, app containers, logs, and UI test state here."
        case .xcTestDevices:
            domainReason = "Xcode creates XCTest device data while running tests."
        case .derivedData:
            domainReason = "Xcode stores build products, indexes, modules, and package checkouts in DerivedData."
        case .xcResults:
            domainReason = "Xcode result bundles store test logs, screenshots, attachments, and diagnostics."
        case .xcodeProducts:
            domainReason = "Xcode Products can contain local build products and test artifacts outside DerivedData."
        case .deviceSupport:
            domainReason = "DeviceSupport folders help Xcode debug physical devices on matching OS versions."
        case .simulatorRuntimes:
            domainReason = "Simulator runtimes provide OS images used by simulator devices."
        case .simulatorImages:
            domainReason = "Simulator images are installed OS assets used to create or run simulator devices."
        case .coreSimulatorCaches:
            domainReason = "CoreSimulator caches store generated simulator support data and can grow after repeated tests."
        case .archives:
            domainReason = "Archives can contain signed builds, dSYMs, and distribution metadata."
        case .swiftPackageCaches:
            domainReason = "SwiftPM caches packages and build support data for dependency resolution."
        }
        return "\(domainReason) \(attributionReason)"
    }
}
