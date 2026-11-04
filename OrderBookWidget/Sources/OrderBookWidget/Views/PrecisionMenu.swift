import SwiftUI

/// `nSigFigs` as a native menu picker, each option labelled by the tick it produces.
struct PrecisionMenu: View {
    @Binding var selection: Precision
    let mid: Double?

    var body: some View {
        Menu {
            Picker(selection: $selection) {
                ForEach(Precision.allCases) { option in
                    Text("\(PrecisionPresentation.tickLabel(for: option, near: mid))  ·  \(option.name)", bundle: .module).tag(option)
                }
            } label: {
                Text("Price grouping", bundle: .module)
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: Glyph.grouping)
                Text(verbatim: PrecisionPresentation.tickLabel(for: selection, near: mid)).monospacedDigit()
            }
            .font(.subheadline.weight(.medium))
        }
        .accessibilityLabel(Text("Price grouping", bundle: .module))
        .accessibilityValue(Text("\(PrecisionPresentation.tickLabel(for: selection, near: mid)), \(selection.name)", bundle: .module))
        .accessibilityIdentifier(A11yID.precisionMenu)
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var selection = Precision.four
        PrecisionMenu(selection: $selection, mid: 80_250)
    }
#endif
