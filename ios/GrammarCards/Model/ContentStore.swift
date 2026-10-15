import Foundation

/// 번들에 들어 있는 급수별 카드 데이터. 앱 실행 중 한 번만 읽는다.
enum ContentStore {
    static let decks: [JLPTLevel: [Grammar]] = {
        var result: [JLPTLevel: [Grammar]] = [:]
        for level in JLPTLevel.allCases {
            do {
                result[level] = try LevelDeck.loadBundled(level).grammar
            } catch {
                assertionFailure("\(level.fileName).json 을 읽지 못함: \(error)")
                result[level] = []
            }
        }
        return result
    }()

    static func cards(_ level: JLPTLevel) -> [Grammar] {
        decks[level] ?? []
    }
}
