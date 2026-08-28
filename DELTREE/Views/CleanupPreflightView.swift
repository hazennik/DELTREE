import SwiftUI

struct CleanupPreflightView: View {
    @Environment(\.appTheme) private var theme

    var plan: CleanupPlan
    var confirmationThresholdBytes: Int64
    var confirmAction: () -> Void
    var cancelAction: () -> Void
    var exportAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                if theme.isClassic {
                    HStack(spacing: 8) {
                        Text(theme.classicGlyph(for: "trash"))
                            .foregroundStyle(theme.danger)
                        Text("CLEANUP PREFLIGHT")
                    }
                    .font(theme.font(.title3))
                    .bold()
                } else {
                    Label("Cleanup Preflight", systemImage: "trash")
                        .font(theme.font(.title3))
                        .bold()
                }
                Spacer()
                Text(StorageFormatters.byteCount(plan.reclaimableBytes))
                    .font(theme.font(.title3))
                    .monospacedDigit()
            }

            Text(theme.isClassic ? cleanupDisclosure.uppercased() : cleanupDisclosure)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if showsHighImpactWarning {
                Text(theme.isClassic ? "HIGH-IMPACT CLEANUP: THIS PLAN IS ABOVE YOUR CONFIRMATION THRESHOLD." : "High-impact cleanup: this plan is above your confirmation threshold.")
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }

            List {
                if plan.actions.isEmpty == false {
                    Section(theme.isClassic ? "APPROVED ACTIONS" : "Approved Actions") {
                        ForEach(plan.actions) { action in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if theme.isClassic {
                                        HStack(spacing: 6) {
                                            Text(theme.classicGlyph(for: action.action.systemImage))
                                                .foregroundStyle(theme.danger)
                                            Text(action.action.displayName.uppercased())
                                        }
                                    } else {
                                        Label(action.action.displayName, systemImage: action.action.systemImage)
                                    }
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
                    Section(theme.isClassic ? "BLOCKED" : "Blocked") {
                        ForEach(plan.blockedItems) { item in
                            Group {
                                if theme.isClassic {
                                    HStack(spacing: 6) {
                                        Text(theme.classicGlyph(for: "lock"))
                                            .foregroundStyle(theme.secondaryText)
                                        Text(item.displayName.uppercased())
                                    }
                                } else {
                                    Label(item.displayName, systemImage: "lock")
                                }
                            }
                            .help(item.explanation)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .frame(minHeight: 280)

            HStack {
                if theme.isClassic {
                    Button("[EXPORT]", action: exportAction)
                        .buttonStyle(ClassicButtonStyle())
                        .disabled(plan.actions.isEmpty && plan.blockedItems.isEmpty)
                } else {
                    Button("Export Report", systemImage: "square.and.arrow.down", action: exportAction)
                        .disabled(plan.actions.isEmpty && plan.blockedItems.isEmpty)
                }
                Spacer()
                if theme.isClassic {
                    Button("[CANCEL]", role: .cancel, action: cancelAction)
                        .buttonStyle(ClassicButtonStyle())
                    Button("[RUN CLEANUP]", action: confirmAction)
                        .buttonStyle(ClassicButtonStyle())
                        .foregroundStyle(theme.danger)
                        .disabled(plan.actions.isEmpty)
                } else {
                    Button("Cancel", role: .cancel, action: cancelAction)
                    Button("Run Cleanup", systemImage: "trash", action: confirmAction)
                        .buttonStyle(.borderedProminent)
                        .tint(theme.danger)
                        .disabled(plan.actions.isEmpty)
                }
            }
        }
        .padding(18)
        .frame(minWidth: 640, minHeight: 460)
        .background(theme.background)
        .foregroundStyle(theme.primaryText)
    }

    private var showsHighImpactWarning: Bool {
        confirmationThresholdBytes > 0 && plan.reclaimableBytes >= confirmationThresholdBytes
    }

    private var cleanupDisclosure: String {
        if plan.permanentlyRemovesSimulatorData {
            return "Files and folders are moved to Trash. Simulator delete and erase actions use simctl, permanently remove the affected simulator data, and cannot be recovered from Trash."
        }
        return "Files and folders are moved to Trash and remain recoverable until Trash is emptied."
    }
}
