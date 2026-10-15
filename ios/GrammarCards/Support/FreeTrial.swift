import Foundation

/// 무료 체험 1사이클의 진행 상황. 중간에 나갔다 들어와도 같은 사이클을 이어서 끝까지 할 수 있도록 저장한다.
struct FreeTrial: Codable, Equatable {
    var level: JLPTLevel
    var cardNos: [Int]
    var knownNos: [Int] = []
    var unknownNos: [Int] = []

    var isFinished: Bool { knownNos.count + unknownNos.count >= cardNos.count }

    static func load(_ defaults: UserDefaults = .standard) -> FreeTrial? {
        guard let data = defaults.data(forKey: SettingsKey.freeTrial) else { return nil }
        return try? JSONDecoder().decode(FreeTrial.self, from: data)
    }

    func save(_ defaults: UserDefaults = .standard) {
        defaults.set(try? JSONEncoder().encode(self), forKey: SettingsKey.freeTrial)
    }

    static func clear(_ defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: SettingsKey.freeTrial)
    }
}

/// 무료 사용자가 학습을 시작할 수 있는지
enum StudyAccess: Equatable {
    /// 시작 가능 (이용권 보유, 아직 무료 체험 전, 또는 이 급수의 무료 체험 이어하기)
    case allowed
    /// 다른 급수에서 무료 체험이 진행 중
    case trialInProgress(JLPTLevel)
    /// 무료 체험을 다 썼음 → 결제 필요
    case locked
}
