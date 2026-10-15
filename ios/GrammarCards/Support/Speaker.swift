import AVFoundation

/// 읽기 속도 선택지 (AVSpeechUtterance.rate 값)
enum SpeechRate: Double, CaseIterable, Identifiable {
    case slow = 0.38, normal = 0.47, fast = 0.55

    var id: Double { rawValue }
    var label: String {
        switch self {
        case .slow: return "느리게"
        case .normal: return "보통"
        case .fast: return "빠르게"
        }
    }
}

/// iOS 내장 일본어 음성(TTS)으로 예문을 읽어 준다
@MainActor
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()

    /// 설치된 일본어 음성 중 가장 품질이 좋은 것 (설정 > 손쉬운 사용 > 읽기 및 말하기 > 음성 에서 추가 가능)
    private lazy var voice: AVSpeechSynthesisVoice? = {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == "ja-JP" }
            .max { $0.quality.rawValue < $1.quality.rawValue }
            ?? AVSpeechSynthesisVoice(language: "ja-JP")
    }()

    /// 루비 마크업 예문을 후리가나 읽기로 읽는다 (한자를 잘못 읽는 것 방지)
    func speak(markup: String) {
        speak(Ruby.spokenText(markup))
    }

    func speak(_ text: String) {
        // 무음 모드에서도 소리가 나도록
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        let saved = UserDefaults.standard.object(forKey: SettingsKey.speechRate) as? Double
        utterance.rate = Float(saved ?? SpeechRate.normal.rawValue)
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
