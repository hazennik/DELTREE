import SwiftUI

struct DetailGridView: View {
    @Environment(\.appTheme) private var theme

    var item: StorageItem

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            row("Size", StorageFormatters.byteCount(item.bytes))
            row("Domain", item.domain.displayName)
            row("Kind", item.kind.displayName)
            row("Owner", "\(item.attribution.displayName) (\(Int(item.attributionConfidence * 100))%)")
            row("Safety", item.isActive ? "Active" : item.safety.displayName)
            row("Suggested Action", item.suggestedAction.displayName)
            if item.relatedProject.isEmpty == false {
                row("Project", item.relatedProject)
            }
            if item.relatedCodexTask.isEmpty == false {
                row("Codex Task", item.relatedCodexTask)
            }
            if item.codexSessionDescription.isEmpty == false {
                row("Session", item.codexSessionDescription)
            }
            if item.codexSessionCleanupEffect.isEmpty == false {
                row("Cleanup Effect", item.codexSessionCleanupEffect)
            }
            if item.runtimeOrDevice.isEmpty == false {
                row("Runtime / Device", item.runtimeOrDevice)
            }
            if item.stateDescription.isEmpty == false {
                row("State", item.stateDescription)
            }
            row("Created", StorageFormatters.dateTime(item.createdAt))
            row("Modified", StorageFormatters.dateTime(item.modifiedAt))
            row("Last Used", StorageFormatters.dateTime(item.lastUsedAt))
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(theme.isClassic ? title.uppercased() : title)
                .foregroundStyle(theme.secondaryText)
            Text(value)
                .textSelection(.enabled)
                .lineLimit(2)
        }
        .font(theme.font(.body))
    }
}
