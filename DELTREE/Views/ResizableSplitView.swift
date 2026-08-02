import AppKit
import SwiftUI

struct ResizableSplitView<Leading: View, Trailing: View>: NSViewRepresentable {
    var leadingMinWidth: CGFloat
    var leadingIdealWidth: CGFloat
    var trailingMinWidth: CGFloat
    var leading: Leading
    var trailing: Trailing

    init(
        leadingMinWidth: CGFloat,
        leadingIdealWidth: CGFloat,
        trailingMinWidth: CGFloat,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing)
    {
        self.leadingMinWidth = leadingMinWidth
        self.leadingIdealWidth = leadingIdealWidth
        self.trailingMinWidth = trailingMinWidth
        self.leading = leading()
        self.trailing = trailing()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            leadingMinWidth: leadingMinWidth,
            leadingIdealWidth: leadingIdealWidth,
            trailingMinWidth: trailingMinWidth)
    }

    func makeNSView(context: Context) -> NSSplitView {
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autoresizesSubviews = true
        splitView.delegate = context.coordinator

        let leadingHost = ResizableHostingView(rootView: leading)
        let trailingHost = ResizableHostingView(rootView: trailing)
        splitView.addArrangedSubview(leadingHost)
        splitView.addArrangedSubview(trailingHost)

        context.coordinator.leadingHostingView = leadingHost
        context.coordinator.trailingHostingView = trailingHost
        scheduleInitialPosition(in: splitView, coordinator: context.coordinator)

        return splitView
    }

    func updateNSView(_ splitView: NSSplitView, context: Context) {
        context.coordinator.leadingMinWidth = leadingMinWidth
        context.coordinator.leadingIdealWidth = leadingIdealWidth
        context.coordinator.trailingMinWidth = trailingMinWidth
        context.coordinator.leadingHostingView?.rootView = leading
        context.coordinator.trailingHostingView?.rootView = trailing
        scheduleInitialPosition(in: splitView, coordinator: context.coordinator)
    }

    private func scheduleInitialPosition(in splitView: NSSplitView, coordinator: Coordinator) {
        DispatchQueue.main.async { [weak splitView] in
            guard let splitView else {
                return
            }
            coordinator.applyInitialPositionIfNeeded(in: splitView)
        }
    }

    final class Coordinator: NSObject, NSSplitViewDelegate {
        var leadingMinWidth: CGFloat
        var leadingIdealWidth: CGFloat
        var trailingMinWidth: CGFloat
        var didApplyInitialPosition = false
        weak var leadingHostingView: ResizableHostingView<Leading>?
        weak var trailingHostingView: ResizableHostingView<Trailing>?

        init(leadingMinWidth: CGFloat, leadingIdealWidth: CGFloat, trailingMinWidth: CGFloat) {
            self.leadingMinWidth = leadingMinWidth
            self.leadingIdealWidth = leadingIdealWidth
            self.trailingMinWidth = trailingMinWidth
        }

        func applyInitialPositionIfNeeded(in splitView: NSSplitView) {
            guard didApplyInitialPosition == false, splitView.bounds.width > 0 else {
                return
            }

            let maxLeadingWidth = max(leadingMinWidth, splitView.bounds.width - trailingMinWidth)
            let dividerPosition = min(max(leadingIdealWidth, leadingMinWidth), maxLeadingWidth)
            didApplyInitialPosition = true
            splitView.setPosition(dividerPosition, ofDividerAt: 0)
        }

        func splitViewDidResizeSubviews(_ notification: Notification) {
            guard let splitView = notification.object as? NSSplitView else {
                return
            }
            applyInitialPositionIfNeeded(in: splitView)
        }

        func splitView(
            _ splitView: NSSplitView,
            constrainMinCoordinate proposedMinimumPosition: CGFloat,
            ofSubviewAt dividerIndex: Int) -> CGFloat
        {
            leadingMinWidth
        }

        func splitView(
            _ splitView: NSSplitView,
            constrainMaxCoordinate proposedMaximumPosition: CGFloat,
            ofSubviewAt dividerIndex: Int) -> CGFloat
        {
            max(leadingMinWidth, splitView.bounds.width - trailingMinWidth)
        }
    }
}
