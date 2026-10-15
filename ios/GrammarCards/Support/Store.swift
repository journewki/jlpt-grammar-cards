import Foundation
import Observation
import StoreKit

/// 평생 이용권(비소모성 인앱 구매) 관리. StoreKit 2.
@MainActor
@Observable
final class Store {
    /// App Store Connect 에 등록할 상품 ID (Products.storekit 과 같아야 함)
    static let lifetimeID = "com.journewki.grammarcards.lifetime"

    private(set) var product: Product?
    private(set) var isUnlocked: Bool
    private(set) var isPurchasing = false
    /// 평생 이용권 구매일 (구매 기록에서 읽음)
    private(set) var purchaseDate: Date?
    var message: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        // 오프라인으로 시작해도 바로 열리도록 마지막 확인 결과를 기억해 둔다
        isUnlocked = UserDefaults.standard.bool(forKey: SettingsKey.unlocked)
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await refresh() }
    }

    /// 이 급수에서 학습을 시작(또는 무료 체험을 이어서)할 수 있는지
    func studyAccess(level: JLPTLevel, freeCycleUsed: Bool) -> StudyAccess {
        if isUnlocked { return .allowed }
        if let trial = FreeTrial.load(), !trial.isFinished {
            return trial.level == level ? .allowed : .trialInProgress(trial.level)
        }
        return freeCycleUsed ? .locked : .allowed
    }

    /// 상품 정보와 구매 상태 새로고침
    func refresh() async {
        if product == nil {
            product = try? await Product.products(for: [Self.lifetimeID]).first
        }
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.lifetimeID,
               transaction.revocationDate == nil {
                owned = true
                purchaseDate = transaction.purchaseDate
            }
        }
        setUnlocked(owned)
    }

    func purchase() async {
        guard let product else {
            message = "상품 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
            await refresh()
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
            case .pending:
                message = "결제 승인을 기다리고 있어요. 승인되면 자동으로 열려요."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "결제에 실패했어요. (\(error.localizedDescription))"
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refresh()
        message = isUnlocked ? "구매 내역을 복원했어요." : "복원할 구매 내역이 없어요."
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.lifetimeID {
            purchaseDate = transaction.purchaseDate
            setUnlocked(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }

    private func setUnlocked(_ value: Bool) {
        if value { FreeTrial.clear() }
        isUnlocked = value
        UserDefaults.standard.set(value, forKey: SettingsKey.unlocked)
    }
}
