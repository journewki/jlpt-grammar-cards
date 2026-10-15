import SwiftUI

/// 평생 이용권 구매 화면
struct PaywallView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// 무료 사이클을 다 쓰고 열린 경우 "무료 체험이 끝났어요" 표시
    var trialEnded = true

    private let features: [(icon: String, title: String, detail: String)] = [
        ("books.vertical.fill", "N5~N1 문법 580개 전부", "기초부터 N1 문장체 표현까지 한 앱에서"),
        ("infinity", "학습 사이클 무제한", "하루에 몇 번이든 원하는 만큼"),
        ("arrow.triangle.2.circlepath", "모름 카드 자동 반복 복습", "헷갈린 문법만 골라서 외울 때까지"),
        ("speaker.wave.2.fill", "일본어 예문 음성 듣기", "후리가나 읽기 그대로 정확한 발음으로"),
        ("checkmark.seal.fill", "한 번 결제로 평생", "구독 없음, 추가 결제 없음"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(features, id: \.title) { f in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: f.icon)
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.title).font(.headline)
                                    Text(f.detail).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))

                    Text("학원 한 달 수강료보다 훨씬 저렴하게,\n문법 복습은 이 앱 하나로.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom) { purchaseBar }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("닫기")
                }
            }
            .alert("알림", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(store.message ?? "")
            }
            .onChange(of: store.isUnlocked) { _, unlocked in
                if unlocked { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)
            if trialEnded {
                Text("무료 체험이 끝났어요")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("밥 한 끼 값으로\n평생 무제한")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("JLPT N5~N1 필수 문법 580개를 한 번에 정복하세요")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var purchaseBar: some View {
        VStack(spacing: 10) {
            Button {
                Task { await store.purchase() }
            } label: {
                Group {
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("\(store.product?.displayPrice ?? "₩9,900") · 평생 이용권 구매")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.isPurchasing)

            HStack(spacing: 16) {
                Button("구매 복원") { Task { await store.restore() } }
                Text("·").foregroundStyle(.tertiary)
                Text("1회 결제 · 자동 갱신 없음").foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
        .padding()
        .background(.bar)
    }
}

#Preview {
    PaywallView().environment(Store())
}
