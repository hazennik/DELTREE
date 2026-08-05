import AppKit
import SwiftUI

@MainActor
enum StatusMenuRenderer {
    private static let hostedMenuWidth: CGFloat = 342

    static func render(
        descriptor: StatusMenuDescriptor,
        visualMode: AppVisualMode,
        into menu: NSMenu,
        target: AnyObject,
        actionSelector: Selector)
    {
        menu.removeAllItems()

        for item in descriptor.items {
            switch item {
            case let .overview(footprint, lastCodexImpactBytes, hasRecentGrowth, isScanning, safeItemCount):
                menu.addItem(hostedItem(StatusMenuOverviewView(
                    footprint: footprint,
                    lastCodexImpactBytes: lastCodexImpactBytes,
                    hasRecentGrowth: hasRecentGrowth,
                    isScanning: isScanning,
                    safeItemCount: safeItemCount), visualMode: visualMode))
            case let .section(title):
                menu.addItem(hostedItem(StatusMenuSectionHeaderView(title: title), visualMode: visualMode))
            case let .summary(title, value, systemImage):
                menu.addItem(hostedItem(StatusMenuSummaryRowView(
                    title: title,
                    value: value,
                    systemImage: systemImage), visualMode: visualMode))
            case let .sources(footprint):
                menu.addItem(hostedItem(StatusMenuSourceBreakdownView(footprint: footprint), visualMode: visualMode))
            case let .breakdown(footprint):
                menu.addItem(hostedItem(StorageBreakdownMenuView(footprint: footprint), visualMode: visualMode))
            case let .cleanupSuggestions(suggestions, totalCount, totalBytes):
                menu.addItem(hostedItem(StatusMenuSuggestedCleanupView(
                    suggestions: suggestions,
                    totalCount: totalCount,
                    totalBytes: totalBytes), visualMode: visualMode))
            case let .safety(footprint, safeItemCount):
                menu.addItem(hostedItem(StatusMenuSafetyChartView(
                    footprint: footprint,
                    safeItemCount: safeItemCount), visualMode: visualMode))
            case .separator:
                menu.addItem(.separator())
            case let .command(title, command, keyEquivalent, isEnabled):
                let item = NSMenuItem(title: title, action: actionSelector, keyEquivalent: keyEquivalent)
                item.target = target
                item.representedObject = command.rawValue
                item.isEnabled = isEnabled
                item.image = NSImage(systemSymbolName: command.systemImage, accessibilityDescription: title)
                menu.addItem(item)
            }
        }
    }

    private static func hostedItem<Content: View>(_ content: Content, visualMode: AppVisualMode) -> NSMenuItem {
        let item = NSMenuItem()
        let hostingView = NSHostingView(rootView: content
            .frame(width: hostedMenuWidth)
            .appTheme(AppTheme(mode: visualMode)))
        hostingView.setFrameSize(hostingView.fittingSize)
        item.view = hostingView
        return item
    }
}
