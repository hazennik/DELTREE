import SwiftUI

struct StorageFilterBarView: View {
    @Binding var searchText: String
    @Binding var selectedSafety: SafetyClassification?
    @Binding var selectedOwner: OwnerAttribution?
    @Binding var includeIgnoredItems: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            controls

            VStack(alignment: .leading, spacing: 8) {
                searchField

                HStack(spacing: 10) {
                    pickers
                    includeIgnoredToggle
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            searchField
            pickers
            includeIgnoredToggle
            Spacer()
        }
    }

    private var searchField: some View {
        TextField("Filter", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 140, idealWidth: 220)
    }

    private var pickers: some View {
        Group {
            Picker("Safety", selection: $selectedSafety) {
                Text("Any Safety").tag(Optional<SafetyClassification>.none)
                ForEach(SafetyClassification.allCases, id: \.self) { safety in
                    Text(safety.displayName).tag(Optional(safety))
                }
            }
            .frame(width: 150)

            Picker("Owner", selection: $selectedOwner) {
                Text("Any Owner").tag(Optional<OwnerAttribution>.none)
                ForEach(OwnerAttribution.allCases, id: \.self) { owner in
                    Text(owner.displayName).tag(Optional(owner))
                }
            }
            .frame(width: 150)
        }
    }

    private var includeIgnoredToggle: some View {
        Toggle("Show Ignored", isOn: $includeIgnoredItems)
            .toggleStyle(.checkbox)
    }
}
