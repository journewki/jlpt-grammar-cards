import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.cardsPerSession) private var cardsPerSession = StudySettings().cardsPerSession
    @AppStorage(SettingsKey.reviewRatio) private var reviewRatio = StudySettings().reviewRatio
    @AppStorage(SettingsKey.showMeaning) private var showMeaning = false
    @AppStorage(SettingsKey.showFurigana) private var showFurigana = true
    @AppStorage(SettingsKey.autoPlaySpeech) private var autoPlaySpeech = false
    @AppStorage(SettingsKey.speechRate) private var speechRate = SpeechRate.normal.rawValue

    var body: some View {
        Form {
            Section {
                Picker("한 번에 학습할 카드", selection: $cardsPerSession) {
                    ForEach(StudySettings.sessionSizeOptions, id: \.self) { Text("\($0)장").tag($0) }
                }
                VStack(alignment: .leading) {
                    Text("모름 카드 비율 \(Int((reviewRatio * 100).rounded()))%")
                    Slider(value: $reviewRatio, in: 0...0.8, step: 0.1)
                }
            } header: {
                Text("학습")
            } footer: {
                Text("한 사이클 중 이 비율만큼 예전에 모름으로 표시한 카드가 섞여 나오고, 나머지는 새 카드로 채워져요.")
            }

            Section("카드 표시") {
                Toggle("뜻 항상 보기", isOn: $showMeaning)
                Toggle("후리가나 표시", isOn: $showFurigana)
            }

            Section {
                Toggle("카드가 넘어갈 때 예문 자동 재생", isOn: $autoPlaySpeech)
                Picker("읽기 속도", selection: $speechRate) {
                    ForEach(SpeechRate.allCases) { Text($0.label).tag($0.rawValue) }
                }
                Button("예문 소리 들어 보기") {
                    Speaker.shared.speak(markup: "{今日|きょう}はいい{天気|てんき}ですね。")
                }
            } header: {
                Text("소리")
            } footer: {
                Text("더 자연스러운 음성은 iPhone 설정 > 손쉬운 사용 > 읽기 및 말하기 > 음성 > 일본어에서 '향상된 음질' 음성을 내려받으면 자동으로 사용돼요.")
            }

            Section("정보") {
                ForEach(JLPTLevel.allCases) { level in
                    LabeledContent(level.rawValue, value: "\(ContentStore.cards(level).count)개")
                }
            }
        }
        .navigationTitle("설정")
    }
}
