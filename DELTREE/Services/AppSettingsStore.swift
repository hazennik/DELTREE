import Foundation
import Observation

@MainActor
@Observable
final class AppSettingsStore {
    private enum Key {
        static let watcherEnabled = "watcherEnabled"
        static let scanIntervalMinutes = "scanIntervalMinutes"
        static let staleAgeDays = "staleAgeDays"
        static let staleXCTestDeviceDays = "staleXCTestDeviceDays"
        static let staleXCResultDays = "staleXCResultDays"
        static let staleCodexWorkspaceDays = "staleCodexWorkspaceDays"
        static let keepLastTestRuns = "keepLastTestRuns"
        static let keepSimulatorsUsedWithinDays = "keepSimulatorsUsedWithinDays"
        static let neverTouchArchives = "neverTouchArchives"
        static let notifyOnlyByDefault = "notifyOnlyByDefault"
        static let autoScanAfterActivity = "autoScanAfterActivity"
        static let notificationsEnabled = "notificationsEnabled"
        static let lowDiskThresholdGB = "lowDiskThresholdGB"
        static let recentGrowthThresholdGB = "recentGrowthThresholdGB"
        static let requireConfirmationAboveGB = "requireConfirmationAboveGB"
        static let excludedPathsText = "excludedPathsText"
        static let customScanRootsText = "customScanRootsText"
        static let visualMode = "visualMode"
    }

    private let defaults: UserDefaults

    @ObservationIgnored var onAppearanceChange: (() -> Void)?

    var watcherEnabled: Bool {
        didSet { defaults.set(watcherEnabled, forKey: Key.watcherEnabled) }
    }

    var scanIntervalMinutes: Double {
        didSet { defaults.set(scanIntervalMinutes, forKey: Key.scanIntervalMinutes) }
    }

    var staleAgeDays: Int {
        didSet { defaults.set(staleAgeDays, forKey: Key.staleAgeDays) }
    }

    var staleXCTestDeviceDays: Int {
        didSet { defaults.set(staleXCTestDeviceDays, forKey: Key.staleXCTestDeviceDays) }
    }

    var staleXCResultDays: Int {
        didSet { defaults.set(staleXCResultDays, forKey: Key.staleXCResultDays) }
    }

    var staleCodexWorkspaceDays: Int {
        didSet { defaults.set(staleCodexWorkspaceDays, forKey: Key.staleCodexWorkspaceDays) }
    }

    var keepLastTestRuns: Int {
        didSet { defaults.set(keepLastTestRuns, forKey: Key.keepLastTestRuns) }
    }

    var keepSimulatorsUsedWithinDays: Int {
        didSet { defaults.set(keepSimulatorsUsedWithinDays, forKey: Key.keepSimulatorsUsedWithinDays) }
    }

    var neverTouchArchives: Bool {
        didSet { defaults.set(neverTouchArchives, forKey: Key.neverTouchArchives) }
    }

    var notifyOnlyByDefault: Bool {
        didSet { defaults.set(notifyOnlyByDefault, forKey: Key.notifyOnlyByDefault) }
    }

    var autoScanAfterActivity: Bool {
        didSet { defaults.set(autoScanAfterActivity, forKey: Key.autoScanAfterActivity) }
    }

    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled) }
    }

    var lowDiskThresholdGB: Double {
        didSet { defaults.set(lowDiskThresholdGB, forKey: Key.lowDiskThresholdGB) }
    }

    var recentGrowthThresholdGB: Double {
        didSet { defaults.set(recentGrowthThresholdGB, forKey: Key.recentGrowthThresholdGB) }
    }

    var requireConfirmationAboveGB: Double {
        didSet { defaults.set(requireConfirmationAboveGB, forKey: Key.requireConfirmationAboveGB) }
    }

    var excludedPathsText: String {
        didSet { defaults.set(excludedPathsText, forKey: Key.excludedPathsText) }
    }

    var customScanRootsText: String {
        didSet { defaults.set(customScanRootsText, forKey: Key.customScanRootsText) }
    }

    var visualMode: AppVisualMode {
        didSet {
            defaults.set(visualMode.rawValue, forKey: Key.visualMode)
            if oldValue != visualMode {
                onAppearanceChange?()
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        watcherEnabled = defaults.object(forKey: Key.watcherEnabled) as? Bool ?? true
        scanIntervalMinutes = defaults.object(forKey: Key.scanIntervalMinutes) as? Double ?? 5
        staleAgeDays = defaults.object(forKey: Key.staleAgeDays) as? Int ?? 14
        staleXCTestDeviceDays = defaults.object(forKey: Key.staleXCTestDeviceDays) as? Int ?? 14
        staleXCResultDays = defaults.object(forKey: Key.staleXCResultDays) as? Int ?? 14
        staleCodexWorkspaceDays = defaults.object(forKey: Key.staleCodexWorkspaceDays) as? Int ?? 7
        keepLastTestRuns = defaults.object(forKey: Key.keepLastTestRuns) as? Int ?? 5
        keepSimulatorsUsedWithinDays = defaults.object(forKey: Key.keepSimulatorsUsedWithinDays) as? Int ?? 14
        neverTouchArchives = defaults.object(forKey: Key.neverTouchArchives) as? Bool ?? true
        notifyOnlyByDefault = defaults.object(forKey: Key.notifyOnlyByDefault) as? Bool ?? true
        autoScanAfterActivity = defaults.object(forKey: Key.autoScanAfterActivity) as? Bool ?? true
        notificationsEnabled = defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? false
        lowDiskThresholdGB = defaults.object(forKey: Key.lowDiskThresholdGB) as? Double ?? 20
        recentGrowthThresholdGB = defaults.object(forKey: Key.recentGrowthThresholdGB) as? Double ?? 1
        requireConfirmationAboveGB = defaults.object(forKey: Key.requireConfirmationAboveGB) as? Double ?? 1
        excludedPathsText = defaults.string(forKey: Key.excludedPathsText) ?? ""
        customScanRootsText = defaults.string(forKey: Key.customScanRootsText) ?? ""
        visualMode = AppVisualMode(rawValue: defaults.string(forKey: Key.visualMode) ?? "") ?? .classic
    }

    var scanConfiguration: StorageScanConfiguration {
        StorageScanConfiguration(
            staleAgeDays: max(1, staleAgeDays),
            staleXCTestDeviceDays: max(1, staleXCTestDeviceDays),
            staleXCResultDays: max(1, staleXCResultDays),
            staleCodexWorkspaceDays: max(1, staleCodexWorkspaceDays),
            keepLastTestRuns: max(0, keepLastTestRuns),
            keepSimulatorsUsedWithinDays: max(1, keepSimulatorsUsedWithinDays),
            neverTouchArchives: neverTouchArchives,
            excludedPaths: Set(excludedPathsText
                .split(whereSeparator: \.isNewline)
                .map { URL(fileURLWithPath: String($0)).standardizedFileURL.path }),
            customScanRoots: customScanRootsText
                .split(whereSeparator: \.isNewline)
                .map { URL(fileURLWithPath: String($0)).standardizedFileURL.path },
            manualOverrides: [:])
    }

    var lowDiskThresholdBytes: Int64 {
        Int64(max(0, lowDiskThresholdGB) * 1_000_000_000)
    }

    var recentGrowthThresholdBytes: Int64 {
        Int64(max(0, recentGrowthThresholdGB) * 1_000_000_000)
    }

    var requireConfirmationAboveBytes: Int64 {
        Int64(max(0, requireConfirmationAboveGB) * 1_000_000_000)
    }

    var changeToken: String {
        [
            watcherEnabled.description,
            autoScanAfterActivity.description,
            scanIntervalMinutes.description,
            staleAgeDays.description,
            staleXCTestDeviceDays.description,
            staleXCResultDays.description,
            staleCodexWorkspaceDays.description,
            keepLastTestRuns.description,
            keepSimulatorsUsedWithinDays.description,
            neverTouchArchives.description,
            notifyOnlyByDefault.description,
            notificationsEnabled.description,
            lowDiskThresholdGB.description,
            recentGrowthThresholdGB.description,
            requireConfirmationAboveGB.description,
            excludedPathsText,
            customScanRootsText
        ].joined(separator: "|")
    }
}
