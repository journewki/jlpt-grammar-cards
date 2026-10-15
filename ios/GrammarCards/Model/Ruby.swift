import Foundation

/// 예문 한 조각. 한자 단어는 후리가나와 함께 한 덩어리, 그 외 글자는 한 글자씩.
struct RubySegment: Hashable {
    let base: String
    let ruby: String?
    let highlighted: Bool
}

/// `{漢字|かんじ}` 마크업 해석
enum Ruby {
    private static let pattern = /\{([^{}|]+)\|([^{}|]+)\}/

    /// 루비를 뺀 문장: "{雨|あめ}が降る" → "雨が降る"
    static func plainText(_ markup: String) -> String {
        markup.replacing(pattern) { String($0.output.1) }
    }

    /// 화면에 그릴 조각으로 나눈다. highlights 는 루비를 뺀 문장에서 앞에서부터 차례로 찾는다.
    static func segments(_ markup: String, highlights: [String] = []) -> [RubySegment] {
        // 1) 토큰화: (본문, 후리가나?)
        var tokens: [(base: String, ruby: String?)] = []
        var rest = markup[...]
        while let match = rest.firstMatch(of: pattern) {
            for ch in rest[rest.startIndex..<match.range.lowerBound] {
                tokens.append((String(ch), nil))
            }
            tokens.append((String(match.output.1), String(match.output.2)))
            rest = rest[match.range.upperBound...]
        }
        for ch in rest {
            tokens.append((String(ch), nil))
        }

        // 2) 강조할 글자 위치 (루비를 뺀 문장 기준 글자 인덱스)
        let plain = Array(tokens.map(\.base).joined())
        var marked = Set<Int>()
        var from = 0
        for h in highlights {
            let needle = Array(h)
            guard let start = firstIndex(of: needle, in: plain, from: from) else { break }
            marked.formUnion(start..<(start + needle.count))
            from = start + needle.count
        }

        // 3) 조각마다 강조 여부 결정
        var result: [RubySegment] = []
        var offset = 0
        for token in tokens {
            let length = token.base.count
            let isMarked = (offset..<(offset + length)).contains { marked.contains($0) }
            result.append(RubySegment(base: token.base, ruby: token.ruby, highlighted: isMarked))
            offset += length
        }
        return result
    }

    private static func firstIndex(of needle: [Character], in haystack: [Character], from: Int) -> Int? {
        guard !needle.isEmpty, haystack.count >= needle.count, from <= haystack.count - needle.count else { return nil }
        for i in from...(haystack.count - needle.count) where Array(haystack[i..<(i + needle.count)]) == needle {
            return i
        }
        return nil
    }
}
