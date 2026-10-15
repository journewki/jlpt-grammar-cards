import SwiftData
import SwiftUI

@main
struct GrammarCardsApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [CardProgress.self, ReviewLog.self])
    }
}
