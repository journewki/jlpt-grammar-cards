import Foundation
import SwiftData

// MARK: - 급수

enum JLPTLevel: String, Codable, CaseIterable, Identifiable {
    case n5 = "N5", n4 = "N4", n3 = "N3", n2 = "N2", n1 = "N1"
    /// 일상표현 덱 (급수 없음, 별도 탭)
    case daily = "DAILY"

    /// 문법 탭에 나오는 급수
    static let grammarLevels: [JLPTLevel] = [.n5, .n4, .n3, .n2, .n1]

    var id: String { rawValue }
    /// 화면 표시용 이름
    var displayName: String { self == .daily ? "일상표현" : rawValue }
    /// 번들 데이터 파일 이름 (n5.json …)
    var fileName: String { rawValue.lowercased() }
}

// MARK: - 콘텐츠 (급수별 번들 JSON, 읽기 전용)

struct LevelDeck: Decodable {
    let version: Int
    let level: JLPTLevel
    let grammar: [Grammar]

    static func loadBundled(_ level: JLPTLevel, bundle: Bundle = .main) throws -> LevelDeck {
        guard let url = bundle.url(forResource: level.fileName, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(LevelDeck.self, from: Data(contentsOf: url))
    }
}

struct Grammar: Decodable, Identifiable, Hashable {
    /// 책의 문법 번호. 급수와 상관없이 책 전체에서 고유하며 학습 기록의 키로 쓴다.
    let no: Int
    let expression: String
    let reading: String?
    /// 같은 모양의 표현을 구분하는 분류: 명사 / な형용사 / 동사 て형 …
    let category: String
    let meaningKo: String
    let connection: String
    let example: Example

    var id: Int { no }
}

struct Example: Decodable, Hashable {
    /// 루비 마크업: {漢字|かんじ}
    let sentenceJa: String
    let translationKo: String
    /// 강조할 문법 부분. 루비를 뺀 문장에서 앞에서부터 차례로 찾는다 (〜に〜がある → ["に", "があります"])
    let highlights: [String]
}

// MARK: - 사용자 학습 기록 (SwiftData, iCloud 동기화 가능)

enum CardStatus: String, Codable {
    case new, unknown, known
}

@Model
final class CardProgress {
    // CloudKit 동기화는 .unique 제약을 지원하지 않으므로 중복 방지는 코드에서 처리
    var grammarNo: Int = 0
    var levelRaw: String = JLPTLevel.n5.rawValue
    var statusRaw: String = CardStatus.new.rawValue
    var unknownCount: Int = 0
    var lastReviewedAt: Date?
    var isBookmarked: Bool = false

    var status: CardStatus {
        get { CardStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    var level: JLPTLevel {
        get { JLPTLevel(rawValue: levelRaw) ?? .n5 }
        set { levelRaw = newValue.rawValue }
    }

    init(grammarNo: Int, level: JLPTLevel) {
        self.grammarNo = grammarNo
        self.levelRaw = level.rawValue
    }

    /// "알고 있음" / "모름" 버튼 처리.
    /// 모름 → 다음 사이클들에 새 카드와 섞여 계속 나옴. 나중에 알고 있음을 누르면 졸업.
    func record(known: Bool, at date: Date = .now) {
        lastReviewedAt = date
        if known {
            status = .known
        } else {
            status = .unknown
            unknownCount += 1
        }
    }
}

@Model
final class ReviewLog {
    var grammarNo: Int = 0
    var wasKnown: Bool = false
    var reviewedAt: Date = Date.now

    init(grammarNo: Int, wasKnown: Bool, reviewedAt: Date = .now) {
        self.grammarNo = grammarNo
        self.wasKnown = wasKnown
        self.reviewedAt = reviewedAt
    }
}
