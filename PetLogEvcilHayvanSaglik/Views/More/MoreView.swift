import SwiftUI
import LocalAuthentication

struct MoreView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var showDeleteAlert = false
    @State private var showPaywall = false
    @State private var showExportOptions = false
    @State private var showCustomerCenter = false
    @State private var showRestartAlert = false
    @State private var showSharePet = false
    @State private var appLock = AppLockService.shared
    @State private var pdfData: Data?
    @State private var showPDFShare = false

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
                        NavigationLink {
                            BreedHealthView(pet: pet)
                        } label: {
                            Label("Irk Sağlık Rehberi", systemImage: "heart.text.clipboard.fill")
                        }
                        NavigationLink {
                            MonthlyReportView(pet: pet, store: store)
                        } label: {
                            Label("Aylık Rapor", systemImage: "chart.bar.doc.horizontal.fill")
                        }
                        Button {
                            showSharePet = true
                        } label: {
                            Label("Pet Kartı Paylaş", systemImage: "square.and.arrow.up.fill")
                        }
                        NavigationLink {
                            DocumentListView(pet: pet, store: store, premiumManager: premiumManager)
                        } label: {
                            Label("Belgelerim", systemImage: "doc.text.fill")
                        }
                    }
                    if let pet = store.selectedPet {
                        birthdayRow(pet)
                        NavigationLink {
                            BehaviorHistoryView(pet: pet)
                        } label: {
                            Label("Davranış Geçmişi", systemImage: "brain.head.profile.fill")
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
                    if let pet = store.selectedPet {
                        Button {
                            if premiumManager.hasFullAccess {
                                pdfData = PDFReportGenerator.generateReport(for: pet, store: store)
                                showPDFShare = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            HStack {
                                Label("PDF Rapor Oluştur", systemImage: "doc.richtext.fill")
                                Spacer()
                                if !premiumManager.hasFullAccess {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .sensoryFeedback(.success, trigger: showPDFShare)
                    }
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

                Section {
                    if premiumManager.hasFullAccess {
                        Toggle(isOn: $iCloudSyncEnabled) {
                            Label("iCloud Senkronizasyonu", systemImage: "icloud.fill")
                        }
                        .onChange(of: iCloudSyncEnabled) { _, _ in
                            showRestartAlert = true
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("iCloud Senkronizasyonu", systemImage: "icloud.fill")
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                } header: {
                    Text("Senkronizasyon")
                } footer: {
                    Text("Verilerinizi tüm Apple cihazlarınız arasında senkronize edin.")
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
            .sheet(isPresented: $showSharePet) {
                if let pet = store.selectedPet {
                    SharePetSheet(pet: pet, store: store)
                }
            }
            .sheet(isPresented: $showPDFShare) {
                if let data = pdfData {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(store.selectedPet?.name ?? "PetLog")_Rapor.pdf")
                    let _ = try? data.write(to: tempURL)
                    ShareLink(item: tempURL) {
                        Label("PDF'i Paylaş", systemImage: "square.and.arrow.up")
                    }
                    .onDisappear { showPDFShare = false }
                }
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
            .alert("Yeniden Başlatma Gerekli", isPresented: $showRestartAlert) {
                Button("Tamam") {}
            } message: {
                Text("iCloud senkronizasyonu değişikliğinin etkili olması için uygulamayı kapatıp yeniden açmanız gerekir.")
            }
        }
    }

    private func birthdayRow(_ pet: Pet) -> some View {
        let now = Date()
        let calendar = Calendar.current
        var nextBirthday = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: pet.birthdate),
            day: calendar.component(.day, from: pet.birthdate)
        )) ?? pet.birthdate

        if nextBirthday < now {
            nextBirthday = calendar.date(byAdding: .year, value: 1, to: nextBirthday) ?? nextBirthday
        }

        let daysUntil = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: nextBirthday)).day ?? 0

        return HStack {
            Label("Doğum Günü", systemImage: "birthday.cake.fill")
            Spacer()
            if daysUntil == 0 {
                Text("Bugün! 🎉")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
            } else {
                Text("\(daysUntil) gün")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(daysUntil <= 7 ? .orange : .secondary)
            }
        }
    }
}
