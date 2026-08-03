import Foundation

struct CodexWorkspaceDomainScanner: DomainScanning {
    var domain: StorageDomain
    private let kind: StorageKind
    private let roots: [URL]
    private let mode: DirectoryScanMode

    init(domain: StorageDomain, kind: StorageKind, roots: [URL], mode: DirectoryScanMode = .topLevelChildren) {
        self.domain = domain
        self.kind = kind
        self.roots = roots
        self.mode = mode
    }

    func scan(context: DomainScanContext) async -> DomainScanResult {
        var result = DomainScanResult.empty

        for root in roots {
            if DirectoryScannerHelpers.missingOrUnreadableRoot(root, context: context, result: &result) {
                continue
            }

            let candidates: [URL]
            switch mode {
            case .wholeRoots:
                candidates = [root]
            case .topLevelChildren:
                candidates = DirectoryScannerHelpers.topLevelCandidates(root: root, context: context)
            case let .matchingPackages(extensionName):
                candidates = DirectoryScannerHelpers.packageURLs(root: root, extensionName: extensionName, context: context)
            }

            for candidate in candidates where context.configuration.isExcluded(candidate.path) == false {
                let size = context.fileSizeScanner.size(of: candidate)
                result.unreadablePaths.append(contentsOf: size.unreadablePaths)
                guard size.bytes > 0 else {
                    continue
                }

                var metadata: [String: String] = [
                    "root": root.standardizedFileURL.path,
                    "suggestedAction": suggestedAction(for: candidate).rawValue,
                    "state": state(for: candidate, context: context),
                ]
                metadata.merge(CodexSessionMatcher.metadata(for: candidate.path, sessions: context.codexSessions)) { current, _ in current }
                metadata.merge(
                    CodexSessionMatcher.sessionStorageMetadata(
                        for: candidate.path,
                        sessions: context.codexSessions,
                        now: context.now,
                        staleAgeDays: context.configuration.staleAgeDays))
                { _, new in new }

                let latestSessionActivityDate = CodexSessionMatcher.latestSessionActivityDate(
                    for: candidate.path,
                    sessions: context.codexSessions)
                if let latestSessionActivityDate {
                    metadata["state"] = DirectoryScannerHelpers.state(
                        ageDays: DirectoryScannerHelpers.ageDays(since: latestSessionActivityDate, now: context.now),
                        staleThreshold: context.configuration.staleAgeDays)
                }

                let item = await StorageItemFactory.makeItem(
                    url: candidate,
                    domain: domain,
                    kind: classifiedKind(for: candidate),
                    size: size,
                    metadata: metadata,
                    isActive: false,
                    explicitLastUsedAt: latestSessionActivityDate,
                    context: context)
                result.items.append(item)
            }
        }

        return result
    }

    private func suggestedAction(for url: URL) -> StorageAction {
        if domain == .codexWorkspaces {
            return .removeCodexWorkspace
        }

        let lowered = url.lastPathComponent.lowercased()
        if lowered.contains("cache") || lowered.contains("tmp") || lowered.contains("temp") || lowered.contains("log") {
            return .moveToTrash
        }
        return .none
    }

    private func classifiedKind(for url: URL) -> StorageKind {
        let lowered = url.lastPathComponent.lowercased()
        if lowered.contains("log") {
            return .codexLog
        }
        if lowered.contains("tmp") || lowered.contains("temp") || lowered.contains("cache") {
            return .codexTemp
        }
        return kind
    }

    private func state(for url: URL, context: DomainScanContext) -> String {
        let fileMetadata = FileMetadataReader.metadata(for: url)
        let ageDays = DirectoryScannerHelpers.ageDays(
            since: fileMetadata.modifiedAt,
            now: context.now)
        return DirectoryScannerHelpers.state(
            ageDays: ageDays,
            staleThreshold: context.configuration.staleCodexWorkspaceDays)
    }
}
