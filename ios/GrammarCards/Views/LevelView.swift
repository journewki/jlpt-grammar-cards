import SwiftData
import SwiftUI

/// 급수 화면: 학습 시작, 모름 복습, 카드 목록
struct LevelView: View {
    let level: JLPTLevel

    @Environment(\.modelContext) private var context
    @Query private var progress: [CardProgress]
    @AppStorage(SettingsKey.cardsPerSession) private var cardsPerSession = StudySettings().cardsPerSession
    @AppStorage(SettingsKey.freeCycleUsed) private var freeCycleUsed = false
    @Environment(Store.self) private var store
    @State private var showPaywall = false
    @State private var trialElsewhere: JLPTLevel?

    @State private var studyMode: StudyMode?
    @State private var filter: Filter = .all
    @State private var selected: Grammar?
    @State private var confirmReset = false

    private struct StudyMode: Identifiable {
        let mode: StudyView.Mode
        var id: String { "\(mode)" }
    }

    enum Filter: String, CaseIterable, Identifiable {
        case all = "전체", unknown = "모름", known = "알고 있음", fresh = "새 카드"
        var id: String { rawValue }
    }

    private var statusByNo: [Int: CardStatus] {
        Dictionary(progress.filter { $0.levelRaw == level.rawValue }.map { ($0.grammarNo, $0.status) },
                   uniquingKeysWith: { a, _ in a })
    }

    var body: some View {
        let stats = LevelStats(level: level, progress: progress)
        let statuses = statusByNo
        let lastSeen = Dictionary(progress.compactMap { p in p.lastReviewedAt.map { (p.grammarNo, $0) } },
                                  uniquingKeysWith: { a, _ in a })
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    StatsBar(stats: stats)
                    HStack {
                        statBox("알고 있음", stats.known, .green)
                        statBox("모름", stats.unknown, .red)
                        statBox("새 카드", stats.fresh, .gray)
                    }
                }
                .padding(.vertical, 6)

                Button {
                    open(.mixed)
                } label: {
                    Label(resumeLabel ?? "학습 시작 (\(min(cardsPerSession, stats.total))장)", systemImage: "play.fill")
                        .font(.headline)
                }
                Button {
                    open(.unknownOnly)
                } label: {
                    Label("모름 카드만 복습 (\(min(cardsPerSession, stats.unknown))장)", systemImage: "arrow.counterclockwise")
                }
                .disabled(stats.unknown == 0)
            }

            Section {
                Picker("보기", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                ForEach(filtered(statuses)) { g in
                    Button { selected = g } label: {
                        CardRow(grammar: g, status: statuses[g.no] ?? .new, lastSeen: lastSeen[g.no])
                    }
                    .tint(.primary)
                }
            }
        }
        .navigationTitle(level.displayName)
        .toolbar {
            Menu {
                Button("\(level.displayName) 학습 기록 초기화", role: .destructive) { confirmReset = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .confirmationDialog("\(level.displayName)의 알고 있음/모름 기록을 모두 지울까요?",
                            isPresented: $confirmReset, titleVisibility: .visible) {
            Button("초기화", role: .destructive) { ProgressRepository.reset(level, in: context) }
        }
        .fullScreenCover(item: $studyMode) { StudyView(level: level, mode: $0.mode) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("무료 체험 진행 중",
               isPresented: Binding(get: { trialElsewhere != nil }, set: { if !$0 { trialElsewhere = nil } })) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("\(trialElsewhere?.displayName ?? "")에서 시작한 무료 체험 사이클을 먼저 끝내 주세요. 평생 이용권이 있으면 모든 급수를 자유롭게 학습할 수 있어요.")
        }
        .sheet(item: $selected) { g in
            CardFaceView(grammar: g, level: level, showMeaning: true, showHistory: false)
                .padding()
                .presentationDetents([.medium, .large])
        }
    }

    /// 이 급수에서 무료 체험이 진행 중이면 "무료 체험 이어하기 (7 / 20)"
    private var resumeLabel: String? {
        guard !store.isUnlocked, let trial = FreeTrial.load(), trial.level == level, !trial.isFinished else { return nil }
        return "무료 체험 이어하기 (\(trial.knownNos.count + trial.unknownNos.count) / \(trial.cardNos.count))"
    }

    /// 무료 1사이클을 다 썼으면 결제 화면, 아니면 학습 시작
    private func open(_ mode: StudyView.Mode) {
        switch store.studyAccess(level: level, freeCycleUsed: freeCycleUsed) {
        case .allowed: studyMode = StudyMode(mode: mode)
        case .trialInProgress(let other): trialElsewhere = other
        case .locked: showPaywall = true
        }
    }

    private func filtered(_ statuses: [Int: CardStatus]) -> [Grammar] {
        let all = ContentStore.cards(level)
        switch filter {
        case .all: return all
        case .unknown: return all.filter { statuses[$0.no] == .unknown }
        case .known: return all.filter { statuses[$0.no] == .known }
        case .fresh: return all.filter { (statuses[$0.no] ?? .new) == .new }
        }
    }

    private func statBox(_ title: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.title3.bold()).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CardRow: View {
    let grammar: Grammar
    let status: CardStatus
    let lastSeen: Date?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(grammar.expression).font(.body.weight(.medium))
                Text(grammar.meaningKo).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if let lastSeen {
                Text(RelativeTime.korean(since: lastSeen)).font(.caption2).foregroundStyle(.tertiary)
            }
            switch status {
            case .known: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .unknown: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            case .new: EmptyView()
            }
        }
    }
}
