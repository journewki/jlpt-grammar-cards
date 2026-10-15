import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.cardsPerSession) private var cardsPerSession = StudySettings().cardsPerSession
    @AppStorage(SettingsKey.reviewRatio) private var reviewRatio = StudySettings().reviewRatio
    @AppStorage(SettingsKey.showMeaning) private var showMeaning = false
    @AppStorage(SettingsKey.showFurigana) private var showFurigana = true

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

            Section("정보") {
                ForEach(JLPTLevel.allCases) { level in
                    LabeledContent(level.rawValue, value: "\(ContentStore.cards(level).count)개")
                }
            }
        }
        .navigationTitle("설정")
    }
}
