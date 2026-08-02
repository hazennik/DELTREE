import SwiftUI

struct DomainSidebarView: View {
    var summaries: [DomainSummary]
    var totalBytes: Int64
    @Binding var selectedSection: DashboardSection
    @Binding var selectedDomain: StorageDomain?

    var body: some View {
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
        .navigationTitle("DELTREE")
        .frame(minWidth: 160, idealWidth: 240)
    }
}
