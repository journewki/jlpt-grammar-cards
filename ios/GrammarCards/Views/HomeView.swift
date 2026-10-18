import SwiftData
import SwiftUI

/// 급수별 진도 집계
struct LevelStats {
    let total: Int
    let known: Int
    let unknown: Int
    var fresh: Int { max(total - known - unknown, 0) }

    init(level: JLPTLevel, progress: [CardProgress]) {
        let mine = progress.filter { $0.levelRaw == level.rawValue }
        total = ContentStore.cards(level).count
        known = mine.filter { $0.status == .known }.count
        unknown = mine.filter { $0.status == .unknown }.count
    }
}

struct HomeView: View {
    @Query private var progress: [CardProgress]
    @Environment(Store.self) private var store
    @AppStorage(SettingsKey.freeCycleUsed) private var freeCycleUsed = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                if !store.isUnlocked {
                    Section {
                        Button { showPaywall = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill").foregroundStyle(.yellow).font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(freeCycleUsed ? "평생 이용권으로 계속 학습하기" : "무료 체험: 1사이클 학습 가능")
                                        .font(.headline)
                                    Text("단돈 \(store.product?.displayPrice ?? "₩15,900")으로 580개 문법 평생 무제한")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }
                Section {
                    ForEach(JLPTLevel.grammarLevels) { level in
                        NavigationLink(value: level) {
                            LevelRow(level: level, stats: LevelStats(level: level, progress: progress))
                        }
                    }
                } footer: {
                    Text("모름으로 표시한 문법은 다음 학습 때 새 문법과 섞여서 다시 나와요.")
                }
            }
            .navigationTitle("JLPT 문법 카드")
            .navigationDestination(for: JLPTLevel.self) { LevelView(level: $0) }
            .sheet(isPresented: $showPaywall) { PaywallView(trialEnded: freeCycleUsed) }
            .toolbar {
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

private struct LevelRow: View {
    let level: JLPTLevel
    let stats: LevelStats

    var body: some View {
        HStack(spacing: 16) {
            Text(level.rawValue)
                .font(.title2.bold())
                .frame(width: 52, height: 52)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(stats.total)개 문법").font(.headline)
                StatsBar(stats: stats)
                HStack(spacing: 10) {
                    legend("알고 있음 \(stats.known)", .green)
                    legend("모름 \(stats.unknown)", .red)
                    legend("새 카드 \(stats.fresh)", .gray)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func legend(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
        }
    }
}

/// 알고 있음 / 모름 / 새 카드 비율 막대
struct StatsBar: View {
    let stats: LevelStats

    var body: some View {
        GeometryReader { geo in
            let total = CGFloat(max(stats.total, 1))
            HStack(spacing: 0) {
                Color.green.frame(width: geo.size.width * CGFloat(stats.known) / total)
                Color.red.frame(width: geo.size.width * CGFloat(stats.unknown) / total)
                Color.gray.opacity(0.25)
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
    }
}
