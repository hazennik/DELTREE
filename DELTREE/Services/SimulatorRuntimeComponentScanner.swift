import Foundation

struct SimulatorRuntimeComponentScanner: DomainScanning {
    var domain: StorageDomain
    private let kind: StorageKind
    private let roots: [URL]
    private let packageExtension: String?

    init(domain: StorageDomain, kind: StorageKind, roots: [URL], packageExtension: String? = nil) {
        self.domain = domain
        self.kind = kind
        self.roots = roots
        self.packageExtension = packageExtension
    }

    func scan(context: DomainScanContext) async -> DomainScanResult {
        var result = DomainScanResult.empty

        for root in roots {
            if DirectoryScannerHelpers.missingOrUnreadableRoot(root, context: context, result: &result) {
                continue
            }

            let candidates: [URL]
            if let packageExtension {
                candidates = DirectoryScannerHelpers.packageURLs(root: root, extensionName: packageExtension, context: context)
            } else {
                candidates = DirectoryScannerHelpers.topLevelCandidates(root: root, context: context)
            }

            for candidate in candidates where context.configuration.isExcluded(candidate.path) == false {
                let size = context.fileSizeScanner.size(of: candidate)
                result.unreadablePaths.append(contentsOf: size.unreadablePaths)
                guard size.bytes > 0 else {
                    continue
                }

                let metadata = [
                    "root": root.standardizedFileURL.path,
                    "runtimeName": candidate.deletingPathExtension().lastPathComponent,
                    "suggestedAction": StorageAction.none.rawValue,
                    "state": "Installed",
                ]
                let item = await StorageItemFactory.makeItem(
                    url: candidate,
                    domain: domain,
                    kind: kind,
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
