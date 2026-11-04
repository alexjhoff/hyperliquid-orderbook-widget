import SwiftUI

/// Market picker on the left, connection status on the right.
struct BookHeaderView: View {
    @Bindable var viewModel: OrderBookViewModel

    var body: some View {
        HStack {
            Picker("Market", selection: $viewModel.symbol) {
                ForEach(Symbol.allCases) { symbol in
                    Text(symbol.coin).tag(symbol)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 180)
            .accessibilityIdentifier("symbolPicker")
            Spacer()
            ConnectionStatusView(viewModel: viewModel)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
            HStack(spacing: 6) {
                Circle()
                    .fill(tint(presentation.tone))
                    .frame(width: 7, height: 7)
                Text(presentation.label)
                    .monospacedDigit()
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Connection, \(presentation.label)")
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
