import SwiftUI

struct CleanupPreflightView: View {
    @Environment(\.appTheme) private var theme

    var plan: CleanupPlan
    var confirmAction: () -> Void
    var cancelAction: () -> Void
    var exportAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Cleanup Preflight", systemImage: "trash")
                    .font(theme.font(.title3))
                    .bold()
                Spacer()
                Text(StorageFormatters.byteCount(plan.reclaimableBytes))
                    .font(theme.font(.title3))
                    .monospacedDigit()
            }

            Text("DELTREE will use Trash for files and folders, or approved simctl commands for simulator actions. Nothing is permanently deleted by the app.")
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            List {
                if plan.actions.isEmpty == false {
                    Section("Approved Actions") {
                        ForEach(plan.actions) { action in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Label(action.action.displayName, systemImage: action.action.systemImage)
                                    Spacer()
                                    Text(StorageFormatters.byteCount(action.bytes))
                                        .monospacedDigit()
                                }
                                Text(action.item.path)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(theme.secondaryText)
                                    .lineLimit(2)
                                Text(action.reason)
                                    .font(theme.font(.caption))
                                    .foregroundStyle(theme.secondaryText)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }

                if plan.blockedItems.isEmpty == false {
                    Section("Blocked") {
                        ForEach(plan.blockedItems) { item in
                            Label(item.displayName, systemImage: "lock")
                                .help(item.explanation)
                        }
                    }
                }
            }
            .frame(minHeight: 280)

            HStack {
                Button("Export Report", systemImage: "square.and.arrow.down", action: exportAction)
                    .disabled(plan.actions.isEmpty && plan.blockedItems.isEmpty)
                Spacer()
                Button("Cancel", role: .cancel, action: cancelAction)
                Button("Run Cleanup", systemImage: "trash", action: confirmAction)
                    .buttonStyle(.borderedProminent)
                    .tint(theme.danger)
                    .disabled(plan.actions.isEmpty)
            }
        }
        .padding(18)
        .frame(minWidth: 640, minHeight: 460)
        .background(theme.background)
        .foregroundStyle(theme.primaryText)
    }
}
