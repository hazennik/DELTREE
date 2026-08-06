import SwiftUI

struct StorageItemTableView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var items: [StorageItem]
    @Binding var selectedItemID: StorageItem.ID?
    @Binding var sortOrder: [KeyPathComparator<StorageItem>]

    var body: some View {
        Table(items, selection: $selectedItemID, sortOrder: $sortOrder) {
            TableColumn("Name") { item in
                Group {
                    if theme.isClassic {
                        HStack(spacing: 8) {
                            Text(theme.classicGlyph(for: item.domain.symbolName))
                                .foregroundStyle(item.domain.menuTint(in: theme))
                            Text(item.displayName.uppercased())
                        }
                    } else {
                        Label(item.displayName, systemImage: item.domain.symbolName)
                    }
                }
                .lineLimit(1)
                .help(item.path)
            }
            .width(min: 120, ideal: 360)

            TableColumn("Size") { item in
                Text(StorageFormatters.byteCount(item.bytes))
                    .font(theme.font(.body))
                    .monospacedDigit()
            }
            .width(min: 64, ideal: 90)

            TableColumn("Safety") { item in
                VStack(alignment: .leading, spacing: 2) {
                    SafetyBadgeView(safety: item.safety, isActive: item.isActive)
                    Group {
                        if theme.isClassic {
                            HStack(spacing: 6) {
                                Text(theme.classicGlyph(for: item.suggestedAction.systemImage))
                                Text(item.suggestedAction.displayName.uppercased())
                            }
                        } else {
                            Label(item.suggestedAction.displayName, systemImage: item.suggestedAction.systemImage)
                        }
                    }
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
                }
            }
            .width(min: 104, ideal: 160)
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .foregroundStyle(theme.primaryText)
        .animation(scanListAnimation, value: itemIdentityToken)
    }

    private var itemIdentityToken: Int {
        items.count
    }

    private var scanListAnimation: Animation? {
        guard theme.isClassic, reduceMotion == false else {
            return nil
        }
        return .linear(duration: 0.12)
    }
}
