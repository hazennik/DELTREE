import AppKit
import SwiftUI

@MainActor
enum ScreenshotExportService {
    static func export(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let modernSettingsViewModel = previewViewModel(mode: .modern)
        try write(
            DashboardView(viewModel: previewViewModel(mode: .modern))
                .frame(width: 1280, height: 820),
            size: CGSize(width: 1280, height: 820),
            to: directory.appendingPathComponent("modern-dashboard.png"))

        try write(
            StatusMenuScreenshotView(mode: .modern),
            size: CGSize(width: 720, height: 920),
            to: directory.appendingPathComponent("modern-menu-bar-dropdown.png"))

        try write(
            CleanupPreflightView(
                plan: previewCleanupPlan(),
                confirmationThresholdBytes: 1_000_000_000,
                confirmAction: {},
                cancelAction: {},
                exportAction: {})
                .appTheme(AppTheme(mode: .modern))
                .frame(width: 820, height: 560),
            size: CGSize(width: 820, height: 560),
            to: directory.appendingPathComponent("modern-cleanup-preflight.png"))

        try write(
            SettingsView(
                settings: modernSettingsViewModel.settings,
                viewModel: modernSettingsViewModel)
                .frame(width: 680, height: 620),
            size: CGSize(width: 680, height: 620),
            to: directory.appendingPathComponent("modern-settings.png"))

        try write(
            DashboardView(viewModel: previewViewModel(mode: .classic))
                .frame(width: 1500, height: 900),
            size: CGSize(width: 1500, height: 900),
            to: directory.appendingPathComponent("classic-dashboard.png"))

        try write(
            StatusMenuScreenshotView(mode: .classic),
            size: CGSize(width: 620, height: 900),
            to: directory.appendingPathComponent("classic-menu-bar-dropdown.png"))

        try write(
            PermissionPromptGuideView(),
            size: CGSize(width: 900, height: 560),
            to: directory.appendingPathComponent("permissions-file-access-guide.png"))

        try write(
            SocialPreviewScreenshotView(),
            size: CGSize(width: 1200, height: 630),
            to: directory.appendingPathComponent("social-preview.png"))
    }

    fileprivate static func previewViewModel(mode: AppVisualMode) -> DashboardViewModel {
        let viewModel = DashboardViewModel.preview
        viewModel.settings.visualMode = mode
        viewModel.settings.notifyOnlyByDefault = false
        viewModel.availableDiskBytes = 68_000_000_000
        viewModel.previousSnapshot = previousSnapshot(from: viewModel.snapshot)
        viewModel.lastDelta = StorageDelta.make(previous: viewModel.previousSnapshot, current: viewModel.snapshot)
        viewModel.selectedItemID = viewModel.snapshot.items.first?.id
        return viewModel
    }

    private static func previousSnapshot(from snapshot: StorageSnapshot) -> StorageSnapshot {
        var previous = snapshot
        previous.capturedAt = snapshot.capturedAt.addingTimeInterval(-86_400)
        previous.items = snapshot.items.map { item in
            var item = item
            item.bytes = Int64(Double(item.bytes) * 0.82)
            return item
        }
        return previous
    }

    private static func previewCleanupPlan() -> CleanupPlan {
        let snapshot = previewViewModel(mode: .modern).snapshot
        let actions = snapshot.items
            .filter(\.isCleanupEligible)
            .prefix(5)
            .map { item in
                CleanupPlanAction(
                    item: item,
                    action: item.suggestedAction == .none ? .moveToTrash : item.suggestedAction,
                    reason: item.cleanupImpact.isEmpty ? item.safety.displayName : item.cleanupImpact)
            }
        let blocked = snapshot.items.filter { $0.safety == .keep || $0.isActive }
        return CleanupPlan(actions: Array(actions), blockedItems: blocked)
    }

    fileprivate static func previewStatusMenuDescriptor(mode: AppVisualMode) -> StatusMenuDescriptor {
        let viewModel = previewViewModel(mode: mode)
        let safeItems = viewModel.snapshot.items.filter(\.isCleanupEligible)
        let reviewItems = viewModel.snapshot.items.filter { item in
            item.isIgnored == false &&
                (item.safety == .probablySafe || item.safety == .reviewRecommended)
        }
        let footprint = viewModel.footprint
        return StatusMenuDescriptor(title: viewModel.menuBarTitle, isWarning: false, items: [
            .overview(
                footprint: footprint,
                lastCodexImpactBytes: viewModel.lastDelta.codexImpactBytes,
                hasRecentGrowth: true,
                isScanning: false,
                safeItemCount: safeItems.count),
            .separator,
            .section(title: "Storage Sources"),
            .sources(footprint),
            .separator,
            .section(title: "Cleanup Readiness"),
            .safety(footprint: footprint, safeItemCount: safeItems.count),
            .reviewItems(
                items: reviewItems.map(StatusMenuReviewItem.make),
                totalBytes: reviewItems.reduce(0) { $0 + max(0, $1.bytes) }),
            .separator,
            .section(title: "Suggested Cleanup"),
            .cleanupSuggestions(
                suggestions: Array(safeItems.prefix(3).map(StatusMenuCleanupSuggestion.make)),
                totalCount: safeItems.count,
                totalBytes: footprint.reclaimableBytes),
            .separator,
            .section(title: "Actions"),
            .command(title: "Open Dashboard", command: .openDashboard, keyEquivalent: "", isEnabled: true),
            .command(title: "Scan Now", command: .scanNow, keyEquivalent: "r", isEnabled: true),
            .command(title: "Clean Safe Items...", command: .cleanSafe, keyEquivalent: "", isEnabled: true),
            .separator,
            .command(title: "Settings...", command: .openSettings, keyEquivalent: ",", isEnabled: true),
            .command(title: "Quit DELTREE", command: .quit, keyEquivalent: "q", isEnabled: true),
        ])
    }

    private static func write<Content: View>(_ content: Content, size: CGSize, to url: URL) throws {
        let hostingView = NSHostingView(rootView: content.frame(width: size.width, height: size.height))
        hostingView.frame = CGRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        window.contentView = hostingView
        window.displayIfNeeded()
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * 2),
            pixelsHigh: Int(size.height * 2),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0)
        else {
            throw ScreenshotExportError.renderFailed(url.lastPathComponent)
        }
        bitmap.size = size
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotExportError.encodeFailed(url.lastPathComponent)
        }
        try data.write(to: url, options: .atomic)
    }
}

private enum ScreenshotExportError: LocalizedError {
    case renderFailed(String)
    case encodeFailed(String)

    var errorDescription: String? {
        switch self {
        case let .renderFailed(name):
            "Could not render \(name)."
        case let .encodeFailed(name):
            "Could not encode \(name)."
        }
    }
}

private struct StatusMenuScreenshotView: View {
    var mode: AppVisualMode

    var body: some View {
        let theme = AppTheme(mode: mode)
        ZStack(alignment: .topTrailing) {
            theme.background

            VStack(spacing: 0) {
                MenuBarStrip(mode: mode)
                Spacer(minLength: 0)
            }

            StatusMenuPanel(
                descriptor: ScreenshotExportService.previewStatusMenuDescriptor(mode: mode),
                mode: mode)
                .padding(.top, 46)
                .padding(.trailing, 34)
        }
        .appTheme(theme)
    }
}

private struct MenuBarStrip: View {
    var mode: AppVisualMode

    var body: some View {
        let theme = AppTheme(mode: mode)
        HStack(spacing: 14) {
            Text("DELTREE")
                .font(.system(size: 13, weight: .semibold, design: theme.isClassic ? .monospaced : .default))
            Spacer()
            Text("Wed Aug 5  7:52 PM")
                .font(.system(size: 12, design: theme.isClassic ? .monospaced : .default))
            HStack(spacing: 6) {
                Image(systemName: "externaldrive.fill")
                Text("13.5 GB")
                    .monospacedDigit()
            }
            .font(.system(size: 12, weight: .medium, design: theme.isClassic ? .monospaced : .default))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(theme.isClassic ? theme.controlFill : theme.panelFill, in: Capsule())
        }
        .foregroundStyle(theme.primaryText)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .background(theme.isClassic ? theme.panelFill : Color(nsColor: .windowBackgroundColor))
        .overlay(Rectangle().fill(theme.separator).frame(height: 1), alignment: .bottom)
    }
}

private struct StatusMenuPanel: View {
    @Environment(\.appTheme) private var theme

    var descriptor: StatusMenuDescriptor
    var mode: AppVisualMode

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(descriptor.items.enumerated()), id: \.offset) { _, item in
                row(for: item)
            }
        }
        .frame(width: theme.isClassic ? 360 : 382)
        .padding(.vertical, theme.isClassic ? 0 : 7)
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: theme.isClassic ? 0 : 8))
        .overlay {
            RoundedRectangle(cornerRadius: theme.isClassic ? 0 : 8)
                .stroke(theme.panelBorder, lineWidth: 1)
        }
        .shadow(color: .black.opacity(theme.isClassic ? 0 : 0.18), radius: 22, x: 0, y: 14)
    }

    @ViewBuilder
    private func row(for item: StatusMenuItemDescriptor) -> some View {
        switch item {
        case let .overview(footprint, lastCodexImpactBytes, hasRecentGrowth, isScanning, safeItemCount):
            StatusMenuOverviewView(
                footprint: footprint,
                lastCodexImpactBytes: lastCodexImpactBytes,
                hasRecentGrowth: hasRecentGrowth,
                isScanning: isScanning,
                safeItemCount: safeItemCount)
                .frame(width: theme.isClassic ? 342 : 358)
        case let .section(title):
            StatusMenuSectionHeaderView(title: title)
                .frame(width: theme.isClassic ? 342 : 358)
        case let .summary(title, value, systemImage):
            StatusMenuSummaryRowView(title: title, value: value, systemImage: systemImage)
                .frame(width: theme.isClassic ? 342 : 358)
        case let .sources(footprint):
            StatusMenuSourceBreakdownView(footprint: footprint)
                .frame(width: theme.isClassic ? 342 : 358)
        case let .breakdown(footprint):
            StorageBreakdownMenuView(footprint: footprint)
                .frame(width: theme.isClassic ? 342 : 358)
        case let .cleanupSuggestions(suggestions, totalCount, totalBytes):
            StatusMenuSuggestedCleanupView(
                suggestions: suggestions,
                totalCount: totalCount,
                totalBytes: totalBytes)
                .frame(width: theme.isClassic ? 342 : 358)
        case let .safety(footprint, safeItemCount):
            StatusMenuSafetyChartView(footprint: footprint, safeItemCount: safeItemCount)
                .frame(width: theme.isClassic ? 342 : 358)
        case let .reviewItems(items, totalBytes):
            StatusMenuSummaryRowView(
                title: "Review Items (\(items.count))",
                value: StorageFormatters.byteCount(totalBytes),
                systemImage: "exclamationmark.triangle")
                .frame(width: theme.isClassic ? 342 : 358)
        case .separator:
            if theme.isClassic {
                StatusMenuDividerView()
                    .frame(width: 342)
            } else {
                Rectangle()
                    .fill(theme.separator)
                    .frame(height: 1)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
            }
        case let .command(title, command, keyEquivalent, isEnabled):
            if theme.isClassic {
                StatusMenuCommandRowView(
                    title: title,
                    systemImage: command.systemImage,
                    keyEquivalent: keyEquivalent,
                    isEnabled: isEnabled,
                    action: {})
                    .frame(width: 342)
            } else {
                ModernMenuCommandRow(
                    title: title,
                    systemImage: command.systemImage,
                    keyEquivalent: keyEquivalent,
                    isEnabled: isEnabled)
                    .frame(width: 358)
            }
        }
    }
}

private struct ModernMenuCommandRow: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var systemImage: String
    var keyEquivalent: String
    var isEnabled: Bool

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .frame(width: 18)
                .foregroundStyle(isEnabled ? theme.secondaryText : theme.mutedText)
            Text(title)
                .foregroundStyle(isEnabled ? theme.primaryText : theme.mutedText)
            Spacer()
            if keyEquivalent.isEmpty == false {
                Text("⌘\(keyEquivalent.uppercased())")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .font(theme.font(.body))
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }
}

private struct PermissionPromptGuideView: View {
    var body: some View {
        let theme = AppTheme(mode: .modern)
        ZStack {
            theme.background
            HStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("macOS File Access")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    Text("DELTREE scans local developer folders only. If macOS asks for access, grant the prompt, rerun the scan, and keep raw paths out of public issues.")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 10) {
                        GuideCheckmark(text: "Grant access for known developer folders")
                        GuideCheckmark(text: "Use Trash for file and folder cleanup")
                        GuideCheckmark(text: "Share redacted diagnostics only")
                    }
                }
                .frame(width: 390, alignment: .leading)

                VStack(spacing: 14) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(theme.accent)
                    Text("\"DELTREE\" would like to access files in your developer folders.")
                        .font(.system(size: 18, weight: .semibold))
                        .multilineTextAlignment(.center)
                    Text("Allow access to continue scanning Xcode and Codex storage.")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                    HStack {
                        Text("Don't Allow")
                            .frame(width: 112, height: 32)
                            .background(theme.panelFill, in: RoundedRectangle(cornerRadius: 6))
                        Text("OK")
                            .frame(width: 112, height: 32)
                            .background(theme.accent, in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(.white)
                    }
                    .font(.system(size: 13, weight: .medium))
                }
                .padding(28)
                .frame(width: 360)
                .background(theme.panelFill, in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.panelBorder, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.14), radius: 24, x: 0, y: 14)
            }
            .padding(42)
        }
        .appTheme(theme)
    }
}

private struct GuideCheckmark: View {
    var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme(mode: .modern).safe)
            Text(text)
                .font(.system(size: 15, weight: .medium))
        }
    }
}

private struct SocialPreviewScreenshotView: View {
    var body: some View {
        let theme = AppTheme(mode: .modern)
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            HStack(spacing: 34) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("DELTREE")
                        .font(.system(size: 64, weight: .heavy, design: .rounded))
                    Text("Safe Codex + Xcode storage cleanup for macOS.")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        SocialBadge(text: "Local only")
                        SocialBadge(text: "Trash first")
                        SocialBadge(text: "No telemetry")
                    }
                }
                .frame(width: 410, alignment: .leading)

                DashboardView(viewModel: ScreenshotExportService.previewViewModel(mode: .modern))
                    .frame(width: 650, height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.panelBorder, lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 14)
            }
            .padding(46)
        }
        .appTheme(theme)
    }
}

private struct SocialBadge: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(AppTheme(mode: .modern).panelFill, in: Capsule())
            .overlay {
                Capsule().stroke(AppTheme(mode: .modern).panelBorder, lineWidth: 1)
            }
    }
}
