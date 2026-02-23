import SwiftUI

struct AppLockOverlay: View {
    let appLock: AppLockService

    var body: some View {
        if appLock.isLocked {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: appLock.biometricIcon)
                        .font(.system(size: 56))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse, isActive: true)

                    VStack(spacing: 8) {
                        Text("PetLog Kilitli")
                            .font(.title2.bold())
                        Text("Devam etmek için kimliğinizi doğrulayın")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

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
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
                }
            }
            .task {
                _ = await appLock.authenticate()
            }
        }
    }
}

struct NotificationSettingsView: View {
    @State private var notificationService = NotificationService.shared
    @State private var isRequesting = false

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

            Section("Hatırlatma Türleri") {
                Label("Aşı hatırlatmaları", systemImage: "syringe.fill")
                Label("İlaç hatırlatmaları", systemImage: "pills.fill")
                Label("Mama bitiş uyarısı", systemImage: "takeoutbag.and.cup.and.straw.fill")
                Label("Kilo kontrol hatırlatması", systemImage: "scalemass.fill")
                Label("Aylık harcama özeti", systemImage: "chart.pie.fill")
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
    }
}
