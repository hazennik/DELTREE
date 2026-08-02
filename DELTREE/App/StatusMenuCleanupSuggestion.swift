import Foundation

struct StatusMenuCleanupSuggestion: Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var domain: StorageDomain
    var action: StorageAction
    var bytes: Int64
    var consequence: String

    static func make(from item: StorageItem) -> StatusMenuCleanupSuggestion {
        StatusMenuCleanupSuggestion(
            id: item.id,
            title: item.displayName,
            domain: item.domain,
            action: item.suggestedAction == .none ? .moveToTrash : item.suggestedAction,
            bytes: item.bytes,
            consequence: consequence(for: item))
    }

    private static func consequence(for item: StorageItem) -> String {
        let name = item.displayName.lowercased()

        switch item.domain {
        case .codexHome:
            if name == "sessions" {
                return "Removes past Codex session history."
            }
            if name == "archived_sessions" {
                return "Removes archived Codex session history."
            }
            if name == "cache" || name == "caches" {
                return "Removes local provider cache data."
            }
            if name == "log" || name == "logs" || name == "debug" || name.hasPrefix("logs_") {
                return "Removes local diagnostic logs."
            }
            if name == "paste-cache" || name == "image-cache" {
                return "Removes cached attachments."
            }
            if name == "tmp" || name == "temp" || name == ".tmp" || name == "shell-snapshots" || name == "shell_snapshots" {
                return "Removes local temporary provider data."
            }
            return "Removes local Codex cache or temporary data."
        case .codexWorkspaces:
            return "Removes stale Codex workspace files."
        case .coreSimulatorDevices:
            if item.suggestedAction == .deleteUnavailableSimulator {
                return "Deletes an unavailable simulator record."
            }
            return "Removes stale simulator device data."
        case .xcTestDevices:
            return "Removes stale XCTest device data."
        case .derivedData:
            return "Removes rebuildable Xcode build data."
        case .xcResults:
            return "Removes old test logs and attachments."
        case .xcodeProducts:
            return "Removes local build products and artifacts."
        case .coreSimulatorCaches:
            return "Removes generated simulator cache data."
        case .swiftPackageCaches:
            return "Removes rebuildable package cache data."
        case .archives, .deviceSupport, .simulatorRuntimes, .simulatorImages:
            return item.suggestedAction.explanation
        }
    }
}
