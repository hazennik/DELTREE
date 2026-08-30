import AppKit

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let viewModel: DashboardViewModel
    private let settings: AppSettingsStore
    private let openDashboard: () -> Void
    private let openSettings: () -> Void
    private var lastIconState: StatusItemIconState?
    private var lastIconVisualMode: AppVisualMode?

    init(
        viewModel: DashboardViewModel,
        settings: AppSettingsStore,
        openDashboard: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        onAppearanceChange: @escaping () -> Void = {})
    {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.viewModel = viewModel
        self.settings = settings
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
        settings.onAppearanceChange = { [weak self] in
            self?.updateStatusItem()
            onAppearanceChange()
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

        if iconState != lastIconState || settings.visualMode != lastIconVisualMode {
            statusItem.button?.image = StatusItemIconRenderer.image(for: iconState, visualMode: settings.visualMode)
            lastIconState = iconState
            lastIconVisualMode = settings.visualMode
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
            visualMode: settings.visualMode,
            into: menu,
            target: self,
            actionSelector: #selector(performMenuCommand(_:)))
    }

    private func descriptor() -> StatusMenuDescriptor {
        let cleanupEligibleItems = viewModel.snapshot.items.filter(\.isCleanupEligible)
        return StatusMenuDescriptorBuilder.make(
            title: viewModel.menuBarTitle,
            footprint: viewModel.footprint,
            lastDelta: viewModel.lastDelta,
            isScanning: viewModel.isScanning,
            safeItemCount: cleanupEligibleItems.count,
            allowsMenuCleanup: settings.notifyOnlyByDefault == false,
            cleanupSuggestions: cleanupEligibleItems.map(StatusMenuCleanupSuggestion.make))
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
