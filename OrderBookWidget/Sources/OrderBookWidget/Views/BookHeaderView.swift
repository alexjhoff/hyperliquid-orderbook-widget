import SwiftUI

/// Market picker on the left, connection status on the right.
struct BookHeaderView: View {
    @Bindable var viewModel: OrderBookViewModel

    var body: some View {
        HStack {
            Picker(selection: $viewModel.symbol) {
                ForEach(Symbol.allCases) { symbol in
                    Text(verbatim: symbol.coin).tag(symbol)
                }
            } label: {
                Text("Market", bundle: .module)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: Layout.symbolPickerWidth)
            .accessibilityIdentifier(A11yID.symbolPicker)
            Spacer()
            ConnectionStatusView(viewModel: viewModel)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.m)
    }
}

/// A dot and a word. The label ticks once a second so "3s ago" and retry countdowns stay current.
private struct ConnectionStatusView: View {
    let viewModel: OrderBookViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let presentation = StatusPresentation(
                status: viewModel.status,
                bookAge: viewModel.book.map { context.date.timeIntervalSince($0.receivedAt) },
                statusAge: context.date.timeIntervalSince(viewModel.statusChangedAt)
            )
            HStack(spacing: Spacing.s) {
                Circle()
                    .fill(tint(presentation.tone))
                    .frame(width: Layout.statusDot, height: Layout.statusDot)
                Text(verbatim: presentation.label)
                    .monospacedDigit()
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Connection, \(presentation.label)", bundle: .module))
        }
    }

    private func tint(_ tone: StatusPresentation.Tone) -> Color {
        switch tone {
        case .live: .bid
        case .quiet: .yellow
        case .busy: .orange
        case .offline: .secondary
        }
    }
}
