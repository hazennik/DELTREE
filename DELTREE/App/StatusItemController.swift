import AppKit

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let viewModel: DashboardViewModel
    private let openDashboard: () -> Void
    private let openSettings: () -> Void
    private var lastIconState: StatusItemIconState?

    init(viewModel: DashboardViewModel, openDashboard: @escaping () -> Void, openSettings: @escaping () -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.viewModel = viewModel
        self.openDashboard = openDashboard
        self.openSettings = openSettings
        super.init()

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleNone
        statusItem.button?.title = ""
        viewModel.onStateChange = { [weak self] in
            self?.updateStatusItem()
        }
        updateStatusItem()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuild(menu)
    }

    private func updateStatusItem() {
        let descriptor = descriptor()
        let iconState = StatusItemIconState.make(
            footprint: viewModel.footprint,
            lastDelta: viewModel.lastDelta,
            isScanning: viewModel.isScanning)

        if iconState != lastIconState {
            statusItem.button?.image = StatusItemIconRenderer.image(for: iconState)
            lastIconState = iconState
        }

        statusItem.button?.title = ""
        statusItem.button?.contentTintColor = nil
        statusItem.button?.toolTip = descriptor.title
        statusItem.button?.setAccessibilityTitle(iconState.accessibilityDescription)
    }

    private func rebuild(_ menu: NSMenu) {
        updateStatusItem()
        StatusMenuRenderer.render(
            descriptor: descriptor(),
            into: menu,
            target: self,
            actionSelector: #selector(performMenuCommand(_:)))
    }

    private func descriptor() -> StatusMenuDescriptor {
        StatusMenuDescriptorBuilder.make(
            title: viewModel.menuBarTitle,
            footprint: viewModel.footprint,
            lastDelta: viewModel.lastDelta,
            isScanning: viewModel.isScanning,
            safeItemCount: viewModel.snapshot.items.filter(\.isCleanupEligible).count)
    }

    @objc private func performMenuCommand(_ item: NSMenuItem) {
        guard let rawCommand = item.representedObject as? String,
              let command = StatusMenuCommand(rawValue: rawCommand)
        else {
            return
        }

        switch command {
        case .openDashboard:
            openDashboard()
        case .scanNow:
            viewModel.scan(force: true)
        case .cleanSafe:
            viewModel.prepareSafeCleanup()
            openDashboard()
        case .openSettings:
            openSettings()
        case .quit:
            NSApp.terminate(nil)
        }
    }
}
