import SwiftUI

/// 일상표현 탭: 급수 구분 없이 한 덱으로 학습 (모름 카드 + 새 카드 랜덤 섞기)
struct DailyView: View {
    var body: some View {
        NavigationStack {
            LevelView(level: .daily)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("설정")
                    }
                }
        }
    }
}
