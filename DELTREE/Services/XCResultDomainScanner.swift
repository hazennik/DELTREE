import Foundation

struct XCResultDomainScanner: DomainScanning {
    var domain: StorageDomain { .xcResults }
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

            let candidates = DirectoryScannerHelpers.packageURLs(root: root, extensionName: "xcresult", context: context)
                .sorted { lhs, rhs in
                    FileMetadataReader.metadata(for: lhs).modifiedAt ?? .distantPast >
                        FileMetadataReader.metadata(for: rhs).modifiedAt ?? .distantPast
                }

            for (index, candidate) in candidates.enumerated()
                where context.configuration.isExcluded(candidate.path) == false
            {
                let size = context.fileSizeScanner.size(of: candidate)
                result.unreadablePaths.append(contentsOf: size.unreadablePaths)
                guard size.bytes > 0 else {
                    continue
                }

                var metadata: [String: String] = [
                    "root": root.standardizedFileURL.path,
                    "suggestedAction": StorageAction.removeXCResult.rawValue,
                    "relatedProject": projectName(from: candidate),
                    "attachmentsBytes": "\(attachmentBytes(in: candidate, context: context))",
                ]
                let fileMetadata = FileMetadataReader.metadata(for: candidate)
                let ageDays = DirectoryScannerHelpers.ageDays(since: fileMetadata.modifiedAt, now: context.now)
                if let ageDays {
                    metadata["ageDays"] = "\(ageDays)"
                }
                metadata["testRunRank"] = "\(index + 1)"
                if index < context.configuration.keepLastTestRuns {
                    metadata["protectedByKeepLastTestRuns"] = "true"
                    metadata["suggestedAction"] = StorageAction.none.rawValue
                }
                metadata["state"] = DirectoryScannerHelpers.state(ageDays: ageDays, staleThreshold: context.configuration.staleXCResultDays)
                metadata.merge(CodexSessionMatcher.metadata(for: candidate.path, sessions: context.codexSessions)) { current, _ in current }

                let item = await StorageItemFactory.makeItem(
                    url: candidate,
                    domain: .xcResults,
                    kind: .xcResult,
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

    private func projectName(from url: URL) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        if let separator = name.range(of: "_", options: .backwards) {
            return String(name[..<separator.lowerBound])
        }
        return name
    }

    private func attachmentBytes(in resultBundle: URL, context: DomainScanContext) -> Int64 {
        guard let enumerator = context.fileManager.enumerator(
            at: resultBundle,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true })
        else {
            return 0
        }

        var bytes: Int64 = 0
        for case let url as URL in enumerator {
            if url.path.localizedCaseInsensitiveContains("attachment") {
                bytes += context.fileSizeScanner.size(of: url).bytes
            }
        }
        return bytes
    }
}
