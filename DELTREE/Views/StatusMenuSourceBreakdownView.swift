import SwiftUI

struct StatusMenuSourceBreakdownView: View {
    @Environment(\.appTheme) private var theme

    var footprint: StorageFootprint

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            StatusMenuSegmentedListView(
                segments: sourceSegments,
                totalBytes: max(1, codexNativeBytes + xcodeGeneratedBytes))

            if codexLinkedXcodeBytes > 0 {
                HStack(spacing: 8) {
                    if theme.isClassic {
                        Text(theme.classicGlyph(for: "link"))
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 36, alignment: .leading)
                    } else {
                        Image(systemName: "link")
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 16)
                    }
                    Text(theme.isClassic ? "CODEX-LINKED XCODE" : "Codex-linked Xcode")
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(StorageFormatters.byteCount(codexLinkedXcodeBytes))
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var codexNativeBytes: Int64 {
        footprint.domainBreakdowns
            .filter { $0.domain.isCodexDomain }
            .reduce(0) { $0 + max(0, $1.bytes) }
    }

    private var xcodeGeneratedBytes: Int64 {
        footprint.xcodeRelatedBytes
    }

    private var codexLinkedXcodeBytes: Int64 {
        max(0, footprint.codexAttributedBytes - codexNativeBytes)
    }

    private var sourceSegments: [StatusMenuSegment] {
        [
            StatusMenuSegment(
                id: "codex-native",
                title: "Codex Native",
                value: StorageFormatters.byteCount(codexNativeBytes),
                detail: "Home, sessions, workspaces",
                systemImage: "terminal",
                tint: theme.isClassic ? theme.normalTint : theme.safe,
                bytes: codexNativeBytes),
            StatusMenuSegment(
                id: "xcode-generated",
                title: "Xcode Generated",
                value: StorageFormatters.byteCount(xcodeGeneratedBytes),
                detail: "Simulators, builds, archives",
                systemImage: "hammer",
                tint: theme.isClassic ? theme.normalTint : theme.warning,
                bytes: xcodeGeneratedBytes),
        ]
    }
}
