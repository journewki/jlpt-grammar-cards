import SwiftUI

/// 후리가나가 달린 예문. 글자 단위로 줄바꿈되고, 문법 부분은 강조색으로 표시된다.
struct RubyText: View {
    let markup: String
    var highlights: [String] = []
    var showFurigana = true
    var font: Font = .title3
    var highlightColor: Color = .accentColor

    var body: some View {
        FlowLayout(lineSpacing: 6) {
            ForEach(Array(Ruby.segments(markup, highlights: highlights).enumerated()), id: \.offset) { _, seg in
                VStack(spacing: 0) {
                    if showFurigana {
                        // 후리가나가 없는 글자도 같은 높이를 차지해 줄이 가지런하게 유지된다
                        Text(seg.ruby ?? " ")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .opacity(seg.ruby == nil ? 0 : 1)
                            .fixedSize()
                    }
                    Text(seg.base)
                        .font(font)
                        .fontWeight(seg.highlighted ? .bold : .regular)
                        .foregroundStyle(seg.highlighted ? highlightColor : .primary)
                        .fixedSize()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Ruby.plainText(markup))
    }
}

/// 왼쪽부터 채우고 폭이 넘치면 다음 줄로 넘기는 레이아웃
struct FlowLayout: Layout {
    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            widest = max(widest, x)
        }
        return CGSize(width: proposal.width ?? widest, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    RubyText(markup: "{駅|えき}の{前|まえ}に{銀行|ぎんこう}があります。", highlights: ["に", "があります"])
        .padding()
}
