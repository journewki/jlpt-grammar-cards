import XCTest
@testable import GrammarCards

final class ContentTests: XCTestCase {
    /// 번들에 들어간 급수별 JSON 이 모두 읽히는지
    func testAllDecksDecode() throws {
        var seen = Set<Int>()
        for level in JLPTLevel.allCases {
            let deck = try LevelDeck.loadBundled(level)
            XCTAssertEqual(deck.level, level)
            XCTAssertFalse(deck.grammar.isEmpty, "\(level) 카드가 비어 있음")
            for g in deck.grammar {
                XCTAssertTrue(seen.insert(g.no).inserted, "#\(g.no) 번호 중복")
            }
        }
    }
}

final class RubyTests: XCTestCase {
    func testPlainText() {
        XCTAssertEqual(Ruby.plainText("{駅|えき}の{前|まえ}に"), "駅の前に")
    }

    func testSpokenTextUsesReadings() {
        XCTAssertEqual(Ruby.spokenText("{一言|ひとこと}{言|い}った"), "ひとこといった")
    }

    func testSegmentsAndHighlights() {
        let segs = Ruby.segments("{駅|えき}の{前|まえ}に{銀行|ぎんこう}があります。", highlights: ["に", "があります"])
        XCTAssertEqual(segs.first, RubySegment(base: "駅", ruby: "えき", highlighted: false))
        XCTAssertEqual(segs.first { $0.base == "銀行" }?.ruby, "ぎんこう")
        let marked = segs.filter(\.highlighted).map(\.base).joined()
        XCTAssertEqual(marked, "にがあります")
    }

    func testHighlightInsideRubyMarksWholeWord() {
        let segs = Ruby.segments("{見合|みあ}わせて", highlights: ["合わせて"])
        XCTAssertTrue(segs[0].highlighted)
    }
}

final class SessionBuilderTests: XCTestCase {
    private func card(_ no: Int) -> Grammar {
        Grammar(no: no, expression: "〜\(no)", reading: nil, category: "테스트", meaningKo: "뜻",
                connection: "접속", example: Example(sentenceJa: "例", translationKo: "예", highlights: []))
    }

    private struct FixedRNG: RandomNumberGenerator {
        var state: UInt64 = 42
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    func testMixesUnknownWithNewCards() {
        let cards = (1...30).map(card)
        var progress: [Int: ProgressSnapshot] = [:]
        for no in 1...10 { progress[no] = ProgressSnapshot(status: .unknown, unknownCount: 1, lastReviewedAt: .now) }
        var rng = FixedRNG()
        let picked = SessionBuilder.build(grammar: cards, progress: progress,
                                          settings: StudySettings(cardsPerSession: 10, reviewRatio: 0.4), using: &rng)
        XCTAssertEqual(picked.count, 10)
        XCTAssertEqual(picked.filter { $0.no <= 10 }.count, 4, "모름 카드 40%")
        XCTAssertEqual(Set(picked.filter { $0.no > 10 }.map(\.no)), Set(11...16), "새 카드는 책 번호 순")
    }

    func testFillsWithUnknownWhenNoNewCardsLeft() {
        let cards = (1...5).map(card)
        var progress: [Int: ProgressSnapshot] = [:]
        for no in 1...5 { progress[no] = ProgressSnapshot(status: .unknown, unknownCount: 1, lastReviewedAt: .now) }
        var rng = FixedRNG()
        let picked = SessionBuilder.build(grammar: cards, progress: progress,
                                          settings: StudySettings(cardsPerSession: 10, reviewRatio: 0.4), using: &rng)
        XCTAssertEqual(picked.count, 5)
    }
}
