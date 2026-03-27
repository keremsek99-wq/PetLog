import SwiftUI
import SwiftData

struct AddFeedingSheet: View {
    let store: PetStore
    @Environment(\.dismiss) private var dismiss
    @State private var mealType: MealType = .breakfast
    @State private var portionGrams: Double = 100
    @State private var portionString: String = "100"
    @State private var foodBrand = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var saved = false

    private var pet: Pet? { store.selectedPet }

    private var mealEmoji: String {
        switch mealType {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snack: return "🍖"
        case .water: return "💧"
        }
    }

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
                                        colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Text(mealEmoji)
                                .font(.largeTitle)
                        }
                        .animation(.spring(duration: 0.3), value: mealType)

                        if let pet {
                            Text("\(pet.name) beslenmesi")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)

                    // Meal type chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Öğün")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        HStack(spacing: 8) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                Button {
                                    withAnimation(.spring(duration: 0.2)) {
                                        mealType = type
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.subheadline)
                                            .foregroundStyle(mealType == type ? .white : .orange)
                                        Text(type.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(mealType == type ? .white : .primary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(mealType == type
                                                  ? Color.orange
                                                  : Color(.secondarySystemGroupedBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .sensoryFeedback(.selection, trigger: mealType)
                    }

                    // Portion
                    VStack(spacing: 8) {
                        Text(mealType == .water ? "Su Miktarı" : "Porsiyon")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            TextField("0", text: $portionString)
                                .keyboardType(.decimalPad)
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .multilineTextAlignment(.center)
                                .onChange(of: portionString) { _, newVal in
                                    portionGrams = Double(newVal.replacingOccurrences(of: ",", with: ".")) ?? 0
                                }
                            Text(mealType == .water ? "ml" : "g")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }

                    // Food brand (not for water)
                    if mealType != .water {
                        TextField("Mama markası", text: $foodBrand)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    // Date & Notes
                    VStack(spacing: 12) {
                        DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("Opsiyonel not...", text: $notes, axis: .vertical)
                            .lineLimit(3)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Beslenme Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
    }

    private func save() {
        guard let pet = store.selectedPet else { return }
        store.addFeedingLog(to: pet, mealType: mealType, portionGrams: portionGrams, foodBrand: foodBrand, notes: notes, date: date)
        saved = true
        dismiss()
    }
}
