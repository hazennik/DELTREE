import AppKit
import SwiftUI

@MainActor
final class DashboardWindowController {
    private let window: NSWindow

    init(viewModel: DashboardViewModel) {
        let contentView = DashboardView(viewModel: viewModel)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "DELTREE"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
