import SwiftUI

struct AddVaccineSheet: View {
    let store: PetStore
    let pet: Pet

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var dateAdministered: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var veterinarian: String = ""
    @State private var notes: String = ""
    @State private var saved = false

    private let commonVaccines = ["Kuduz", "Karma (DHPPi)", "Lösemi (FeLV)", "İç Parazit", "Dış Parazit", "Leptospiroz", "Bordetella"]

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
                                        colors: [Color.purple.opacity(0.2), Color.purple.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Text("💉")
                                .font(.largeTitle)
                        }
                        Text("\(pet.name) için aşı kaydı")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Vaccine name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aşı Adı")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        TextField("Aşı Adı", text: $name)
                            .font(.body.weight(.medium))
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        // Common vaccine chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(commonVaccines, id: \.self) { v in
                                    Button {
                                        withAnimation(.spring(duration: 0.2)) {
                                            name = v
                                        }
                                    } label: {
                                        Text(v)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(name == v ? Color.purple : Color(.tertiarySystemGroupedBackground))
                                            .foregroundStyle(name == v ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .sensoryFeedback(.selection, trigger: name)
                    }

                    // Date
                    DatePicker("Yapıldığı Tarih", selection: $dateAdministered, displayedComponents: .date)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))

                    // Due date toggle
                    VStack(spacing: 12) {
                        Toggle(isOn: $hasDueDate.animation(.spring(duration: 0.3))) {
                            HStack(spacing: 8) {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundStyle(.orange)
                                Text("Hatırlatma Tarihi Belirle")
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))

                        if hasDueDate {
                            DatePicker("Sonraki Tarih", selection: $dueDate, in: dateAdministered..., displayedComponents: .date)
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 12))
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }

                    // Details
                    VStack(spacing: 12) {
                        TextField("Veteriner", text: $veterinarian)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("Notlar", text: $notes, axis: .vertical)
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
            .navigationTitle("Aşı Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
    }

    private func save() {
        store.addVaccine(to: pet, name: name, dateAdministered: dateAdministered, dueDate: hasDueDate ? dueDate : nil, vet: veterinarian, notes: notes)
        saved = true
        dismiss()
    }
}
