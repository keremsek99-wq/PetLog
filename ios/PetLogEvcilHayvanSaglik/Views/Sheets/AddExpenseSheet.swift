import SwiftUI

struct AddExpenseSheet: View {
    let store: PetStore
    let pet: Pet

    @Environment(\.dismiss) private var dismiss
    @State private var category: ExpenseCategory = .food
    @State private var amountString: String = ""
    @State private var date: Date = Date()
    @State private var merchant: String = ""
    @State private var notes: String = ""
    @State private var isRecurring: Bool = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Emoji header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [PetOSColors.financeOrange.opacity(0.2), PetOSColors.financeOrange.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Text(category.emoji)
                                .font(.largeTitle)
                        }
                        Text(pet.name + " için harcama")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Amount input
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("₺")
                                .font(.title2.weight(.medium))
                                .foregroundStyle(.secondary)
                            TextField("0,00", text: $amountString)
                                .keyboardType(.decimalPad)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                    // Category picker as chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kategori")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                Button {
                                    withAnimation(.spring(duration: 0.2)) {
                                        category = cat
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(cat.emoji)
                                            .font(.title3)
                                        Text(cat.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(category == cat ? .white : .primary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(category == cat
                                                  ? PetOSColors.categoryColor(cat)
                                                  : Color(.secondarySystemGroupedBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                                .sensoryFeedback(.selection, trigger: category)
                            }
                        }
                    }

                    // Details
                    VStack(spacing: 12) {
                        DatePicker("Tarih", selection: $date, displayedComponents: .date)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("Mağaza / Veteriner", text: $merchant)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("Notlar", text: $notes, axis: .vertical)
                            .lineLimit(2)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        Toggle(isOn: $isRecurring) {
                            HStack(spacing: 8) {
                                Image(systemName: "repeat")
                                    .foregroundStyle(.blue)
                                Text("Düzenli Harcama")
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Harcama Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled((Double(amountString.replacingOccurrences(of: ",", with: ".")) ?? 0) <= 0)
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
    }

    private func save() {
        guard let amount = Double(amountString.replacingOccurrences(of: ",", with: ".")), amount > 0 else { return }
        store.addExpense(to: pet, category: category, amount: amount, date: date, merchant: merchant, notes: notes, isRecurring: isRecurring)
        saved = true
        dismiss()
    }
}

// MARK: - ExpenseCategory emoji extension

private extension ExpenseCategory {
    var emoji: String {
        switch self {
        case .food: return "🍖"
        case .veterinary: return "🩺"
        case .medication: return "💊"
        case .grooming: return "✂️"
        case .supplies: return "🛒"
        case .insurance: return "🛡️"
        case .training: return "🎓"
        case .boarding: return "🏠"
        case .other: return "📦"
        }
    }
}
