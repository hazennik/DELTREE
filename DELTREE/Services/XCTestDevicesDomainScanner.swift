import Foundation

struct XCTestDevicesDomainScanner: DomainScanning {
    var domain: StorageDomain { .xcTestDevices }
    private let roots: [URL]

    init(roots: [URL]) {
        self.roots = roots
    }

    func scan(context: DomainScanContext) async -> DomainScanResult {
        var result = DomainScanResult.empty

        for root in roots {
            if DirectoryScannerHelpers.missingOrUnreadableRoot(root, context: context, result: &result) {
                continue
            }

            for candidate in DirectoryScannerHelpers.topLevelCandidates(root: root, context: context)
                where context.configuration.isExcluded(candidate.path) == false
            {
                let size = context.fileSizeScanner.size(of: candidate)
                result.unreadablePaths.append(contentsOf: size.unreadablePaths)
                guard size.bytes > 0 else {
                    continue
                }

                let fileMetadata = FileMetadataReader.metadata(for: candidate)
                let ageDays = DirectoryScannerHelpers.ageDays(since: fileMetadata.modifiedAt, now: context.now)
                var metadata: [String: String] = [
                    "root": root.standardizedFileURL.path,
                    "suggestedAction": StorageAction.moveToTrash.rawValue,
                    "state": DirectoryScannerHelpers.state(ageDays: ageDays, staleThreshold: context.configuration.staleXCTestDeviceDays),
                ]
                if let ageDays {
                    metadata["ageDays"] = "\(ageDays)"
                }
                metadata.merge(projectMetadata(under: candidate, context: context)) { current, _ in current }
                metadata.merge(CodexSessionMatcher.metadata(for: candidate.path, sessions: context.codexSessions)) { current, _ in current }

                let item = await StorageItemFactory.makeItem(
                    url: candidate,
                    domain: .xcTestDevices,
                    kind: .xcTestDevice,
                    size: size,
                    metadata: metadata,
                    isActive: false,
                    explicitLastUsedAt: nil,
                    context: context)
                result.items.append(item)
            }
        }

        return result
    }

    private func projectMetadata(under url: URL, context: DomainScanContext) -> [String: String] {
        guard let enumerator = context.fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true })
        else {
            return [:]
        }

        for case let candidate as URL in enumerator {
            if Task.isCancelled {
                enumerator.skipDescendants()
                break
            }

            if candidate.pathExtension == "xctestconfiguration" || candidate.lastPathComponent == "SessionInfo.plist" {
                return ["testMetadata": candidate.lastPathComponent]
            }
        }
        return [:]
    }
}
