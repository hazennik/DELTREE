import AppKit
import SwiftUI

struct SettingsView: View {
    var settings: AppSettingsStore
    var viewModel: DashboardViewModel
    var updateService: AppUpdateService?

    init(
        settings: AppSettingsStore,
        viewModel: DashboardViewModel,
        updateService: AppUpdateService? = nil)
    {
        self.settings = settings
        self.viewModel = viewModel
        self.updateService = updateService
    }

    var body: some View {
        @Bindable var settings = settings
        let theme = AppTheme(mode: settings.visualMode)

        Group {
            if theme.isClassic {
                ClassicSettingsContent(
                    settings: settings,
                    cleanupHistory: viewModel.cleanupHistory,
                    updateService: updateService)
            } else {
                Form {
                    SettingsAppearanceSection(settings: settings)
                    SettingsSystemSection(settings: settings)
                    if let updateService, updateService.isVisible {
                        SettingsUpdatesSection(updateService: updateService)
                    }
                    SettingsScanningSection(settings: settings)
                    SettingsRulesSection(settings: settings)
                    SettingsNotificationsSection(settings: settings)
                    SettingsCustomRootsSection(settings: settings)
                    SettingsExcludedPathsSection(settings: settings)
                    SettingsRecentCleanupSection(records: viewModel.cleanupHistory)
                    SettingsPrivacySection()
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
            }
        }
        .padding()
        .background(theme.background)
        .foregroundStyle(theme.primaryText)
        .appTheme(theme)
        .onChange(of: settings.changeToken) { _, _ in viewModel.settingsDidChange() }
    }
}

private struct SettingsSystemSection: View {
    var settings: AppSettingsStore

    var body: some View {
        @Bindable var settings = settings

        Section("System") {
            Toggle("Launch DELTREE at login", isOn: $settings.launchAtLogin)
        }
    }
}

private struct SettingsAppearanceSection: View {
    @Environment(\.appTheme) private var theme

    var settings: AppSettingsStore

    var body: some View {
        @Bindable var settings = settings

        Section("Appearance") {
            Picker("Visual Mode", selection: $settings.visualMode) {
                ForEach(AppVisualMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("Modern is the default macOS-native interface. Classic provides the terminal-style identity.")
                .foregroundStyle(theme.secondaryText)
        }
    }
}

private struct SettingsScanningSection: View {
    var settings: AppSettingsStore

    var body: some View {
        @Bindable var settings = settings

        Section("Scanning") {
            Toggle("Watch developer folders for live attribution", isOn: $settings.watcherEnabled)
            Toggle("Auto-scan after Codex/Xcode activity", isOn: $settings.autoScanAfterActivity)
            Toggle("Scan ~/Documents/Codex", isOn: $settings.scanDocumentsCodex)
            Text("Off by default. Enabling this may prompt once for Documents access during the next user-initiated scan.")
                .font(.caption)
                .foregroundStyle(.secondary)
            SettingsDoubleField(title: "Scan interval", prompt: "Minutes", value: $settings.scanIntervalMinutes)
            SettingsIntField(title: "Stale after", prompt: "Days", value: $settings.staleAgeDays)
        }
    }
}

private struct SettingsRulesSection: View {
    var settings: AppSettingsStore

    var body: some View {
        @Bindable var settings = settings

        Section("Rules") {
            Toggle("Notify only by default", isOn: $settings.notifyOnlyByDefault)
            Toggle("Never include archives in one-click cleanup", isOn: $settings.neverTouchArchives)
            SettingsIntField(title: "Keep last test runs", prompt: "Count", value: $settings.keepLastTestRuns)
            SettingsIntField(title: "Keep simulators used within", prompt: "Days", value: $settings.keepSimulatorsUsedWithinDays)
            SettingsIntField(title: "Stale XCTestDevices", prompt: "Days", value: $settings.staleXCTestDeviceDays)
            SettingsIntField(title: "Stale result bundles", prompt: "Days", value: $settings.staleXCResultDays)
            SettingsIntField(title: "Stale Codex workspaces", prompt: "Days", value: $settings.staleCodexWorkspaceDays)
            SettingsDoubleField(title: "Confirm cleanup above", prompt: "GB", value: $settings.requireConfirmationAboveGB)
        }
    }
}

private struct SettingsNotificationsSection: View {
    var settings: AppSettingsStore

    var body: some View {
        @Bindable var settings = settings

        Section("Notifications") {
            Toggle("Enable notifications", isOn: $settings.notificationsEnabled)
            SettingsDoubleField(title: "Low disk warning", prompt: "GB", value: $settings.lowDiskThresholdGB)
            SettingsDoubleField(title: "Recent growth warning", prompt: "GB", value: $settings.recentGrowthThresholdGB)
        }
    }
}

private struct SettingsCustomRootsSection: View {
    var settings: AppSettingsStore

    var body: some View {
        Section("Custom Scan Roots") {
            SettingsPathListEditor(settings: settings, kind: .customRoot)
        }
    }
}

private struct SettingsExcludedPathsSection: View {
    var settings: AppSettingsStore

    var body: some View {
        Section("Excluded Paths") {
            SettingsPathListEditor(settings: settings, kind: .exclusion)
        }
    }
}

private struct SettingsRecentCleanupSection: View {
    @Environment(\.appTheme) private var theme

    var records: [CleanupHistoryRecord]

    var body: some View {
        Section("Recent Cleanup") {
            if records.isEmpty {
                Text("No cleanup history yet.")
                    .foregroundStyle(theme.secondaryText)
            } else {
                ForEach(records) { record in
                    DisclosureGroup {
                        CleanupRecordDetailsView(record: record)
                    } label: {
                        CleanupRecordSummaryView(record: record)
                    }
                }
            }
        }
    }
}

private struct SettingsPrivacySection: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        Section("Privacy & Attribution") {
            Text("DELTREE scans known local developer paths, reads local Codex task metadata when present, and stores scan, attribution, and cleanup history on this Mac. Cleanup always requires confirmation and uses Trash or approved simctl actions.")
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ClassicSettingsContent: View {
    @Environment(\.appTheme) private var theme

    var settings: AppSettingsStore
    var cleanupHistory: [CleanupHistoryRecord]
    var updateService: AppUpdateService?

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ClassicSection("Appearance") {
                    HStack(spacing: 8) {
                        ClassicVisualModeButton(mode: .classic, selection: $settings.visualMode)
                        ClassicVisualModeButton(mode: .modern, selection: $settings.visualMode)
                    }

                    Text("CLASSIC USES A MUTED DOS TEXT-MODE INTERFACE. MODERN USES MACOS NATIVE CONTROLS.")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                }

                ClassicSection("System") {
                    ClassicToggleButton(title: "Launch DELTREE at login", isOn: $settings.launchAtLogin)
                }

                if let updateService, updateService.isVisible {
                    ClassicSection("About & Updates") {
                        SettingsUpdatesContent(updateService: updateService, isClassic: true)
                    }
                }

                ClassicSection("Scanning") {
                    ClassicToggleButton(title: "Watch developer folders", isOn: $settings.watcherEnabled)
                    ClassicToggleButton(title: "Auto-scan after activity", isOn: $settings.autoScanAfterActivity)
                    ClassicToggleButton(title: "Scan ~/Documents/Codex", isOn: $settings.scanDocumentsCodex)
                    Text("OFF BY DEFAULT. ENABLING THIS MAY PROMPT ON THE NEXT USER-INITIATED SCAN.")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                    ClassicSettingsDoubleField(title: "Scan interval", prompt: "Minutes", value: $settings.scanIntervalMinutes)
                    ClassicSettingsIntField(title: "Stale after", prompt: "Days", value: $settings.staleAgeDays)
                }

                ClassicSection("Rules") {
                    ClassicToggleButton(title: "Notify only by default", isOn: $settings.notifyOnlyByDefault)
                    ClassicToggleButton(title: "Never include archives", isOn: $settings.neverTouchArchives)
                    ClassicSettingsIntField(title: "Keep last test runs", prompt: "Count", value: $settings.keepLastTestRuns)
                    ClassicSettingsIntField(title: "Keep simulators used within", prompt: "Days", value: $settings.keepSimulatorsUsedWithinDays)
                    ClassicSettingsIntField(title: "Stale XCTestDevices", prompt: "Days", value: $settings.staleXCTestDeviceDays)
                    ClassicSettingsIntField(title: "Stale result bundles", prompt: "Days", value: $settings.staleXCResultDays)
                    ClassicSettingsIntField(title: "Stale Codex workspaces", prompt: "Days", value: $settings.staleCodexWorkspaceDays)
                    ClassicSettingsDoubleField(title: "Confirm cleanup above", prompt: "GB", value: $settings.requireConfirmationAboveGB)
                }

                ClassicSection("Notifications") {
                    ClassicToggleButton(title: "Enable notifications", isOn: $settings.notificationsEnabled)
                    ClassicSettingsDoubleField(title: "Low disk warning", prompt: "GB", value: $settings.lowDiskThresholdGB)
                    ClassicSettingsDoubleField(title: "Recent growth warning", prompt: "GB", value: $settings.recentGrowthThresholdGB)
                }

                ClassicSection("Custom Scan Roots") {
                    SettingsPathListEditor(settings: settings, kind: .customRoot, isClassic: true)
                }

                ClassicSection("Excluded Paths") {
                    SettingsPathListEditor(settings: settings, kind: .exclusion, isClassic: true)
                }

                ClassicSection("Recent Cleanup") {
                    if cleanupHistory.isEmpty {
                        Text("NO CLEANUP HISTORY YET.")
                            .font(theme.font(.caption))
                            .foregroundStyle(theme.secondaryText)
                    } else {
                        ForEach(cleanupHistory) { record in
                            DisclosureGroup {
                                CleanupRecordDetailsView(record: record, isClassic: true)
                            } label: {
                                CleanupRecordSummaryView(record: record, isClassic: true)
                            }
                        }
                    }
                }

                ClassicSection("Privacy & Attribution") {
                    Text("DELTREE SCANS KNOWN LOCAL DEVELOPER PATHS, READS LOCAL CODEX TASK METADATA WHEN PRESENT, AND STORES SCAN, ATTRIBUTION, AND CLEANUP HISTORY ON THIS MAC. CLEANUP ALWAYS REQUIRES CONFIRMATION AND USES TRASH OR APPROVED SIMCTL ACTIONS.")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SettingsUpdatesSection: View {
    var updateService: AppUpdateService

    var body: some View {
        Section("About & Updates") {
            SettingsUpdatesContent(updateService: updateService)
        }
    }
}

private struct SettingsUpdatesContent: View {
    @Environment(\.appTheme) private var theme

    var updateService: AppUpdateService
    var isClassic = false

    var body: some View {
        @Bindable var updateService = updateService

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("DELTREE")
                        .font(theme.font(.headline))
                    Text(isClassic ? versionText.uppercased() : versionText)
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                }
            }

            if isClassic {
                ClassicToggleButton(
                    title: "Automatically check for updates",
                    isOn: $updateService.automaticallyChecksForUpdates)
                ClassicToggleButton(
                    title: "Automatically download updates",
                    isOn: $updateService.automaticallyDownloadsUpdates)
                    .disabled(updateService.automaticallyChecksForUpdates == false)
            } else {
                Toggle("Automatically check for updates", isOn: $updateService.automaticallyChecksForUpdates)
                Toggle("Automatically download updates", isOn: $updateService.automaticallyDownloadsUpdates)
                    .disabled(updateService.automaticallyChecksForUpdates == false)
            }

            if isClassic {
                updateButtons
                    .buttonStyle(ClassicButtonStyle())
            } else {
                updateButtons
                    .buttonStyle(.bordered)
            }
        }
    }

    private var updateButtons: some View {
        HStack(spacing: 8) {
                if updateService.isUpdateReady {
                    Button {
                        updateService.installUpdate()
                    } label: {
                        Label(
                            isClassic ? "INSTALL UPDATE AND RELAUNCH" : "Install Update and Relaunch",
                            systemImage: "arrow.triangle.2.circlepath.circle")
                    }
                }
                Button {
                    updateService.checkForUpdates()
                } label: {
                    Label(
                        isClassic ? "CHECK FOR UPDATES" : "Check for Updates",
                        systemImage: "arrow.down.circle")
                }
                .disabled(updateService.canCheckForUpdates == false)

                Spacer()
                Link(destination: URL(string: "https://github.com/hazennik/DELTREE")!) {
                    Label(isClassic ? "PROJECT" : "Project", systemImage: "link")
                }
            }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Local"
        return "Version \(version) (\(build))"
    }
}

private struct ClassicVisualModeButton: View {
    var mode: AppVisualMode
    @Binding var selection: AppVisualMode

    var body: some View {
        Button {
            selection = mode
        } label: {
            Text("\(selection == mode ? ">" : " ") [\(mode.displayName.uppercased())]")
        }
        .buttonStyle(ClassicButtonStyle())
        .accessibilityLabel(mode.displayName)
        .accessibilityValue(selection == mode ? "Selected" : "Not selected")
    }
}

private struct ClassicSettingsIntField: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var prompt: String
    @Binding var value: Int

    var body: some View {
        HStack {
            Text(title.uppercased())
                .foregroundStyle(theme.secondaryText)
            Spacer()
            TextField(prompt.uppercased(), value: $value, format: .number)
                .classicTextField()
                .frame(width: 72)
            Text(prompt.uppercased())
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryText)
                .fixedSize()
        }
    }
}

private struct ClassicSettingsDoubleField: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var prompt: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title.uppercased())
                .foregroundStyle(theme.secondaryText)
            Spacer()
            TextField(prompt.uppercased(), value: $value, format: .number)
                .classicTextField()
                .frame(width: 72)
            Text(prompt.uppercased())
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryText)
                .fixedSize()
        }
    }
}

private struct SettingsIntField: View {
    var title: String
    var prompt: String
    @Binding var value: Int

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                TextField("", value: $value, format: .number)
                    .frame(width: 72)
                Text(prompt)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
    }
}

private struct SettingsDoubleField: View {
    var title: String
    var prompt: String
    @Binding var value: Double

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                TextField("", value: $value, format: .number)
                    .frame(width: 72)
                Text(prompt)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
    }
}

private enum SettingsPathListKind {
    case customRoot
    case exclusion

    var emptyMessage: String {
        switch self {
        case .customRoot:
            "No custom scan roots."
        case .exclusion:
            "No excluded paths."
        }
    }

    var addLabel: String {
        switch self {
        case .customRoot:
            "Add Folder"
        case .exclusion:
            "Add Path"
        }
    }

    var helpText: String {
        switch self {
        case .customRoot:
            "Custom roots are treated as Codex workspace roots and remain subject to exclusions."
        case .exclusion:
            "Excluded paths and their contents are never included in scans."
        }
    }
}

private struct SettingsPathListEditor: View {
    @Environment(\.appTheme) private var theme
    @State private var errorMessage: String?

    var settings: AppSettingsStore
    var kind: SettingsPathListKind
    var isClassic = false

    private var paths: [String] {
        switch kind {
        case .customRoot:
            settings.customScanRoots
        case .exclusion:
            settings.excludedPaths
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if paths.isEmpty {
                Text(isClassic ? kind.emptyMessage.uppercased() : kind.emptyMessage)
                    .foregroundStyle(theme.secondaryText)
            } else {
                ForEach(paths, id: \.self) { path in
                    HStack(spacing: 8) {
                        Image(systemName: kind == .customRoot ? "folder" : "nosign")
                            .foregroundStyle(theme.secondaryText)
                        Text(path)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(2)
                            .textSelection(.enabled)
                        Spacer(minLength: 8)
                        Button {
                            remove(path)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Remove \(path)")
                        .accessibilityLabel("Remove \(path)")
                    }
                }
            }

            if isClassic {
                addButton
                    .buttonStyle(ClassicButtonStyle())
            } else {
                addButton
                    .buttonStyle(.bordered)
            }

            Text(isClassic ? kind.helpText.uppercased() : kind.helpText)
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .alert("Path Not Added", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if $0 == false { errorMessage = nil } }))
        {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The selected path is not allowed.")
        }
    }

    private var addButton: some View {
        Button {
            choosePath()
        } label: {
            Label(isClassic ? kind.addLabel.uppercased() : kind.addLabel, systemImage: "folder.badge.plus")
        }
    }

    private func choosePath() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = kind == .exclusion
        panel.canCreateDirectories = false
        panel.prompt = "Add"
        guard panel.runModal() == .OK else {
            return
        }

        for url in panel.urls {
            do {
                switch kind {
                case .customRoot:
                    try settings.addCustomScanRoot(url)
                case .exclusion:
                    try settings.addExcludedPath(url)
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }
    }

    private func remove(_ path: String) {
        switch kind {
        case .customRoot:
            settings.removeCustomScanRoot(path)
        case .exclusion:
            settings.removeExcludedPath(path)
        }
    }
}
