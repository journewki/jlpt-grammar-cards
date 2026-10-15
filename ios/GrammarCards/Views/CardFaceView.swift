import SwiftUI

/// 카드 한 장의 앞면: 표현 + 예문. 뜻을 펼치면 뜻·접속·해석이 나온다.
struct CardFaceView: View {
    let grammar: Grammar
    let level: JLPTLevel
    var showMeaning: Bool
    var showFurigana = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 6) {
                Tag(text: level.rawValue, color: .accentColor)
                Tag(text: grammar.category, color: .secondary)
                Spacer()
                Button {
                    Speaker.shared.speak(markup: grammar.example.sentenceJa)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .accessibilityLabel("예문 듣기")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(grammar.expression)
                    .font(.system(size: 32, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
                if let reading = grammar.reading {
                    Text(reading)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            RubyText(markup: grammar.example.sentenceJa,
                     highlights: grammar.example.highlights,
                     showFurigana: showFurigana)

            Spacer(minLength: 0)

            if showMeaning {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                    Text(grammar.meaningKo)
                        .font(.title3.weight(.semibold))
                    Label(grammar.connection, systemImage: "link")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(grammar.example.translationKo)
                        .font(.callout)
                }
                .transition(.opacity)
            } else {
                Text("탭해서 뜻 보기")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }
}

private struct Tag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}
