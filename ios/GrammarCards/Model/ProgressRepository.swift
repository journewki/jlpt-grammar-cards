import Foundation
import SwiftData

/// 학습 기록(SwiftData) 읽기·쓰기
@MainActor
enum ProgressRepository {
    static func snapshots(in context: ModelContext) -> [Int: ProgressSnapshot] {
        let all = (try? context.fetch(FetchDescriptor<CardProgress>())) ?? []
        var result: [Int: ProgressSnapshot] = [:]
        for p in all {
            result[p.grammarNo] = ProgressSnapshot(status: p.status, unknownCount: p.unknownCount, lastReviewedAt: p.lastReviewedAt)
        }
        return result
    }

    /// "알고 있음" / "모름" 기록
    static func record(_ grammar: Grammar, level: JLPTLevel, known: Bool, in context: ModelContext) {
        let no = grammar.no
        var descriptor = FetchDescriptor<CardProgress>(predicate: #Predicate { $0.grammarNo == no })
        descriptor.fetchLimit = 1
        let progress: CardProgress
        if let existing = try? context.fetch(descriptor).first {
            progress = existing
        } else {
            progress = CardProgress(grammarNo: no, level: level)
            context.insert(progress)
        }
        progress.record(known: known)
        context.insert(ReviewLog(grammarNo: no, wasKnown: known))
        try? context.save()
    }

    /// 한 급수의 학습 기록을 모두 지운다
    static func reset(_ level: JLPTLevel, in context: ModelContext) {
        let raw = level.rawValue
        try? context.delete(model: CardProgress.self, where: #Predicate { $0.levelRaw == raw })
        try? context.save()
    }
}
