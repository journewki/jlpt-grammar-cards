import SwiftUI

/// 카드 한 장의 앞면: 표현 + 예문. 뜻을 펼치면 뜻·접속·해석이 나온다.
struct CardFaceView: View {
    let grammar: Grammar
    let level: JLPTLevel
    var showMeaning: Bool
    var showFurigana = true
    /// 이 카드를 이전에 본 기록 (nil 이면 처음 보는 카드)
    var history: ProgressSnapshot?
    /// false 면 기록 배지를 숨긴다 (목록에서 열어 본 카드 등)
    var showHistory = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 6) {
                Tag(text: level.rawValue, color: .accentColor)
                Tag(text: grammar.category, color: .secondary)
                Spacer()
                if showHistory { HistoryBadge(history: history) }
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

/// "NEW" / "모름 2회 · 3일 전" / "알고 있음 · 5분 전"
private struct HistoryBadge: View {
    let history: ProgressSnapshot?

    var body: some View {
        if let history, history.status != .new {
            let color: Color = history.status == .unknown ? .red : .green
            let label = history.status == .unknown ? "모름 \(max(history.unknownCount, 1))회" : "알고 있음"
            let when = history.lastReviewedAt.map { " · " + RelativeTime.korean(since: $0) } ?? ""
            Tag(text: label + when, color: color)
        } else {
            Tag(text: "NEW", color: .blue)
        }
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
