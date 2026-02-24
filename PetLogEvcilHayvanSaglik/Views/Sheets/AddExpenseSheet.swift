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
            Form {
                Section("Kategori") {
                    Picker("Kategori", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                Section("Tutar") {
                    HStack {
                        Text("₺")
                            .foregroundStyle(.secondary)
                        TextField("0,00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                    }
                }

                Section("Detaylar") {
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)
                    TextField("Mağaza / Veteriner", text: $merchant)
                    TextField("Notlar", text: $notes, axis: .vertical)
                        .lineLimit(2)
                    Toggle("Düzenli Harcama", isOn: $isRecurring)
                }
            }
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
                    .disabled(Double(amountString.replacingOccurrences(of: ",", with: ".")) == nil || Double(amountString.replacingOccurrences(of: ",", with: "."))! <= 0)
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
