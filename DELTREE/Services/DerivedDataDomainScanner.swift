import Foundation

struct DerivedDataDomainScanner: DomainScanning {
    var domain: StorageDomain { .derivedData }
    private let roots: [URL]
    private let classifier = DerivedDataClassifier()

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

                var metadata = classifier.metadata(for: candidate, context: context)
                metadata["root"] = root.standardizedFileURL.path

                let item = await StorageItemFactory.makeItem(
                    url: candidate,
                    domain: .derivedData,
                    kind: .derivedData,
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
