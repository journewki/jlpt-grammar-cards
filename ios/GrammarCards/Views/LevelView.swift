import SwiftData
import SwiftUI

/// 급수 화면: 학습 시작, 모름 복습, 카드 목록
struct LevelView: View {
    let level: JLPTLevel

    @Environment(\.modelContext) private var context
    @Query private var progress: [CardProgress]
    @AppStorage(SettingsKey.cardsPerSession) private var cardsPerSession = StudySettings().cardsPerSession

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
                    studyMode = StudyMode(mode: .mixed)
                } label: {
                    Label("학습 시작 (\(min(cardsPerSession, stats.total))장)", systemImage: "play.fill")
                        .font(.headline)
                }
                Button {
                    studyMode = StudyMode(mode: .unknownOnly)
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
                        CardRow(grammar: g, status: statuses[g.no] ?? .new)
                    }
                    .tint(.primary)
                }
            }
        }
        .navigationTitle(level.rawValue)
        .toolbar {
            Menu {
                Button("\(level.rawValue) 학습 기록 초기화", role: .destructive) { confirmReset = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .confirmationDialog("\(level.rawValue)의 알고 있음/모름 기록을 모두 지울까요?",
                            isPresented: $confirmReset, titleVisibility: .visible) {
            Button("초기화", role: .destructive) { ProgressRepository.reset(level, in: context) }
        }
        .fullScreenCover(item: $studyMode) { StudyView(level: level, mode: $0.mode) }
        .sheet(item: $selected) { g in
            CardFaceView(grammar: g, level: level, showMeaning: true)
                .padding()
                .presentationDetents([.medium, .large])
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(grammar.expression).font(.body.weight(.medium))
                Text(grammar.meaningKo).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            switch status {
            case .known: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .unknown: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            case .new: EmptyView()
            }
        }
    }
}
