import SwiftUI
#if canImport(RevenueCat)
import RevenueCat
#endif
#if canImport(RevenueCatUI)
import RevenueCatUI
#endif

struct PetLogPaywallView: View {
    let premiumManager: PremiumManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        #if canImport(RevenueCatUI)
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
        #else
        fallbackPaywallView
        #endif
    }

    #if !canImport(RevenueCatUI)
    private var fallbackPaywallView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("PetLog Premium")
                    .font(.title.weight(.bold))

                Text("Tüm özelliklerin kilidini açın")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(PremiumFeature.allCases, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: feature.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            Text(feature.rawValue)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.vertical)

                Text("RevenueCat SDK kurulumu gerekli")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    #endif
}
