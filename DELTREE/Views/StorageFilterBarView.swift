import SwiftUI

struct StorageFilterBarView: View {
    @Binding var selectedSafety: SafetyClassification?
    @Binding var selectedOwner: OwnerAttribution?
    @Binding var includeIgnoredItems: Bool

    var body: some View {
        HStack(spacing: 10) {
            Picker("Safety", selection: $selectedSafety) {
                Text("Any Safety").tag(Optional<SafetyClassification>.none)
                ForEach(SafetyClassification.allCases, id: \.self) { safety in
                    Text(safety.displayName).tag(Optional(safety))
                }
            }
            .frame(width: 170)

            Picker("Owner", selection: $selectedOwner) {
                Text("Any Owner").tag(Optional<OwnerAttribution>.none)
                ForEach(OwnerAttribution.allCases, id: \.self) { owner in
                    Text(owner.displayName).tag(Optional(owner))
                }
            }
            .frame(width: 170)

            Toggle("Show Ignored", isOn: $includeIgnoredItems)
                .toggleStyle(.checkbox)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
