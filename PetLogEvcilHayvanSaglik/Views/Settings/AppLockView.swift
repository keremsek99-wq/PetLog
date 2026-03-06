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
