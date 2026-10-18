import SwiftData
import SwiftUI

@main
struct GrammarCardsApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            Group {
                #if PERSONAL_UNLOCK
                // 개인용 빌드: 문법 + 일상표현 탭 (일상표현은 검수 후 출시용에도 공개 예정)
                TabView {
                    HomeView()
                        .tabItem { Label("문법", systemImage: "book.closed") }
                    DailyView()
                        .tabItem { Label("일상표현", systemImage: "text.bubble") }
                }
                #else
                HomeView()
                #endif
            }
            .environment(store)
        }
        .modelContainer(for: [CardProgress.self, ReviewLog.self])
    }
}
