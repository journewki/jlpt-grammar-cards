import Foundation

// MARK: - 학습 설정

struct StudySettings: Codable, Equatable {
    /// 한 사이클에 볼 카드 수
    var cardsPerSession: Int = 20
    /// 사이클 중 "모름" 카드가 차지하는 비율 (0.0 ~ 1.0). 나머지는 새 카드.
    var reviewRatio: Double = 0.4

    static let sessionSizeOptions = [10, 20, 30, 50]
}

// MARK: - 사이클 구성

/// 카드 선택에 필요한 최소 정보. SwiftData 모델과 분리해서 순수 로직으로 테스트할 수 있게 한다.
struct ProgressSnapshot {
    let status: CardStatus
    let unknownCount: Int
    let lastReviewedAt: Date?
}

enum SessionBuilder {
    /// 한 급수 안에서 이번 사이클에 나올 카드를 고른다.
    ///
    /// 1. 모름 카드: 가장 오래전에 본 것 → 모름 횟수 많은 것 순으로 `size * reviewRatio`장
    /// 2. 새 카드: 책 번호 순으로 남은 자리 채움
    /// 3. 새 카드가 모자라면 모름 카드로, 그래도 모자라면 알고 있음 카드(오래된 순)로 채움
    /// 4. 모름 카드와 새 카드가 섞이도록 셔플
    static func build<R: RandomNumberGenerator>(
        grammar: [Grammar],
        progress: [Int: ProgressSnapshot],
        settings: StudySettings,
        using rng: inout R
    ) -> [Grammar] {
        let size = max(0, settings.cardsPerSession)
        let ratio = min(max(settings.reviewRatio, 0), 1)

        func status(_ g: Grammar) -> CardStatus { progress[g.no]?.status ?? .new }
        let oldestFirst: (Grammar, Grammar) -> Bool = { a, b in
            let pa = progress[a.no], pb = progress[b.no]
            let da = pa?.lastReviewedAt ?? .distantPast, db = pb?.lastReviewedAt ?? .distantPast
            if da != db { return da < db }
            let ua = pa?.unknownCount ?? 0, ub = pb?.unknownCount ?? 0
            if ua != ub { return ua > ub }
            return a.no < b.no
        }

        var unknown = grammar.filter { status($0) == .unknown }.sorted(by: oldestFirst)
        var fresh = grammar.filter { status($0) == .new }.sorted { $0.no < $1.no }
        var known = grammar.filter { status($0) == .known }.sorted(by: oldestFirst)

        var picked: [Grammar] = []
        func take(_ pool: inout [Grammar], _ n: Int) {
            let k = min(max(n, 0), pool.count)
            picked += pool.prefix(k)
            pool.removeFirst(k)
        }

        take(&unknown, Int((Double(size) * ratio).rounded()))
        take(&fresh, size - picked.count)
        take(&unknown, size - picked.count)
        take(&known, size - picked.count)

        picked.shuffle(using: &rng)
        return picked
    }

    static func build(grammar: [Grammar], progress: [Int: ProgressSnapshot], settings: StudySettings) -> [Grammar] {
        var rng = SystemRandomNumberGenerator()
        return build(grammar: grammar, progress: progress, settings: settings, using: &rng)
    }
}

// MARK: - 진행 중인 사이클

/// 한 사이클의 진행 상태. 카드마다 한 번 답하면 끝나고,
/// 모름 카드는 다음 사이클에서 새 카드와 섞여 다시 나온다.
struct StudySession {
    let level: JLPTLevel
    let cards: [Grammar]
    private(set) var index = 0
    private(set) var knownNos: [Int] = []
    private(set) var unknownNos: [Int] = []

    init(level: JLPTLevel, cards: [Grammar]) {
        self.level = level
        self.cards = cards
    }

    var current: Grammar? { cards.indices.contains(index) ? cards[index] : nil }
    var isFinished: Bool { index >= cards.count }
    var progressText: String { "\(min(index + 1, cards.count)) / \(cards.count)" }

    mutating func answer(known: Bool) {
        guard let card = current else { return }
        if known { knownNos.append(card.no) } else { unknownNos.append(card.no) }
        index += 1
    }
}
