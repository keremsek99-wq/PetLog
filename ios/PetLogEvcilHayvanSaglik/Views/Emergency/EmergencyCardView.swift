import SwiftUI

struct EmergencyCardView: View {
    let pet: Pet

    @State private var showEditSheet = false
    @State private var showShareSheet = false

    private var hasEmergencyInfo: Bool {
        !pet.allergies.isEmpty || !pet.bloodType.isEmpty || !pet.microchipID.isEmpty ||
        !pet.emergencyVetPhone.isEmpty || !pet.emergencyContactPhone.isEmpty || !pet.specialConditions.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header Card
                emergencyHeader

                if hasEmergencyInfo {
                    // Info Cards
                    if !pet.allergies.isEmpty || !pet.specialConditions.isEmpty {
                        medicalInfoCard
                    }

                    if !pet.microchipID.isEmpty || !pet.bloodType.isEmpty {
                        identificationCard
                    }

                    if !pet.emergencyVetName.isEmpty || !pet.emergencyVetPhone.isEmpty {
                        vetContactCard
                    }

                    if !pet.emergencyContactName.isEmpty || !pet.emergencyContactPhone.isEmpty {
                        emergencyContactCard
                    }

                    // Active medications
                    if !pet.activeMedications.isEmpty {
                        activeMedicationsCard
                    }
                } else {
                    emptyState
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Acil Durum Kartı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button { showEditSheet = true } label: {
                        Image(systemName: "pencil.circle.fill")
                    }
                    if hasEmergencyInfo {
                        ShareLink(item: emergencyText) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EmergencyInfoEditSheet(pet: pet)
        }
    }

    // MARK: - Header

    private var emergencyHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.8), .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                Text("🚨")
                    .font(.largeTitle)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.title2.weight(.bold))
                HStack(spacing: 8) {
                    Text(pet.species.rawValue)
                    if !pet.breed.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(pet.breed)
                    }
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(pet.age)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    // MARK: - Medical Info

    private var medicalInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tıbbi Bilgiler", systemImage: "heart.text.clipboard")
                .font(.headline)
                .foregroundStyle(.red)

            if !pet.allergies.isEmpty {
                infoRow(emoji: "⚠️", label: "Alerjiler", value: pet.allergies)
            }
            if !pet.specialConditions.isEmpty {
                infoRow(emoji: "🩺", label: "Özel Durumlar", value: pet.specialConditions)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Identification

    private var identificationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Kimlik Bilgileri", systemImage: "qrcode")
                .font(.headline)
                .foregroundStyle(.blue)

            if !pet.microchipID.isEmpty {
                infoRow(emoji: "📡", label: "Mikroçip No", value: pet.microchipID)
            }
            if !pet.bloodType.isEmpty {
                infoRow(emoji: "🩸", label: "Kan Grubu", value: pet.bloodType)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Vet Contact

    private var vetContactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Veteriner", systemImage: "cross.case.fill")
                .font(.headline)
                .foregroundStyle(.green)

            if !pet.emergencyVetName.isEmpty {
                infoRow(emoji: "👨‍⚕️", label: "Veteriner", value: pet.emergencyVetName)
            }
            if !pet.emergencyVetPhone.isEmpty {
                HStack {
                    infoRow(emoji: "📞", label: "Telefon", value: pet.emergencyVetPhone)
                    Spacer()
                    Link(destination: URL(string: "tel:\(pet.emergencyVetPhone.replacingOccurrences(of: " ", with: ""))")!) {
                        Image(systemName: "phone.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Emergency Contact

    private var emergencyContactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Acil İletişim", systemImage: "person.crop.circle.badge.exclamationmark")
                .font(.headline)
                .foregroundStyle(.orange)

            if !pet.emergencyContactName.isEmpty {
                infoRow(emoji: "👤", label: "Kişi", value: pet.emergencyContactName)
            }
            if !pet.emergencyContactPhone.isEmpty {
                HStack {
                    infoRow(emoji: "📱", label: "Telefon", value: pet.emergencyContactPhone)
                    Spacer()
                    Link(destination: URL(string: "tel:\(pet.emergencyContactPhone.replacingOccurrences(of: " ", with: ""))")!) {
                        Image(systemName: "phone.circle.fill")
                            .font(.title)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Active Medications

    private var activeMedicationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Aktif İlaçlar", systemImage: "pills.fill")
                .font(.headline)
                .foregroundStyle(.purple)

            ForEach(pet.activeMedications, id: \.id) { med in
                HStack(spacing: 8) {
                    Text("💊")
                    VStack(alignment: .leading, spacing: 1) {
                        Text(med.name)
                            .font(.subheadline.weight(.semibold))
                        Text("\(med.dosage) · \(med.schedule.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Acil Durum Bilgisi Yok")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Alerjiler, kan grubu, mikroçip numarası ve acil iletişim bilgilerini ekleyin. Bu bilgiler acil bir durumda hayat kurtarabilir.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button {
                showEditSheet = true
            } label: {
                Label("Bilgileri Düzenle", systemImage: "pencil.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(32)
    }

    // MARK: - Helpers

    private func infoRow(emoji: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }

    private var emergencyText: String {
        var lines: [String] = []
        lines.append("🚨 ACİL DURUM KARTI — \(pet.name)")
        lines.append("\(pet.species.rawValue) · \(pet.breed) · \(pet.age)")
        lines.append("Kilo: \(pet.latestWeight.map { String(format: "%.1f kg", $0) } ?? "Bilinmiyor")")
        if !pet.allergies.isEmpty { lines.append("⚠️ Alerjiler: \(pet.allergies)") }
        if !pet.bloodType.isEmpty { lines.append("🩸 Kan Grubu: \(pet.bloodType)") }
        if !pet.microchipID.isEmpty { lines.append("📡 Mikroçip: \(pet.microchipID)") }
        if !pet.specialConditions.isEmpty { lines.append("🩺 Özel Durum: \(pet.specialConditions)") }
        if !pet.emergencyVetName.isEmpty { lines.append("👨‍⚕️ Veteriner: \(pet.emergencyVetName)") }
        if !pet.emergencyVetPhone.isEmpty { lines.append("📞 Vet Tel: \(pet.emergencyVetPhone)") }
        if !pet.emergencyContactName.isEmpty { lines.append("👤 Acil Kişi: \(pet.emergencyContactName)") }
        if !pet.emergencyContactPhone.isEmpty { lines.append("📱 Acil Tel: \(pet.emergencyContactPhone)") }
        if !pet.activeMedications.isEmpty {
            lines.append("💊 Aktif İlaçlar: \(pet.activeMedications.map { "\($0.name) \($0.dosage)" }.joined(separator: ", "))")
        }
        lines.append("\n— PetLog ile oluşturuldu")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Emergency Info Edit Sheet

struct EmergencyInfoEditSheet: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss

    @State private var allergies: String = ""
    @State private var bloodType: String = ""
    @State private var microchipID: String = ""
    @State private var emergencyVetName: String = ""
    @State private var emergencyVetPhone: String = ""
    @State private var emergencyContactName: String = ""
    @State private var emergencyContactPhone: String = ""
    @State private var specialConditions: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Text("🚨")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("\(pet.name) Acil Durum Bilgileri")
                                .font(.headline)
                            Text("Bu bilgileri eksiksiz doldurun")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Tıbbi Bilgiler") {
                    TextField("Alerjiler (örn: Penisilin, Tavuk)", text: $allergies)
                    TextField("Kan Grubu", text: $bloodType)
                    TextField("Özel Sağlık Durumları", text: $specialConditions, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Kimlik Bilgileri") {
                    TextField("Mikroçip No", text: $microchipID)
                        .keyboardType(.numberPad)
                }

                Section("Veteriner Bilgileri") {
                    TextField("Veteriner Adı", text: $emergencyVetName)
                    TextField("Veteriner Telefon", text: $emergencyVetPhone)
                        .keyboardType(.phonePad)
                }

                Section("Acil İletişim Kişisi") {
                    TextField("Ad Soyad", text: $emergencyContactName)
                    TextField("Telefon", text: $emergencyContactPhone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Acil Durum Bilgileri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveToPet()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadFromPet()
            }
        }
    }

    private func loadFromPet() {
        allergies = pet.allergies
        bloodType = pet.bloodType
        microchipID = pet.microchipID
        emergencyVetName = pet.emergencyVetName
        emergencyVetPhone = pet.emergencyVetPhone
        emergencyContactName = pet.emergencyContactName
        emergencyContactPhone = pet.emergencyContactPhone
        specialConditions = pet.specialConditions
    }

    private func saveToPet() {
        pet.allergies = allergies
        pet.bloodType = bloodType
        pet.microchipID = microchipID
        pet.emergencyVetName = emergencyVetName
        pet.emergencyVetPhone = emergencyVetPhone
        pet.emergencyContactName = emergencyContactName
        pet.emergencyContactPhone = emergencyContactPhone
        pet.specialConditions = specialConditions
    }
}
