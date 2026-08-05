import SwiftUI

struct StatusMenuSuggestedCleanupView: View {
    @Environment(\.appTheme) private var theme

    var suggestions: [StatusMenuCleanupSuggestion]
    var totalCount: Int
    var totalBytes: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if theme.isClassic {
                    HStack(spacing: 6) {
                        Text(theme.classicGlyph(for: "trash"))
                            .foregroundStyle(theme.safe)
                        Text("CLEAN SAFE WOULD INCLUDE")
                    }
                    .lineLimit(1)
                } else {
                    Label("Clean Safe would include", systemImage: "trash")
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(StorageFormatters.byteCount(totalBytes))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .font(theme.font(.caption))

            VStack(alignment: .leading, spacing: 7) {
                ForEach(suggestions) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: theme.isClassic ? 0 : 2)
                            .fill(theme.domainFillTint(suggestion.domain))
                            .frame(width: 8, height: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            if theme.isClassic {
                                HStack(spacing: 6) {
                                    Text(theme.classicGlyph(for: suggestion.domain.symbolName))
                                        .foregroundStyle(suggestion.domain.menuTint(in: theme))
                                    Text(suggestion.title.uppercased())
                                }
                                .lineLimit(1)
                            } else {
                                Label(suggestion.title, systemImage: suggestion.domain.symbolName)
                                    .lineLimit(1)
                            }
                            Text(suggestion.consequence)
                                .foregroundStyle(theme.secondaryText)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 8)

                        Text(StorageFormatters.byteCount(suggestion.bytes))
                            .monospacedDigit()
                            .foregroundStyle(theme.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            .font(theme.font(.caption))

            if hiddenSuggestionCount > 0 {
                Text(theme.isClassic ? "PLUS \(hiddenSuggestionCount) SMALLER SAFE \(hiddenSuggestionCount == 1 ? "ITEM" : "ITEMS")." : "Plus \(hiddenSuggestionCount) smaller safe \(hiddenSuggestionCount == 1 ? "item" : "items").")
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityLabel(accessibilityLabel)
        .foregroundStyle(theme.primaryText)
    }

    private var hiddenSuggestionCount: Int {
        max(0, totalCount - suggestions.count)
    }

    private var accessibilityLabel: String {
        "Suggested cleanup. Clean Safe would include \(totalCount) items, \(StorageFormatters.byteCount(totalBytes))."
    }
}
