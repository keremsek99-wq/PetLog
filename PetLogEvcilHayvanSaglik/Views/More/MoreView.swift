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
}
