import SwiftUI

struct PremiumBanner: View {
    let premiumManager: PremiumManager
    @State private var showPaywall = false

    var body: some View {
        if !premiumManager.hasFullAccess {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Premium'a Geç")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("AI önerileri, detaylı analizler ve daha fazlası")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [.blue.opacity(0.06), .purple.opacity(0.06)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showPaywall) {
                PetLogPaywallView(premiumManager: premiumManager)
            }
        }
    }
}

struct PremiumLockOverlay: View {
    let premiumManager: PremiumManager
    @State private var showPaywall = false

    var body: some View {
        if !premiumManager.hasFullAccess {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Premium Özellik")
                    .font(.subheadline.weight(.semibold))
                Text("Detaylı analizleri görmek için\nPremium'a geçin.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button {
                    showPaywall = true
                } label: {
                    Text("Premium'u Keşfet")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 14))
            .sheet(isPresented: $showPaywall) {
                PetLogPaywallView(premiumManager: premiumManager)
            }
        }
    }
}
