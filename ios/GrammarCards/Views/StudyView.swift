import SwiftData
import SwiftUI

/// 한 사이클 학습 화면. 오른쪽으로 밀면 "알고 있음", 왼쪽으로 밀면 "모름".
struct StudyView: View {
    enum Mode {
        /// 모름 카드 + 새 카드 섞기
        case mixed
        /// 모름 카드만
        case unknownOnly
    }

    let level: JLPTLevel
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.showMeaning) private var showMeaning = false
    @AppStorage(SettingsKey.showFurigana) private var showFurigana = true
    @AppStorage(SettingsKey.autoPlaySpeech) private var autoPlaySpeech = false

    @State private var session: StudySession?
    @State private var revealed = false
    @State private var drag: CGSize = .zero

    private let swipeThreshold: CGFloat = 110

    var body: some View {
        NavigationStack {
            Group {
                if let session, !session.isFinished, let card = session.current {
                    studyBody(session: session, card: card)
                } else if let session {
                    SessionResultView(session: session,
                                      onRestart: start,
                                      onClose: { dismiss() })
                } else {
                    ProgressView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("닫기")
                }
                ToolbarItem(placement: .principal) {
                    if let session, !session.isFinished {
                        Text(session.progressText).font(.headline).monospacedDigit()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showMeaning.toggle() } label: {
                        Image(systemName: showMeaning ? "eye" : "eye.slash")
                    }
                    .accessibilityLabel(showMeaning ? "뜻 항상 보기 끄기" : "뜻 항상 보기 켜기")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { if session == nil { start() } }
        .onDisappear { Speaker.shared.stop() }
    }

    @ViewBuilder
    private func studyBody(session: StudySession, card: Grammar) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(session.index), total: Double(max(session.cards.count, 1)))

            CardFaceView(grammar: card, level: level,
                         showMeaning: showMeaning || revealed,
                         showFurigana: showFurigana)
                .overlay(alignment: .top) { swipeStamp }
                .offset(x: drag.width, y: drag.height * 0.2)
                .rotationEffect(.degrees(Double(drag.width / 25)))
                .gesture(
                    DragGesture()
                        .onChanged { drag = $0.translation }
                        .onEnded { value in
                            if value.translation.width > swipeThreshold {
                                answer(known: true)
                            } else if value.translation.width < -swipeThreshold {
                                answer(known: false)
                            } else {
                                withAnimation(.spring) { drag = .zero }
                            }
                        }
                )
                .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { revealed.toggle() } }
                .id(card.no)
                .task(id: card.no) {
                    if autoPlaySpeech { Speaker.shared.speak(markup: card.example.sentenceJa) }
                }
                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity),
                                        removal: .opacity))

            HStack(spacing: 12) {
                Button { answer(known: false) } label: {
                    Label("모름", systemImage: "xmark").frame(maxWidth: .infinity)
                }
                .tint(.red)
                Button { answer(known: true) } label: {
                    Label("알고 있음", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .tint(.green)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    /// 밀고 있는 방향에 따라 카드 위에 뜨는 표시
    @ViewBuilder
    private var swipeStamp: some View {
        let progress = min(abs(drag.width) / swipeThreshold, 1)
        if drag.width != 0 {
            let known = drag.width > 0
            let color: Color = known ? .green : .red
            Text(known ? "알고 있음" : "모름")
                .font(.title2.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 3))
                .opacity(progress)
                .padding(.top, 70)
        }
    }

    private func start() {
        let settings = StudySettings.current()
        let all = ContentStore.cards(level)
        let progress = ProgressRepository.snapshots(in: context)
        let pool: [Grammar]
        var effective = settings
        switch mode {
        case .mixed:
            pool = all
        case .unknownOnly:
            pool = all.filter { progress[$0.no]?.status == .unknown }
            effective.reviewRatio = 1
        }
        revealed = false
        drag = .zero
        session = StudySession(level: level, cards: SessionBuilder.build(grammar: pool, progress: progress, settings: effective))
    }

    private func answer(known: Bool) {
        guard let card = session?.current else { return }
        ProgressRepository.record(card, level: level, known: known, in: context)
        withAnimation(.easeOut(duration: 0.2)) {
            session?.answer(known: known)
            revealed = false
            drag = .zero
        }
    }
}

/// 사이클이 끝났을 때 결과
struct SessionResultView: View {
    let session: StudySession
    let onRestart: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: session.cards.isEmpty ? "tray" : "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(session.cards.isEmpty ? Color.secondary : Color.green)
            if session.cards.isEmpty {
                Text("학습할 카드가 없어요").font(.title2.bold())
            } else {
                Text("이번 사이클 완료!").font(.title2.bold())
                HStack(spacing: 32) {
                    stat("알고 있음", session.knownNos.count, .green)
                    stat("모름", session.unknownNos.count, .red)
                }
                if !session.unknownNos.isEmpty {
                    Text("모름 카드는 다음 사이클에 새 카드와 섞여서 다시 나와요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            VStack(spacing: 12) {
                if !session.cards.isEmpty {
                    Button(action: onRestart) {
                        Text("다음 사이클").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button(action: onClose) {
                    Text("닫기").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .padding()
    }

    private func stat(_ title: String, _ value: Int, _ color: Color) -> some View {
        VStack {
            Text("\(value)").font(.largeTitle.bold()).foregroundStyle(color)
            Text(title).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
