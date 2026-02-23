import SwiftUI
import RevenueCat
import RevenueCatUI

struct PetLogPaywallView: View {
    let premiumManager: PremiumManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PaywallView()
            .onPurchaseCompleted { customerInfo in
                Task { @MainActor in
                    await premiumManager.checkSubscriptionStatus()
                }
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                Task { @MainActor in
                    await premiumManager.checkSubscriptionStatus()
                }
                dismiss()
            }
    }
}
