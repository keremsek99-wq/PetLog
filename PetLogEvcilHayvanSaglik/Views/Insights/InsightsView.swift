import SwiftUI

struct InsightsView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var insights: [Insight] = []
    @State private var isRefreshing = false
    @State private var showPaywall = false

    private var pet: Pet? { store.selectedPet }

    private let freeInsightLimit = 2

    var body: some View {
        NavigationStack {
            Group {
                if let pet {
                    insightsContent(pet)
                } else {
                    EmptyStateView(title: "Hayvan Seçilmedi", message: "Kişiselleştirilmiş öneriler almak için bir hayvan ekleyin.", icon: "lightbulb")
                }
            }
            .navigationTitle("Öneriler")
            .sheet(isPresented: $showPaywall) {
                PaywallView(premiumManager: premiumManager)
            }
        }
    }

    private func insightsContent(_ pet: Pet) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                insightHeader

                PremiumBanner(premiumManager: premiumManager)

                if insights.isEmpty {
                    EmptyStateView(
                        title: "Öneriler Hazırlanıyor",
                        message: "\(pet.name) için daha iyi öneriler üretmek adına sağlık verisi ve harcamalarınızı kaydetmeye devam edin.",
                        icon: "chart.bar.doc.horizontal"
                    )
                    .frame(height: 300)
                } else {
                    let urgent = insights.filter { $0.severity == .urgent }
                    let warnings = insights.filter { $0.severity == .warning }
                    let info = insights.filter { $0.severity == .info }

                    if !urgent.isEmpty {
                        insightGroup(title: "Acil", severity: .urgent, items: urgent)
                    }
                    if !warnings.isEmpty {
                        insightGroup(title: "Dikkat", severity: .warning, items: warnings)
                    }
                    if !info.isEmpty {
                        insightGroup(title: "Bilgi", severity: .info, items: info)
                    }
                }

                disclaimerView
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await refreshInsights()
        }
        .task {
            refreshInsightsSync()
        }
    }

    private var insightHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile.fill")
                .font(.title2)
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Yapay Zeka Önerileri")
                        .font(.headline)
                    if premiumManager.hasFullAccess {
                        Text("PRO")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
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
                Text(premiumManager.hasFullAccess
                     ? "Tüm önerilere erişiminiz var"
                     : "Sağlık ve harcama verilerinize dayalı analizler")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.purple.opacity(0.08))
        .clipShape(.rect(cornerRadius: 14))
    }

    private func insightGroup(title: String, severity: InsightSeverity, items: [Insight]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle()
                    .fill(PetOSColors.severityColor(severity))
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetOSColors.severityColor(severity))
            }

            ForEach(Array(items.enumerated()), id: \.element.id) { index, insight in
                let globalIndex = globalInsightIndex(for: insight)
                let isLocked = !premiumManager.hasFullAccess && globalIndex >= freeInsightLimit

                InsightCard(
                    insight: insight,
                    isLocked: isLocked,
                    onUnlock: { showPaywall = true }
                )
            }
        }
    }

    private func globalInsightIndex(for insight: Insight) -> Int {
        insights.firstIndex(where: { $0.id == insight.id }) ?? 0
    }

    private var disclaimerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Öneriler tıbbi tavsiye niteliği taşımaz. Sağlık endişeleriniz için mutlaka veterinerinize danışın.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 10))
    }

    private func refreshInsightsSync() {
        guard let pet else { return }
        insights = store.generateInsights(for: pet)
    }

    private func refreshInsights() async {
        isRefreshing = true
        try? await Task.sleep(for: .milliseconds(500))
        refreshInsightsSync()
        isRefreshing = false
    }
}

struct InsightCard: View {
    let insight: Insight
    var isLocked: Bool = false
    var onUnlock: (() -> Void)?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: insight.type.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetOSColors.severityColor(insight.severity))
                    .frame(width: 32, height: 32)
                    .background(PetOSColors.severityColor(insight.severity).opacity(0.12))
                    .clipShape(.rect(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline.weight(.semibold))
                    Text(insight.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        withAnimation(.snappy) { isExpanded.toggle() }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
            }

            if isLocked {
                VStack(spacing: 10) {
                    Text(insight.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .blur(radius: 4)

                    Button {
                        onUnlock?()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                            Text("Detayları Gör")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            } else {
                Text(insight.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if isExpanded && !insight.recommendedAction.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(insight.recommendedAction)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
        .sensoryFeedback(.selection, trigger: isExpanded)
    }
}
