import SwiftUI

struct AddWeightSheet: View {
    let store: PetStore
    let pet: Pet

    @Environment(\.dismiss) private var dismiss
    @State private var weightString: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var saved = false

    private var latestWeight: Double? { pet.latestWeight }
    private var weightTarget: Double? { pet.weightTargetKg }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Emoji header with weight context
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [PetOSColors.healthGreen.opacity(0.2), PetOSColors.healthGreen.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Text("⚖️")
                                .font(.largeTitle)
                        }

                        if let latest = latestWeight {
                            Text("Son ölçüm: \(String(format: "%.1f", latest)) kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)

                    // Weight input
                    VStack(spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            TextField("0,0", text: $weightString)
                                .keyboardType(.decimalPad)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .multilineTextAlignment(.center)
                            Text("kg")
                                .font(.title2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        // Weight comparison
                        if let latest = latestWeight,
                           let current = Double(weightString.replacingOccurrences(of: ",", with: ".")),
                           current > 0 {
                            let diff = current - latest
                            HStack(spacing: 4) {
                                Image(systemName: diff > 0 ? "arrow.up.right" : (diff < 0 ? "arrow.down.right" : "equal"))
                                    .font(.caption2.weight(.bold))
                                Text(String(format: "%+.1f kg", diff))
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(abs(diff) < 0.1 ? .green : (diff > 0 ? .orange : .blue))
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                    // Target indicator
                    if let target = weightTarget {
                        HStack(spacing: 8) {
                            Image(systemName: "target")
                                .foregroundStyle(.blue)
                            Text("Hedef: \(String(format: "%.1f", target)) kg")
                                .font(.caption)
                            Spacer()
                            if let current = Double(weightString.replacingOccurrences(of: ",", with: ".")),
                               current > 0 {
                                let diff = abs(current - target)
                                Text(diff < 0.5 ? "Hedefe çok yakın! 🎉" : "\(String(format: "%.1f", diff)) kg fark")
                                    .font(.caption)
                                    .foregroundStyle(diff < 0.5 ? .green : .secondary)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.06))
                        )
                    }

                    // Date & Notes
                    VStack(spacing: 12) {
                        DatePicker("Tarih", selection: $date, displayedComponents: .date)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("İsteğe bağlı notlar", text: $notes, axis: .vertical)
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
            .navigationTitle("Kilo Kaydet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled((Double(weightString.replacingOccurrences(of: ",", with: ".")) ?? 0) <= 0)
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        guard let weight = Double(weightString.replacingOccurrences(of: ",", with: ".")), weight > 0 else { return }
        store.addWeightLog(to: pet, weightKg: weight, date: date, notes: notes)
        saved = true
        dismiss()
    }
}
