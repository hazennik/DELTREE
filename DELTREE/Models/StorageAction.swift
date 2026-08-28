import Foundation

enum StorageAction: String, CaseIterable, Codable, Hashable, Sendable {
    case none
    case moveToTrash
    case deleteUnavailableSimulator
    case eraseSimulator
    case cleanDerivedData
    case removeXCResult
    case removeCodexWorkspace
    case revealInFinder
    case copyPath
    case exportReport
    case ignore
    case markUserOwned
    case resetAttribution

    nonisolated var displayName: String {
        switch self {
        case .none:
            "Review"
        case .moveToTrash:
            "Move to Trash"
        case .deleteUnavailableSimulator:
            "Delete Unavailable Simulator"
        case .eraseSimulator:
            "Erase Simulator Contents"
        case .cleanDerivedData:
            "Clean DerivedData"
        case .removeXCResult:
            "Remove Result Bundle"
        case .removeCodexWorkspace:
            "Remove Codex Workspace"
        case .revealInFinder:
            "Reveal in Finder"
        case .copyPath:
            "Copy Path"
        case .exportReport:
            "Export Report"
        case .ignore:
            "Ignore"
        case .markUserOwned:
            "Mark User-Owned"
        case .resetAttribution:
            "Reset Attribution"
        }
    }

    nonisolated var systemImage: String {
        switch self {
        case .none:
            "magnifyingglass"
        case .moveToTrash, .cleanDerivedData, .removeXCResult, .removeCodexWorkspace:
            "trash"
        case .deleteUnavailableSimulator:
            "iphone.slash"
        case .eraseSimulator:
            "eraser"
        case .revealInFinder:
            "folder"
        case .copyPath:
            "doc.on.doc"
        case .exportReport:
            "square.and.arrow.down"
        case .ignore:
            "eye.slash"
        case .markUserOwned:
            "person.crop.circle.badge.checkmark"
        case .resetAttribution:
            "arrow.uturn.backward"
        }
    }

    nonisolated var explanation: String {
        switch self {
        case .none:
            "Review this item before deciding whether to clean it."
        case .moveToTrash:
            "Moves the selected file or folder to the macOS Trash."
        case .deleteUnavailableSimulator:
            "Uses xcrun simctl delete for an unavailable simulator device."
        case .eraseSimulator:
            "Uses xcrun simctl erase to clear simulator contents without deleting the device."
        case .cleanDerivedData:
            "Moves a selected DerivedData folder to the macOS Trash."
        case .removeXCResult:
            "Moves an old .xcresult bundle to the macOS Trash."
        case .removeCodexWorkspace:
            "Moves a stale Codex task workspace to the macOS Trash."
        case .revealInFinder:
            "Opens the item location in Finder."
        case .copyPath:
            "Copies the absolute item path."
        case .exportReport:
            "Writes a JSON cleanup report for review or audit."
        case .ignore:
            "Keeps the item visible only when ignored items are included."
        case .markUserOwned:
            "Pins ownership to User so future scans do not attribute it to Codex or Xcode."
        case .resetAttribution:
            "Removes manual attribution and pin/ignore choices for this item."
        }
    }

    nonisolated var isCleanupExecutionAction: Bool {
        switch self {
        case .moveToTrash, .deleteUnavailableSimulator, .eraseSimulator, .cleanDerivedData, .removeXCResult, .removeCodexWorkspace:
            true
        case .none, .revealInFinder, .copyPath, .exportReport, .ignore, .markUserOwned, .resetAttribution:
            false
        }
    }

    nonisolated var isOneClickSafeCleanupAction: Bool {
        switch self {
        case .moveToTrash, .deleteUnavailableSimulator, .cleanDerivedData, .removeXCResult, .removeCodexWorkspace:
            true
        case .eraseSimulator, .none, .revealInFinder, .copyPath, .exportReport, .ignore, .markUserOwned, .resetAttribution:
            false
        }
    }

    nonisolated var usesTrash: Bool {
        switch self {
        case .moveToTrash, .cleanDerivedData, .removeXCResult, .removeCodexWorkspace:
            true
        case .none, .deleteUnavailableSimulator, .eraseSimulator, .revealInFinder, .copyPath, .exportReport, .ignore, .markUserOwned, .resetAttribution:
            false
        }
    }

    nonisolated var permanentlyRemovesSimulatorData: Bool {
        switch self {
        case .deleteUnavailableSimulator, .eraseSimulator:
            true
        case .none, .moveToTrash, .cleanDerivedData, .removeXCResult, .removeCodexWorkspace,
             .revealInFinder, .copyPath, .exportReport, .ignore, .markUserOwned, .resetAttribution:
            false
        }
    }
}
