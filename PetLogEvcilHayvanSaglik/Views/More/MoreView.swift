import SwiftUI
import LocalAuthentication

struct MoreView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showDeleteAlert = false
    @State private var showPaywall = false
    @State private var showExportOptions = false
    @State private var showCustomerCenter = false
    @State private var appLock = AppLockService.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let pet = store.selectedPet {
                        NavigationLink {
                            PetSummaryCardView(pet: pet, store: store)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: pet.species.icon)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pet.name)
                                        .font(.headline)
                                    Text("\(pet.species.rawValue) · \(pet.age)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } footer: {
                    Text("Pet özet kartını görmek için dokunun")
                }

                if !premiumManager.hasFullAccess {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.12), .purple.opacity(0.12)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("PetLog Premium")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Tüm özelliklerin kilidini açın")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("PRO")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    Section {
                        HStack(spacing: 14) {
                            Image(systemName: "crown.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.12), .purple.opacity(0.12)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PetLog Premium")
                                    .font(.headline)
                                Text("Aktif")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.vertical, 4)

                        Button {
                            showCustomerCenter = true
                        } label: {
                            Label("Aboneliği Yönet", systemImage: "gearshape.fill")
                        }
                    }
                }

                Section("Hayvan Yönetimi") {
                    NavigationLink {
                        PetListView(store: store, premiumManager: premiumManager)
                    } label: {
                        Label("Hayvanlarım", systemImage: "pawprint.fill")
                    }
                    if let pet = store.selectedPet {
                        NavigationLink {
                            PetSummaryCardView(pet: pet, store: store)
                        } label: {
                            Label("Pet Özet Kartı", systemImage: "person.text.rectangle")
                        }
                    }
                }

                Section("Bildirimler & Güvenlik") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Bildirim Ayarları", systemImage: "bell.badge.fill")
                    }
                    Toggle(isOn: Binding(
                        get: { appLock.isAppLockEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let success = await appLock.authenticate()
                                    if success {
                                        appLock.isAppLockEnabled = true
                                    }
                                }
                            } else {
                                appLock.isAppLockEnabled = false
                                appLock.isLocked = false
                            }
                        }
                    )) {
                        Label(appLock.biometricType != .none ? appLock.biometricName : "Uygulama Kilidi", systemImage: appLock.biometricIcon)
                    }
                    .disabled(!appLock.canAuthenticate)
                }

                Section("Veriler") {
                    NavigationLink {
                        DataExportFullView(store: store, premiumManager: premiumManager)
                    } label: {
                        Label("Veri Dışa Aktar", systemImage: "square.and.arrow.up")
                    }
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        Label("Gizlilik & Veriler", systemImage: "hand.raised.fill")
                    }
                }

                Section("Türkiye Özel") {
                    NavigationLink {
                        TurkeyResourcesView()
                    } label: {
                        Label("Faydalı Bilgiler", systemImage: "mappin.and.ellipse")
                    }
                }

                Section("Uygulama") {
                    HStack {
                        Label("Sürüm", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Tüm Verileri Sıfırla", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Daha Fazla")
            .sheet(isPresented: $showPaywall) {
                PetLogPaywallView(premiumManager: premiumManager)
            }
            .sheet(isPresented: $showCustomerCenter) {
                PetLogPaywallView(premiumManager: premiumManager)
            }
            .alert("Tüm Veriler Silinsin mi?", isPresented: $showDeleteAlert) {
                Button("İptal", role: .cancel) {}
                Button("Sıfırla", role: .destructive) {
                    let pets = store.allPets()
                    for pet in pets {
                        store.deletePet(pet)
                    }
                    NotificationService.shared.cancelAllNotifications()
                    hasCompletedOnboarding = false
                }
            } message: {
                Text("Tüm hayvanlar ve ilişkili veriler kalıcı olarak silinecektir. Bu işlem geri alınamaz.")
            }
        }
    }
}

struct PetListView: View {
    let store: PetStore
    let premiumManager: PremiumManager
    @State private var showAddPet = false
    @State private var showPaywall = false
    @State private var editingPet: Pet? = nil

    var body: some View {
        List {
            ForEach(store.allPets(), id: \.id) { pet in
                HStack(spacing: 12) {
                    petAvatar(pet)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name)
                            .font(.headline)
                        Text("\(pet.species.rawValue) · \(pet.breed.isEmpty ? "Irk belirtilmemiş" : pet.breed) · \(pet.age)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if store.selectedPet?.id == pet.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    store.selectedPet = pet
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.deletePet(pet)
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                    Button {
                        editingPet = pet
                    } label: {
                        Label("Düzenle", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle("Hayvanlarım")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if store.canAddMorePets(isPremium: premiumManager.hasFullAccess) {
                        showAddPet = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddPet) {
            AddPetSheet(store: store)
        }
        .sheet(item: $editingPet) { pet in
            AddPetSheet(store: store, editingPet: pet)
        }
        .sheet(isPresented: $showPaywall) {
            PetLogPaywallView(premiumManager: premiumManager)
        }
    }

    private func petAvatar(_ pet: Pet) -> some View {
        Group {
            if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: pet.species.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Circle())
            }
        }
    }
}

struct DataExportFullView: View {
    let store: PetStore
    let premiumManager: PremiumManager
    @State private var exportType: ExportType = .summary
    @State private var showPaywall = false

    private var pet: Pet? { store.selectedPet }

    var body: some View {
        List {
            Section {
                Text("Evcil hayvanınızın sağlık ve finans verilerini dışa aktarın.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let pet {
                Section("\(pet.name) Özeti") {
                    StatRow(label: "Kilo Kayıtları", value: "\(pet.weightLogs.count)", icon: "scalemass.fill", iconColor: .green)
                    StatRow(label: "Aşılar", value: "\(pet.vaccineRecords.count)", icon: "syringe.fill", iconColor: .purple)
                    StatRow(label: "İlaçlar", value: "\(pet.medications.count)", icon: "pills.fill", iconColor: .blue)
                    StatRow(label: "Veteriner Ziyaretleri", value: "\(pet.vetVisits.count)", icon: "cross.case.fill", iconColor: .red)
                    StatRow(label: "Harcamalar", value: "\(pet.expenses.count)", icon: "turkishlirasign.circle.fill", iconColor: .orange)
                }

                Section("Dışa Aktarma Formatı") {
                    Picker("Format", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    switch exportType {
                    case .summary:
                        ShareLink(item: generateSummaryText(pet)) {
                            Label("Özet Paylaş", systemImage: "square.and.arrow.up")
                        }
                    case .json:
                        if premiumManager.hasFullAccess {
                            ShareLink(item: DataExportService.shared.exportJSON(for: pet, store: store)) {
                                Label("JSON Dışa Aktar", systemImage: "doc.badge.arrow.up")
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Label("JSON Dışa Aktar", systemImage: "doc.badge.arrow.up")
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    case .csv:
                        if premiumManager.hasFullAccess {
                            ShareLink(item: DataExportService.shared.exportCSV(for: pet)) {
                                Label("CSV Dışa Aktar (Harcamalar)", systemImage: "tablecells")
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Label("CSV Dışa Aktar (Harcamalar)", systemImage: "tablecells")
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Veri Dışa Aktar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PetLogPaywallView(premiumManager: premiumManager)
        }
    }

    private func generateSummaryText(_ pet: Pet) -> String {
        var text = "PetLog Sağlık & Finans Raporu\n"
        text += "Hayvan: \(pet.name) (\(pet.species.rawValue))\n"
        text += "Yaş: \(pet.age)\n\n"
        if let weight = pet.latestWeight {
            text += "Güncel Kilo: \(String(format: "%.1f", weight)) kg\n"
        }
        text += "Toplam Harcama (Yıl): \(store.annualSpending(for: pet).formatted(.currency(code: "TRY")))\n"
        text += "Aktif İlaçlar: \(pet.activeMedications.count)\n"
        text += "Aşı Kayıtları: \(pet.vaccineRecords.count)\n"
        text += "Veteriner Ziyaretleri: \(pet.vetVisits.count)\n"
        return text
    }
}

nonisolated enum ExportType: String, CaseIterable, Sendable {
    case summary
    case json
    case csv

    var title: String {
        switch self {
        case .summary: return "Özet"
        case .json: return "JSON"
        case .csv: return "CSV"
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                    Text("Verileriniz Güvende")
                        .font(.headline)
                    Text("PetLog, verilerinizi cihazınızda saklar. Verileriniz sunucularımıza gönderilmez ve üçüncü taraflarla paylaşılmaz.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Veri Saklama") {
                InfoRow(title: "Yerel Depolama", detail: "Tüm veriler cihazınızda saklanır", icon: "iphone", color: .blue)
                InfoRow(title: "Şifreleme", detail: "iOS veri koruma ile şifrelenir", icon: "lock.fill", color: .green)
                InfoRow(title: "Biyometrik Kilit", detail: "Face ID/Touch ID ile koruma", icon: "faceid", color: .purple)
            }

            Section("KVKK Uyumu") {
                InfoRow(title: "Veri Taşınabilirliği", detail: "Verilerinizi JSON olarak dışa aktarın", icon: "square.and.arrow.up", color: .orange)
                InfoRow(title: "Veri Silme", detail: "Tüm verilerinizi kalıcı olarak silin", icon: "trash", color: .red)
                InfoRow(title: "Reklam Yok", detail: "Kişisel verileriniz reklam için kullanılmaz", icon: "nosign", color: .green)
            }

            Section("Tıbbi Sorumluluk Reddi") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PetLog tıbbi teşhis veya tedavi önerisi vermez. Uygulama içindeki tüm öneriler yalnızca bilgilendirme amaçlıdır.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Evcil hayvanınızın sağlığıyla ilgili endişeleriniz için her zaman lisanslı bir veterinere başvurun.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Gizlilik & Veriler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TurkeyResourcesView: View {
    var body: some View {
        List {
            Section("Acil Veteriner Hatları") {
                InfoRow(title: "Tarım ve Orman Bakanlığı", detail: "ALO 174", icon: "phone.fill", color: .red)
                InfoRow(title: "HAYTAP Hayvan Hakları", detail: "0212 244 26 14", icon: "phone.fill", color: .green)
            }

            Section("Faydalı Bilgiler") {
                InfoRow(title: "Evcil Hayvan Pasaportu", detail: "Yurt dışı seyahat için veterinerinizden alın", icon: "doc.text.fill", color: .blue)
                InfoRow(title: "Çip Zorunluluğu", detail: "Tüm kedi ve köpekler için zorunlu", icon: "sensor.fill", color: .purple)
                InfoRow(title: "Kuduz Aşısı", detail: "Yılda bir kez zorunlu", icon: "syringe.fill", color: .orange)
            }

            Section("Popüler Mama Markaları") {
                InfoRow(title: "ProPlan", detail: "Veteriner önerili premium mama", icon: "fork.knife", color: .orange)
                InfoRow(title: "Royal Canin", detail: "Irka özel mama seçenekleri", icon: "fork.knife", color: .red)
                InfoRow(title: "Acana / Orijen", detail: "Doğal içerikli premium mama", icon: "fork.knife", color: .green)
                InfoRow(title: "Bonacibo", detail: "Türk üretimi kaliteli mama", icon: "fork.knife", color: .teal)
                InfoRow(title: "Jungle", detail: "Türk üretimi ekonomik mama", icon: "fork.knife", color: .brown)
            }

            Section("Online Alışveriş") {
                InfoRow(title: "PetCity", detail: "petcity.com.tr", icon: "cart.fill", color: .blue)
                InfoRow(title: "PetBurada", detail: "petburada.com", icon: "cart.fill", color: .green)
                InfoRow(title: "Zooplus TR", detail: "zooplus.com.tr", icon: "cart.fill", color: .orange)
            }
        }
        .navigationTitle("Faydalı Bilgiler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let title: String
    let detail: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(.rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
