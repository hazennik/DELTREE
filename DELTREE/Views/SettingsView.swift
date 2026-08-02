import SwiftUI

struct SettingsView: View {
    var settings: AppSettingsStore
    var viewModel: DashboardViewModel

    var body: some View {
        @Bindable var settings = settings

        Form {
            SettingsScanningSection(settings: settings)
            SettingsRulesSection(settings: settings)
            SettingsNotificationsSection(settings: settings)
            SettingsCustomRootsSection(settings: settings)
            SettingsExcludedPathsSection(settings: settings)
            SettingsRecentCleanupSection(records: viewModel.cleanupHistory)
            SettingsPrivacySection()
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: settings.changeToken) { _, _ in viewModel.settingsDidChange() }
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
    var settings: AppSettingsStore

    var body: some View {
        @Bindable var settings = settings

        Section("Custom Scan Roots") {
            TextField("One absolute path per line", text: $settings.customScanRootsText, axis: .vertical)
                .lineLimit(4...)
                .font(.system(.body, design: .monospaced))
            Text("Custom roots are treated as Codex workspace roots and are still subject to exclusions.")
                .foregroundStyle(.secondary)
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
    var records: [CleanupHistoryRecord]

    var body: some View {
        Section("Recent Cleanup") {
            if records.isEmpty {
                Text("No cleanup history yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records) { record in
                    HStack {
                        Text(record.performedAt, format: .dateTime.month().day().hour().minute())
                        Spacer()
                        Text("\(record.itemCount) item(s)")
                            .foregroundStyle(.secondary)
                        Text(StorageFormatters.byteCount(record.totalBytes))
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}

private struct SettingsPrivacySection: View {
    var body: some View {
        Section("Privacy & Attribution") {
            Text("DELTREE scans known local developer paths, reads local Codex task metadata when present, and stores scan, attribution, and cleanup history on this Mac. Cleanup always requires confirmation and uses Trash or approved simctl actions.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
