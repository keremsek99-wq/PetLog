import SwiftUI

struct AddVetVisitSheet: View {
    let store: PetStore
    let pet: Pet

    @Environment(\.dismiss) private var dismiss
    @State private var date: Date = Date()
    @State private var reason: String = ""
    @State private var diagnosis: String = ""
    @State private var costString: String = ""
    @State private var veterinarian: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Ziyaret") {
                    TextField("Ziyaret sebebi", text: $reason)
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)
                }

                Section("Detaylar") {
                    TextField("Teşhis", text: $diagnosis)
                    TextField("Veteriner", text: $veterinarian)
                    TextField("Notlar", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Ücret") {
                    HStack {
                        Text("₺")
                            .foregroundStyle(.secondary)
                        TextField("0,00", text: $costString)
                            .keyboardType(.decimalPad)
                    }
                    Text("Bu işlem aynı zamanda bir harcama kaydı oluşturacaktır.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Veteriner Ziyareti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled(reason.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let cost = Double(costString.replacingOccurrences(of: ",", with: ".")) ?? 0
        store.addVetVisit(to: pet, date: date, reason: reason, diagnosis: diagnosis, cost: cost, vet: veterinarian, notes: notes)
        dismiss()
    }
}
