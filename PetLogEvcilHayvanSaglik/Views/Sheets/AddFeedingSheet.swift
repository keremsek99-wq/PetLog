import SwiftUI
import SwiftData

struct AddFeedingSheet: View {
    let store: PetStore
    @Environment(\.dismiss) private var dismiss
    @State private var mealType: MealType = .breakfast
    @State private var portionGrams: Double = 100
    @State private var foodBrand = ""
    @State private var notes = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Öğün") {
                    Picker("Öğün", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if mealType != .water {
                    Section("Porsiyon") {
                        HStack {
                            Text("Miktar")
                            Spacer()
                            TextField("gram", value: $portionGrams, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("g")
                                .foregroundStyle(.secondary)
                        }

                        TextField("Mama markası", text: $foodBrand)
                    }
                } else {
                    Section("Su Miktarı") {
                        HStack {
                            Text("Miktar")
                            Spacer()
                            TextField("ml", value: $portionGrams, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("ml")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Tarih") {
                    DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notlar") {
                    TextField("Opsiyonel not...", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
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
                }
            }
        }
    }

    private func save() {
        guard let pet = store.selectedPet else { return }
        store.addFeedingLog(to: pet, mealType: mealType, portionGrams: portionGrams, foodBrand: foodBrand, notes: notes, date: date)
        dismiss()
    }
}
