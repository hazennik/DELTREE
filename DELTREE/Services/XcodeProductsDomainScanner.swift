import Foundation

struct XcodeProductsDomainScanner: DomainScanning {
    var domain: StorageDomain { .xcodeProducts }
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
                where candidate.pathExtension.lowercased() != "xcresult" &&
                context.configuration.isExcluded(candidate.path) == false
            {
                let size = context.fileSizeScanner.size(of: candidate)
                result.unreadablePaths.append(contentsOf: size.unreadablePaths)
                guard size.bytes > 0 else {
                    continue
                }

                var metadata: [String: String] = [
                    "root": root.standardizedFileURL.path,
                    "suggestedAction": StorageAction.moveToTrash.rawValue,
                    "state": "Review",
                ]
                metadata.merge(CodexSessionMatcher.metadata(for: candidate.path, sessions: context.codexSessions)) { current, _ in current }

                let item = await StorageItemFactory.makeItem(
                    url: candidate,
                    domain: .xcodeProducts,
                    kind: .xcodeProduct,
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
}
