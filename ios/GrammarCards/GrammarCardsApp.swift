import SwiftData
import SwiftUI

@main
struct GrammarCardsApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
        }
        .modelContainer(for: [CardProgress.self, ReviewLog.self])
    }
}
