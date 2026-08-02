import AppKit
import SwiftData
import SwiftUI

@MainActor
final class SettingsWindowController {
    private static let preferredContentSize = NSSize(width: 520, height: 420)
    private static let minimumContentSize = NSSize(width: 420, height: 360)

    private let window: NSWindow

    init(container: AppContainer) {
        let contentView = SettingsView(
            settings: container.settings,
            viewModel: container.dashboardViewModel)
            .frame(
                minWidth: Self.minimumContentSize.width,
                idealWidth: Self.preferredContentSize.width,
                minHeight: Self.minimumContentSize.height,
                idealHeight: Self.preferredContentSize.height)
            .modelContainer(container.modelContainer)

        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "DELTREE Settings"
        window.identifier = NSUserInterfaceItemIdentifier("DELTREESettingsWindow")
        window.isReleasedWhenClosed = false

        let hostingView = ResizableHostingView(rootView: contentView)
        hostingView.frame = NSRect(origin: .zero, size: Self.preferredContentSize)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
        window.contentMinSize = Self.minimumContentSize
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: Self.minimumContentSize)).size
        window.center()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
