import SwiftUI

struct SettingsView: View {
    var settings: AppSettingsStore
    var viewModel: DashboardViewModel

    var body: some View {
        @Bindable var settings = settings
        let theme = AppTheme(mode: settings.visualMode)

        Group {
            if theme.isClassic {
                ClassicSettingsContent(settings: settings, cleanupHistory: viewModel.cleanupHistory)
            } else {
                Form {
                    SettingsAppearanceSection(settings: settings)
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

            Text("Classic is the default terminal-style identity. Modern preserves the previous macOS-native visual system.")
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
    @Environment(\.appTheme) private var theme

    var settings: AppSettingsStore

    var body: some View {
        @Bindable var settings = settings

        Section("Custom Scan Roots") {
            TextField("One absolute path per line", text: $settings.customScanRootsText, axis: .vertical)
                .lineLimit(4...)
                .font(.system(.body, design: .monospaced))
            Text("Custom roots are treated as Codex workspace roots and are still subject to exclusions.")
                .foregroundStyle(theme.secondaryText)
        }
    }
}

private struct SettingsExcludedPathsSection: View {
    var settings: AppSettingsStore

    var body: some View {
        @Bindable var settings = settings

        Section("Excluded Paths") {
            TextField("One absolute path per line", text: $settings.excludedPathsText, axis: .vertical)
                .lineLimit(5...)
                .font(.system(.body, design: .monospaced))
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
                    HStack {
                        Text(record.performedAt, format: .dateTime.month().day().hour().minute())
                        Spacer()
                        Text("\(record.itemCount) item(s)")
                            .foregroundStyle(theme.secondaryText)
                        Text(StorageFormatters.byteCount(record.totalBytes))
                            .monospacedDigit()
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

                ClassicSection("Scanning") {
                    ClassicToggleButton(title: "Watch developer folders", isOn: $settings.watcherEnabled)
                    ClassicToggleButton(title: "Auto-scan after activity", isOn: $settings.autoScanAfterActivity)
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
                    Text("ONE ABSOLUTE PATH PER LINE")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                    TextField("PATH", text: $settings.customScanRootsText, axis: .vertical)
                        .lineLimit(4...)
                        .classicTextField()
                    Text("CUSTOM ROOTS ARE TREATED AS CODEX WORKSPACE ROOTS AND STILL USE EXCLUSIONS.")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                }

                ClassicSection("Excluded Paths") {
                    Text("ONE ABSOLUTE PATH PER LINE")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                    TextField("PATH", text: $settings.excludedPathsText, axis: .vertical)
                        .lineLimit(5...)
                        .classicTextField()
                }

                ClassicSection("Recent Cleanup") {
                    if cleanupHistory.isEmpty {
                        Text("NO CLEANUP HISTORY YET.")
                            .font(theme.font(.caption))
                            .foregroundStyle(theme.secondaryText)
                    } else {
                        ForEach(cleanupHistory) { record in
                            HStack {
                                Text(record.performedAt, format: .dateTime.month().day().hour().minute())
                                Spacer()
                                Text("\(record.itemCount) ITEM(S)")
                                    .foregroundStyle(theme.secondaryText)
                                Text(StorageFormatters.byteCount(record.totalBytes))
                                    .monospacedDigit()
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
                .frame(width: 90)
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
                .frame(width: 90)
        }
    }
}

private struct SettingsIntField: View {
    var title: String
    var prompt: String
    @Binding var value: Int

    var body: some View {
        LabeledContent(title) {
            TextField(prompt, value: $value, format: .number)
                .frame(width: 90)
        }
    }
}

private struct SettingsDoubleField: View {
    var title: String
    var prompt: String
    @Binding var value: Double

    var body: some View {
        LabeledContent(title) {
            TextField(prompt, value: $value, format: .number)
                .frame(width: 90)
        }
    }
}
