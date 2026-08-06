import SwiftUI

struct StorageFilterBarView: View {
    @Environment(\.appTheme) private var theme

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
        .background(theme.isClassic ? theme.panelFill : Color.clear)
        .foregroundStyle(theme.primaryText)
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
        Group {
            if theme.isClassic {
                TextField("FILTER", text: $searchText)
                    .classicTextField()
            } else {
                TextField("Filter", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .font(theme.font(.body))
            }
        }
        .frame(minWidth: 140, idealWidth: 220)
    }

    private var pickers: some View {
        Group {
            if theme.isClassic {
                ClassicOptionButton(title: "Safety", value: selectedSafety?.displayName ?? "Any") {
                    cycleSafety()
                }
                .frame(width: 150)

                ClassicOptionButton(title: "Owner", value: selectedOwner?.displayName ?? "Any") {
                    cycleOwner()
                }
                .frame(width: 150)
            } else {
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
    }

    private var includeIgnoredToggle: some View {
        Group {
            if theme.isClassic {
                ClassicToggleButton(title: "Show Ignored", isOn: $includeIgnoredItems)
            } else {
                Toggle("Show Ignored", isOn: $includeIgnoredItems)
                    .toggleStyle(.checkbox)
            }
        }
    }

    private func cycleSafety() {
        let values = [Optional<SafetyClassification>.none] + SafetyClassification.allCases.map(Optional.some)
        guard let index = values.firstIndex(of: selectedSafety) else {
            selectedSafety = nil
            return
        }
        selectedSafety = values[(index + 1) % values.count]
    }

    private func cycleOwner() {
        let values = [Optional<OwnerAttribution>.none] + OwnerAttribution.allCases.map(Optional.some)
        guard let index = values.firstIndex(of: selectedOwner) else {
            selectedOwner = nil
            return
        }
        selectedOwner = values[(index + 1) % values.count]
    }
}
