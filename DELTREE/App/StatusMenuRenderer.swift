import AppKit
import SwiftUI

@MainActor
enum StatusMenuRenderer {
    private static let hostedMenuWidth: CGFloat = 342

    static func render(
        descriptor: StatusMenuDescriptor,
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
                    safeItemCount: safeItemCount)))
            case let .section(title):
                menu.addItem(hostedItem(StatusMenuSectionHeaderView(title: title)))
            case let .summary(title, value, systemImage):
                menu.addItem(hostedItem(StatusMenuSummaryRowView(
                    title: title,
                    value: value,
                    systemImage: systemImage)))
            case let .breakdown(footprint):
                menu.addItem(hostedItem(StorageBreakdownMenuView(footprint: footprint)))
            case let .safety(footprint, safeItemCount):
                menu.addItem(hostedItem(StatusMenuSafetyChartView(
                    footprint: footprint,
                    safeItemCount: safeItemCount)))
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

    private static func hostedItem<Content: View>(_ content: Content) -> NSMenuItem {
        let item = NSMenuItem()
        let hostingView = NSHostingView(rootView: content.frame(width: hostedMenuWidth))
        hostingView.setFrameSize(hostingView.fittingSize)
        item.view = hostingView
        return item
    }
}
