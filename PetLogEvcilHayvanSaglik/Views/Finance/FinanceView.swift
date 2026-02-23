import SwiftUI
import Charts

struct FinanceView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var showAddExpense = false
    @State private var showPaywall = false
    @State private var selectedTimeframe: FinanceTimeframe = .month

    private var pet: Pet? { store.selectedPet }

    var body: some View {
        NavigationStack {
            Group {
                if let pet {
                    financeContent(pet)
                } else {
                    EmptyStateView(title: "Hayvan Seçilmedi", message: "Finans takibi için ana ekrandan bir hayvan ekleyin.", icon: "turkishlirasign.circle")
                }
            }
            .navigationTitle("Finans")
            .toolbar {
                if pet != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddExpense = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                if let pet { AddExpenseSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(premiumManager: premiumManager)
            }
        }
    }

    private func financeContent(_ pet: Pet) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                spendingSummary(pet)
                categoryBreakdown(pet)
                annualProjection(pet)
                recentExpenses(pet)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func spendingSummary(_ pet: Pet) -> some View {
        VStack(spacing: 16) {
            Picker("Dönem", selection: $selectedTimeframe) {
                ForEach(FinanceTimeframe.allCases, id: \.self) { tf in
                    Text(tf.rawValue).tag(tf)
                }
            }
            .pickerStyle(.segmented)

            let amount = selectedTimeframe == .month ? store.monthlySpending(for: pet) : store.annualSpending(for: pet)

            VStack(spacing: 4) {
                Text(amount.formatted(.currency(code: "TRY")))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(selectedTimeframe == .month ? "bu ay harcandı" : "bu yıl harcandı")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }

    private func categoryBreakdown(_ pet: Pet) -> some View {
        let categories = store.spendingByCategory(for: pet)
        let total = categories.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kategoriye Göre")

            if categories.isEmpty {
                Text("Bu ay harcama yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Chart(categories, id: \.category) { item in
                    SectorMark(
                        angle: .value("Tutar", item.amount),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(PetOSColors.categoryColor(item.category))
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .padding(.vertical, 8)

                ForEach(categories, id: \.category) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(PetOSColors.categoryColor(item.category))
                            .frame(width: 10, height: 10)
                        Image(systemName: item.category.icon)
                            .font(.subheadline)
                            .foregroundStyle(PetOSColors.categoryColor(item.category))
                            .frame(width: 24)
                        Text(item.category.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text(item.amount.formatted(.currency(code: "TRY")))
                            .font(.subheadline.weight(.semibold))
                        if total > 0 {
                            Text("%\(Int(item.amount / total * 100))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }

    private func annualProjection(_ pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Yıllık Projeksiyon")

            if premiumManager.hasFullAccess {
                let monthly = store.monthlySpending(for: pet)
                let projected = monthly * 12
                let annual = store.annualSpending(for: pet)

                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tahmini Yıllık")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(projected.formatted(.currency(code: "TRY")))
                                .font(.title3.weight(.bold))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Yıl İçi Toplam")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(annual.formatted(.currency(code: "TRY")))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if projected > 0 {
                        let progress = min(annual / projected, 1.0)
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: progress)
                                .tint(.orange)
                            Text("%\(Int(progress * 100)) tamamlandı")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yıllık harcama projeksiyonu")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text("Premium ile tahmini yıllık giderlerinizi görün")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(14)
                    .background(Color.blue.opacity(0.06))
                    .clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }

    private func recentExpenses(_ pet: Pet) -> some View {
        let sorted = pet.expenses.sorted { $0.date > $1.date }.prefix(20)

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Son Harcamalar")

            if sorted.isEmpty {
                EmptyStateView(title: "Harcama Yok", message: "Evcil hayvan bakım masraflarınızı takip etmeye başlayın.", icon: "turkishlirasign.circle", actionTitle: "Harcama Ekle") {
                    showAddExpense = true
                }
                .frame(height: 200)
            } else {
                ForEach(Array(sorted), id: \.id) { expense in
                    ExpenseRow(expense: expense) {
                        store.deleteExpense(expense)
                    }
                }
            }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expense.category.icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PetOSColors.categoryColor(expense.category))
                .frame(width: 36, height: 36)
                .background(PetOSColors.categoryColor(expense.category).opacity(0.12))
                .clipShape(.rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category.rawValue)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                    if !expense.merchant.isEmpty {
                        Text("·")
                        Text(expense.merchant)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount.formatted(.currency(code: "TRY")))
                    .font(.subheadline.weight(.semibold))
                if expense.isRecurring {
                    Text("Düzenli")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .contextMenu {
            Button("Sil", role: .destructive, action: onDelete)
        }
    }
}

nonisolated enum FinanceTimeframe: String, CaseIterable, Sendable {
    case month = "Aylık"
    case year = "Yıllık"
}
