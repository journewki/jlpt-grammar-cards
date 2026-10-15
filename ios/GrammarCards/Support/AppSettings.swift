import Foundation

/// @AppStorage 키 모음
enum SettingsKey {
    static let cardsPerSession = "cardsPerSession"
    static let reviewRatio = "reviewRatio"
    static let showMeaning = "showMeaning"
    static let showFurigana = "showFurigana"
    static let autoPlaySpeech = "autoPlaySpeech"
    static let speechRate = "speechRate"
    static let unlocked = "unlocked"
    static let freeCycleUsed = "freeCycleUsed"
    static let freeTrial = "freeTrial"
}

extension StudySettings {
    /// 저장된 설정값으로 만든다
    static func current(_ defaults: UserDefaults = .standard) -> StudySettings {
        var s = StudySettings()
        if defaults.object(forKey: SettingsKey.cardsPerSession) != nil {
            s.cardsPerSession = defaults.integer(forKey: SettingsKey.cardsPerSession)
        }
        if defaults.object(forKey: SettingsKey.reviewRatio) != nil {
            s.reviewRatio = defaults.double(forKey: SettingsKey.reviewRatio)
        }
        return s
    }
}
