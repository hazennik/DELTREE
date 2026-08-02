import AppKit
import SwiftUI

@MainActor
final class DashboardWindowController {
    private static let preferredContentSize = NSSize(width: 1120, height: 720)
    private static let minimumContentSize = NSSize(width: 640, height: 440)
    private static let visibleFrameInset: CGFloat = 48

    private let window: NSWindow

    init(viewModel: DashboardViewModel) {
        let contentView = DashboardView(viewModel: viewModel)
        let minimumContentSize = Self.minimumContentSizeConstrainedToVisibleScreen()

        window = NSWindow(
            contentRect: Self.initialContentRect(),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "DELTREE"

        let hostingView = ResizableHostingView(rootView: contentView)
        hostingView.frame = NSRect(origin: .zero, size: window.contentRect(forFrameRect: window.frame).size)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
        applyWindowSizingConstraints(minimumContentSize: minimumContentSize)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        applyWindowSizingConstraints()
        fitWindowOnVisibleScreen()
        window.makeKeyAndOrderFront(nil)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            applyWindowSizingConstraints()
        }
    }

    private static func initialContentRect() -> NSRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(origin: .zero, size: preferredContentSize)
        let availableSize = availableContentSize(in: visibleFrame)
        let contentSize = NSSize(
            width: min(preferredContentSize.width, availableSize.width),
            height: min(preferredContentSize.height, availableSize.height))

        return NSRect(
            x: visibleFrame.midX - contentSize.width / 2,
            y: visibleFrame.midY - contentSize.height / 2,
            width: contentSize.width,
            height: contentSize.height)
    }

    private static func minimumContentSizeConstrainedToVisibleScreen() -> NSSize {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(origin: .zero, size: preferredContentSize)
        let availableSize = availableContentSize(in: visibleFrame)

        return NSSize(
            width: min(minimumContentSize.width, availableSize.width),
            height: min(minimumContentSize.height, availableSize.height))
    }

    private static func availableContentSize(in visibleFrame: NSRect) -> NSSize {
        NSSize(
            width: max(480, visibleFrame.width - visibleFrameInset),
            height: max(360, visibleFrame.height - visibleFrameInset))
    }

    private func applyWindowSizingConstraints(minimumContentSize suppliedMinimumContentSize: NSSize? = nil) {
        let minimumContentSize = suppliedMinimumContentSize ?? Self.minimumContentSizeConstrainedToVisibleScreen()
        window.contentMinSize = minimumContentSize
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: minimumContentSize)).size
    }

    private func fitWindowOnVisibleScreen() {
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
        guard let visibleFrame else {
            return
        }

        var frame = window.frame
        let maxWidth = max(480, visibleFrame.width - Self.visibleFrameInset)
        let maxHeight = max(360, visibleFrame.height - Self.visibleFrameInset)

        if frame.width > maxWidth {
            frame.size.width = maxWidth
        }
        if frame.height > maxHeight {
            frame.size.height = maxHeight
        }

        frame.origin.x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - frame.width)
        frame.origin.y = min(max(frame.origin.y, visibleFrame.minY), visibleFrame.maxY - frame.height)

        window.setFrame(frame, display: true)
    }
}
