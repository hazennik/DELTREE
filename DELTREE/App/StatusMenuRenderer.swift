import AppKit
import SwiftUI

@MainActor
enum StatusMenuRenderer {
    static func render(
        descriptor: StatusMenuDescriptor,
        into menu: NSMenu,
        target: AnyObject,
        actionSelector: Selector)
    {
        menu.removeAllItems()

        for item in descriptor.items {
            switch item {
            case let .summary(title, value, systemImage):
                menu.addItem(summaryItem(title: title, value: value, systemImage: systemImage))
            case let .breakdown(footprint):
                let menuItem = NSMenuItem()
                menuItem.view = NSHostingView(rootView: StorageBreakdownMenuView(footprint: footprint))
                menu.addItem(menuItem)
            case .separator:
                menu.addItem(.separator())
            case let .command(title, command, keyEquivalent, isEnabled):
                let item = NSMenuItem(title: title, action: actionSelector, keyEquivalent: keyEquivalent)
                item.target = target
                item.representedObject = command.rawValue
                item.isEnabled = isEnabled
                menu.addItem(item)
            }
        }
    }

    private static func summaryItem(title: String, value: String, systemImage: String?) -> NSMenuItem {
        let item = NSMenuItem(title: "\(title): \(value)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        if let systemImage {
            item.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
        }
        return item
    }
}
