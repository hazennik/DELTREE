import SwiftUI

struct DomainSidebarView: View {
    @Environment(\.appTheme) private var theme

    var summaries: [DomainSummary]
    var totalBytes: Int64
    @Binding var selectedSection: DashboardSection
    @Binding var selectedDomain: StorageDomain?

    var body: some View {
        Group {
            if theme.isClassic {
                classicSidebar
            } else {
                modernSidebar
            }
        }
        .navigationTitle("DELTREE")
        .background(theme.sidebarBackground)
        .foregroundStyle(theme.primaryText)
        .frame(minWidth: 160, idealWidth: 240)
    }

    private var modernSidebar: some View {
        List {
            Section("Views") {
                ForEach(DashboardSection.allCases, id: \.self) { section in
                    SidebarSectionButton(
                        section: section,
                        isSelected: selectedSection == section,
                        action: {
                            selectedSection = section
                            selectedDomain = nil
                        })
                }
            }

            Section("Domains") {
                SidebarAllStorageButton(
                    totalBytes: totalBytes,
                    action: {
                        selectedSection = .overview
                        selectedDomain = nil
                    })

                ForEach(summaries) { summary in
                    SidebarDomainButton(
                        summary: summary,
                        isSelected: selectedDomain == summary.domain,
                        action: {
                            selectedSection = summary.domain.dashboardSection
                            selectedDomain = summary.domain
                        })
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var classicSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("DELTREE")
                    .font(theme.font(.headline))
                    .foregroundStyle(theme.selectionText)
                    .padding(.bottom, 6)

                classicHeader("Views")

                ForEach(DashboardSection.allCases, id: \.self) { section in
                    ClassicSidebarButton(isSelected: selectedSection == section && selectedDomain == nil) {
                        selectedSection = section
                        selectedDomain = nil
                    } label: {
                        SidebarSectionRow(section: section)
                    }
                }

                classicHeader("Domains")
                    .padding(.top, 8)

                ClassicSidebarButton(isSelected: selectedSection == .overview && selectedDomain == nil) {
                    selectedSection = .overview
                    selectedDomain = nil
                } label: {
                    SidebarAllStorageRow(totalBytes: totalBytes)
                }

                ForEach(summaries) { summary in
                    ClassicSidebarButton(isSelected: selectedDomain == summary.domain) {
                        selectedSection = summary.domain.dashboardSection
                        selectedDomain = summary.domain
                    } label: {
                        SidebarDomainRow(summary: summary)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func classicHeader(_ title: String) -> some View {
        Text("[ \(title.uppercased()) ]")
            .font(theme.font(.caption))
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ClassicSidebarButton<LabelContent: View>: View {
    @Environment(\.appTheme) private var theme

    var isSelected: Bool
    var action: () -> Void
    @ViewBuilder var label: LabelContent

    init(
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> LabelContent
    ) {
        self.isSelected = isSelected
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(isSelected ? ">" : " ")
                    .foregroundStyle(isSelected ? theme.selectionText : theme.mutedText)
                    .frame(width: 10)
                label
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? theme.selectionFill : Color.clear)
            .overlay {
                if isSelected {
                    Rectangle()
                        .stroke(theme.panelBorder, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
