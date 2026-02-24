import SwiftUI

struct AppLockOverlay: View {
    let appLock: AppLockService

    @State private var hasAttemptedAuth = false

    var body: some View {
        if appLock.isLocked {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: appLock.biometricIcon)
                        .font(.system(size: 56))
                        .foregroundStyle(appLock.authenticationFailed ? .red : .blue)
                        .symbolEffect(.pulse, isActive: !appLock.authenticationFailed)

                    VStack(spacing: 8) {
                        Text("PetLog Kilitli")
                            .font(.title2.bold())
                        Text(appLock.authenticationFailed
                             ? "Kimlik doğrulama başarısız oldu"
                             : "Devam etmek için kimliğinizi doğrulayın")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        Button {
                            Task {
                                _ = await appLock.authenticate()
                            }
                        } label: {
                            Label("Kilidi Aç", systemImage: appLock.biometricIcon)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)

                        if appLock.authenticationFailed {
                            Button {
                                appLock.disableLockDueToError()
                            } label: {
                                Text("Kilidi Devre Dışı Bırak")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
                }
            }
            .onAppear {
                guard !hasAttemptedAuth else { return }
                hasAttemptedAuth = true
                Task {
                    _ = await appLock.authenticate()
                }
            }
        }
    }
}

struct NotificationSettingsView: View {
    var premiumManager: PremiumManager = .shared
    @State private var notificationService = NotificationService.shared
    @State private var isRequesting = false
    @State private var showPaywall = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "bell.badge.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bildirimler")
                            .font(.headline)
                        Text(notificationService.isAuthorized ? "Açık" : "Kapalı")
                            .font(.subheadline)
                            .foregroundStyle(notificationService.isAuthorized ? .green : .secondary)
                    }
                    Spacer()
                    if !notificationService.isAuthorized {
                        Button {
                            isRequesting = true
                            Task {
                                _ = await notificationService.requestAuthorization()
                                isRequesting = false
                            }
                        } label: {
                            if isRequesting {
                                ProgressView()
                            } else {
                                Text("İzin Ver")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Temel Hatırlatmalar") {
                Label("Aşı hatırlatmaları", systemImage: "syringe.fill")
                Label("İlaç hatırlatmaları", systemImage: "pills.fill")
            }

            Section {
                if premiumManager.hasFullAccess {
                    Label("Mama bitiş uyarısı", systemImage: "takeoutbag.and.cup.and.straw.fill")
                    Label("Kilo kontrol hatırlatması", systemImage: "scalemass.fill")
                    Label("Aylık harcama özeti", systemImage: "chart.pie.fill")
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gelişmiş Hatırlatmalar")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Mama bitiş, kilo kontrol, harcama özeti")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            } header: {
                Text("Gelişmiş Hatırlatmalar")
            } footer: {
                if !premiumManager.hasFullAccess {
                    Text("Premium ile mama bitiş, kilo kontrol ve aylık harcama hatırlatmalarını açın.")
                }
            }

            Section {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Hatırlatmalar otomatik olarak verilerinize göre planlanır. Zamanlama değişikliği için sistem ayarlarını kullanın.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationService.checkAuthorization()
        }
        .sheet(isPresented: $showPaywall) {
            PetLogPaywallView(premiumManager: premiumManager)
        }
    }
}
