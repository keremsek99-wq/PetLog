import SwiftUI

struct AddFoodSheet: View {
    let store: PetStore
    let pet: Pet

    @Environment(\.dismiss) private var dismiss
    @State private var brand: String = ""
    @State private var bagSizeString: String = ""
    @State private var dailyGramsString: String = ""
    @State private var startedAt: Date = Date()
    @State private var reorderLink: String = ""

    private let popularBrands = ["Royal Canin", "ProPlan", "Acana", "Orijen", "Bonacibo", "Jungle", "Reflex", "N&D", "Brit", "Hills"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Mama") {
                    TextField("Marka", text: $brand)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(popularBrands, id: \.self) { b in
                                Button {
                                    brand = b
                                } label: {
                                    Text(b)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(brand == b ? Color.blue : Color(.tertiarySystemGroupedBackground))
                                        .foregroundStyle(brand == b ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Çuval Boyutu") {
                    HStack {
                        TextField("0,0", text: $bagSizeString)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Günlük Tüketim") {
                    HStack {
                        TextField("0", text: $dailyGramsString)
                            .keyboardType(.decimalPad)
                        Text("gram/gün")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Başlangıç") {
                    DatePicker("Açıldığı Tarih", selection: $startedAt, displayedComponents: .date)
                }

                Section("Sipariş") {
                    TextField("Sipariş linki (isteğe bağlı)", text: $reorderLink)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                }

                if let bagSize = Double(bagSizeString.replacingOccurrences(of: ",", with: ".")),
                   let dailyGrams = Double(dailyGramsString.replacingOccurrences(of: ",", with: ".")),
                   bagSize > 0, dailyGrams > 0 {
                    Section {
                        let totalGrams = bagSize * 1000
                        let days = Int(totalGrams / dailyGrams)
                        let runout = Calendar.current.date(byAdding: .day, value: days, to: startedAt)
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                            Text("Tahmini \(days) gün yetecek")
                                .font(.subheadline)
                            Spacer()
                            if let runout {
                                Text(runout.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mama Takibi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var isValid: Bool {
        !brand.isEmpty &&
        (Double(bagSizeString.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0 &&
        (Double(dailyGramsString.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    private func save() {
        guard let bagSize = Double(bagSizeString.replacingOccurrences(of: ",", with: ".")),
              let dailyGrams = Double(dailyGramsString.replacingOccurrences(of: ",", with: ".")) else { return }
        store.addFood(to: pet, brand: brand, bagSizeKg: bagSize, dailyGrams: dailyGrams, startedAt: startedAt, reorderLink: reorderLink)
        dismiss()
    }
}
