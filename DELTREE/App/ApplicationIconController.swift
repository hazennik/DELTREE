import AppKit

@MainActor
enum ApplicationIconController {
    static func apply(visualMode: AppVisualMode) {
        switch visualMode {
        case .classic:
            NSApp.applicationIconImage = NSImage(named: "ClassicAppIcon")
        case .modern:
            NSApp.applicationIconImage = nil
        }
    }
}
