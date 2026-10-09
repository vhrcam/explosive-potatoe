import SwiftUI

struct TapNumbersGame: View {
    let onComplete: () -> Void

    @State private var numbers = Array(1...9).shuffled()
    @State private var next = 1
    @State private var wrongTile: Int?
    @State private var needed = 1

    private let columns = Array(repeating: GridItem(.fixed(96), spacing: 14), count: 3)
    private var isComplete: Bool { next > numbers.count }

    var body: some View {
        VStack(spacing: 16) {
            header

            ProgressBarView(
                value: wrongTile == nil ? next - 1 : 0,
                total: numbers.count,
                labelColor: wrongTile == nil ? Theme.ink : Theme.red
            )

            ZStack {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(numbers, id: \.self) { number in
                        tile(number)
                    }
                }
                if wrongTile != nil {
                    ResultBadge(isCheck: false, size: 118)
                        .transition(.scale)
                }
                if isComplete {
                    ResultBadge(isCheck: true, size: 122)
                        .transition(.scale)
                    Sparkle(size: 28).offset(x: -158, y: -150)
                    Sparkle(size: 36).offset(x: 146, y: -112)
                    Sparkle(size: 24).offset(x: -154, y: 128)
                    Sparkle(size: 32).offset(x: 146, y: 124)
                }
            }
            .frame(width: 316, height: 316)

            if isComplete {
                CompleteFooter(onDone: onComplete)
            } else {
                Spacer(minLength: 0)
                FuseWarning()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if isComplete {
            MinigameHeader(label: "Minigame complete · +10", labelColor: Theme.green, title: "All 9!")
        } else if let wrongTile {
            MinigameHeader(
                label: "Wrong tile · reshuffling",
                labelColor: Theme.red,
                title: "Oops! That's \(wrongTile)",
                subtitle: "You needed \(needed). Board reshuffles, start again from 1."
            )
        } else {
            MinigameHeader(title: "Tap 1 → 9", subtitle: "Wrong tap reshuffles the board!")
        }
    }

    private func tile(_ number: Int) -> some View {
        let done = number < next
        let fill: Color
        let text: Color
        let border: Color
        if isComplete {
            (fill, text, border) = (Color(hex: 0x9DD3A5), .white, Color(hex: 0x8F8170))
        } else if number == wrongTile {
            (fill, text, border) = (Theme.red, .white, Theme.ink)
        } else if wrongTile != nil {
            (fill, text, border) = done
                ? (Color(hex: 0xB9DFBE), .white, Color(hex: 0xB5A592))
                : (Color(hex: 0xFFF7EA), Color(hex: 0xA8998A), Color(hex: 0xB5A592))
        } else {
            (fill, text, border) = done ? (Theme.green, .white, Theme.ink) : (.white, Theme.ink, Theme.ink)
        }

        return Text("\(number)")
            .font(.lilita(46))
            .foregroundStyle(text)
            .frame(width: 96, height: 96)
            .background(RoundedRectangle(cornerRadius: 18).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(border, lineWidth: 3))
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.tileShadow).offset(y: 5))
            .contentShape(Rectangle())
            .onTapGesture { tap(number) }
            .allowsHitTesting(wrongTile == nil && !isComplete)
    }

    private func tap(_ number: Int) {
        if number == next {
            withAnimation(.spring(duration: 0.3)) { next += 1 }
        } else if number > next {
            needed = next
            withAnimation(.spring(duration: 0.3)) { wrongTile = number }
            Task {
                try? await Task.sleep(for: .seconds(1))
                withAnimation(.spring(duration: 0.4)) {
                    next = 1
                    wrongTile = nil
                    numbers.shuffle()
                }
            }
        }
    }
}

#Preview {
    TapNumbersGame(onComplete: {})
        .screen()
}
