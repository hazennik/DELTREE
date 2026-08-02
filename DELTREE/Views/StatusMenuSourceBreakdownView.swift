import SwiftUI

struct StatusMenuSourceBreakdownView: View {
    var footprint: StorageFootprint

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            StatusMenuGaugeRowView(
                title: "Codex Native",
                value: StorageFormatters.byteCount(codexNativeBytes),
                detail: "Home, sessions, workspaces",
                systemImage: "terminal",
                tint: .green,
                share: share(for: codexNativeBytes))

            StatusMenuGaugeRowView(
                title: "Xcode Generated",
                value: StorageFormatters.byteCount(xcodeGeneratedBytes),
                detail: "Simulators, builds, archives",
                systemImage: "hammer",
                tint: .orange,
                share: share(for: xcodeGeneratedBytes))

            if codexLinkedXcodeBytes > 0 {
                HStack(spacing: 8) {
                    Label("Codex-linked Xcode", systemImage: "link")
                    Spacer(minLength: 8)
                    Text(StorageFormatters.byteCount(codexLinkedXcodeBytes))
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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

    private func share(for bytes: Int64) -> Double {
        guard footprint.totalBytes > 0 else {
            return 0
        }
        return Double(max(0, bytes)) / Double(footprint.totalBytes)
    }
}
