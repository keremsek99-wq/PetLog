import SwiftUI
import StoreKit

struct PetLogPaywallView: View {
    let premiumManager: PremiumManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: String? = nil
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    headerSection

                    // MARK: - Features
                    featuresSection

                    // MARK: - Plans
                    plansSection

                    // MARK: - Purchase Button
                    purchaseButton

                    // MARK: - Restore
                    restoreButton

                    // MARK: - Legal
                    legalSection
                }
                .padding(24)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color.blue.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Default to yearly
                selectedPlan = PetLogConfig.yearlyProductID
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.15), .purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("PetLog Premium")
                .font(.title.bold())

            Text("Hayvanlarınız en iyisini hak ediyor")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.body)
                        .foregroundStyle(.blue)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    Text(feature.rawValue)
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }

    // MARK: - Plans

    private var plansSection: some View {
        VStack(spacing: 10) {
            if premiumManager.products.isEmpty {
                if premiumManager.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Text("Ürünler yüklenemedi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                    Button("Tekrar Dene") {
                        Task { await premiumManager.loadProducts() }
                    }
                    .font(.subheadline)
                }
            } else {
                ForEach(premiumManager.products, id: \.id) { product in
                    planCard(product)
                }
            }
        }
    }

    private func planCard(_ product: Product) -> some View {
        let isSelected = selectedPlan == product.id
        let isYearly = product.id == PetLogConfig.yearlyProductID

        return Button {
            selectedPlan = product.id
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(planTitle(for: product))
                            .font(.subheadline.weight(.semibold))
                        if isYearly {
                            Text("En Avantajlı")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    Text(planSubtitle(for: product))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.subheadline.weight(.bold))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.06) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task { await purchaseSelected() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Premium'a Geç")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(selectedPlan == nil || isPurchasing || premiumManager.products.isEmpty)
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task {
                isPurchasing = true
                _ = await premiumManager.restorePurchases()
                isPurchasing = false
                if premiumManager.isPremium {
                    dismiss()
                }
            }
        } label: {
            Text("Satın Alımları Geri Yükle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .disabled(isPurchasing)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 4) {
            Text("Ödeme Apple ID hesabınız üzerinden alınır.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text("Abonelikler otomatik yenilenir. Ayarlar'dan iptal edebilirsiniz.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Helpers

    private func purchaseSelected() async {
        guard let planID = selectedPlan,
              let product = premiumManager.products.first(where: { $0.id == planID })
        else { return }

        isPurchasing = true
        let success = await premiumManager.purchase(product)
        isPurchasing = false

        if success {
            dismiss()
        }
    }

    private func planTitle(for product: Product) -> String {
        switch product.id {
        case PetLogConfig.monthlyProductID: return "Aylık"
        case PetLogConfig.yearlyProductID: return "Yıllık"
        case PetLogConfig.lifetimeProductID: return "Ömür Boyu"
        default: return product.displayName
        }
    }

    private func planSubtitle(for product: Product) -> String {
        switch product.id {
        case PetLogConfig.monthlyProductID: return "Her ay yenilenir"
        case PetLogConfig.yearlyProductID: return "2 ay bedava"
        case PetLogConfig.lifetimeProductID: return "Tek seferlik ödeme"
        default: return product.description
        }
    }
}
