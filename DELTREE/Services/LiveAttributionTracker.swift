import Foundation

actor LiveAttributionTracker: AttributionTracking {
    private struct FilesystemEvent {
        var paths: [String]
        var processes: ProcessSnapshot
        var observedAt: Date
    }

    private var recentEvents: [FilesystemEvent] = []
    private let eventTTL: TimeInterval

    init(eventTTL: TimeInterval = 15 * 60) {
        self.eventTTL = eventTTL
    }

    func recordFilesystemEvents(paths: [String], processes: ProcessSnapshot, at date: Date) {
        guard paths.isEmpty == false else {
            return
        }

        recentEvents.append(FilesystemEvent(paths: paths.map { Self.standardized($0) }, processes: processes, observedAt: date))
        prune(now: date)
    }

    func attribution(
        forPath path: String,
        domain: StorageDomain,
        kind: StorageKind,
        metadata: [String: String],
        processes: ProcessSnapshot,
        now: Date) -> AttributionResult
    {
        prune(now: now)

        let standardizedPath = Self.standardized(path)
        if domain == .codexHome || domain == .codexWorkspaces || standardizedPath.contains("/.codex") {
            return AttributionResult(owner: .codex, confidence: 0.95, reason: "Path is inside Codex-owned storage.")
        }

        if metadata["codexSessionID"] != nil || metadata["codexTaskTitle"] != nil || metadata["codexWorkingDirectory"] != nil {
            if domain.isXcodeGeneratedDomain {
                return AttributionResult(owner: .xcodeViaCodex, confidence: 0.85, reason: "Path matches local Codex task/session metadata.")
            }
            return AttributionResult(owner: .codex, confidence: 0.9, reason: "Path matches local Codex task/session metadata.")
        }

        if metadata.values.contains(where: { $0.localizedCaseInsensitiveContains("codex") }) ||
            standardizedPath.localizedCaseInsensitiveContains("codex")
        {
            return AttributionResult(owner: .codex, confidence: 0.8, reason: "Path or metadata contains a Codex marker.")
        }

        if let matchedEvent = recentEvents.first(where: { event in
            event.paths.contains { eventPath in
                standardizedPath == eventPath ||
                    standardizedPath.hasPrefix(eventPath + "/") ||
                    eventPath.hasPrefix(standardizedPath + "/")
            }
        }) {
            if matchedEvent.processes.hasCodexActivity, domain.isXcodeGeneratedDomain {
                return AttributionResult(owner: .xcodeViaCodex, confidence: 0.8, reason: "Changed during active Codex and Xcode-related processes.")
            }
            if matchedEvent.processes.hasXcodeActivity {
                return AttributionResult(owner: .xcode, confidence: 0.65, reason: "Changed during active Xcode-related processes.")
            }
        }

        if processes.hasCodexActivity, processes.hasXcodeActivity, domain.isXcodeGeneratedDomain {
            return AttributionResult(owner: .xcodeViaCodex, confidence: 0.65, reason: "Scanned while Codex and Xcode-related processes were active.")
        }

        if processes.hasXcodeActivity, domain.isXcodeGeneratedDomain {
            return AttributionResult(owner: .xcode, confidence: 0.55, reason: "Scanned while Xcode-related processes were active.")
        }

        if kind == .simulatorDevice || kind == .xcTestDevice || domain.isXcodeGeneratedDomain {
            return AttributionResult(owner: .xcode, confidence: 0.35, reason: "Located in an Xcode developer storage folder.")
        }

        return AttributionResult(owner: .unknown, confidence: 0.0, reason: "No reliable owner signal was found.")
    }

    private func prune(now: Date) {
        recentEvents = recentEvents.filter { now.timeIntervalSince($0.observedAt) <= eventTTL }
    }

    nonisolated private static func standardized(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }
}
