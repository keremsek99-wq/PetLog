import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: PremiumPlan = .annual
    @State private var isPurchasing = false
    @State private var showSuccess = false

    let premiumManager: PremiumManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    featuresSection
                    planCards
                    ctaButton
                    legalSection
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.03),
                        Color.purple.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Geri Yükle") {
                        premiumManager.restorePurchase()
                        if premiumManager.isPremium {
                            dismiss()
                        }
                    }
                    .font(.subheadline)
                }
            }
            .sensoryFeedback(.success, trigger: showSuccess)
        }
    }

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
                    .font(.system(size: 34))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 24)

            VStack(spacing: 8) {
                Text("Evcil hayvanınızın sağlığını\nveriye dönüştürün.")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("PetLog Premium ile sağlık ve harcamaları\ntek ekranda yönetin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 28)
    }

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(PremiumFeature.allCases, id: \.rawValue) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                        .frame(width: 32, height: 32)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))

                    Text(feature.rawValue)
                        .font(.subheadline)

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 11)

                if feature != PremiumFeature.allCases.last {
                    Divider()
                        .padding(.leading, 66)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private var planCards: some View {
        VStack(spacing: 12) {
            ForEach(PremiumPlan.allCases, id: \.rawValue) { plan in
                planCard(plan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private func planCard(_ plan: PremiumPlan) -> some View {
        let isSelected = selectedPlan == plan
        let isAnnual = plan == .annual

        return Button {
            withAnimation(.snappy(duration: 0.25)) {
                selectedPlan = plan
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.headline)
                        if isAnnual {
                            Text("%30 tasarruf")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }
                    Text(plan.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(plan.price)
                        .font(.title3.weight(.bold))
                    Text(plan.period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedPlan)
    }

    private var ctaButton: some View {
        VStack(spacing: 12) {
            Button {
                purchasePlan()
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("7 Gün Ücretsiz Dene")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 14))
            }
            .disabled(isPurchasing)

            Text("Deneme süresinden sonra \(selectedPlan.monthlyEquivalent)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("İstediğiniz zaman iptal edebilirsiniz.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button("Kullanım Koşulları") {}
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button("Gizlilik Politikası") {}
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 32)
    }

    private func purchasePlan() {
        isPurchasing = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            premiumManager.startTrial()
            premiumManager.purchase(plan: selectedPlan)
            showSuccess = true
            try? await Task.sleep(for: .milliseconds(600))
            dismiss()
        }
    }
}
