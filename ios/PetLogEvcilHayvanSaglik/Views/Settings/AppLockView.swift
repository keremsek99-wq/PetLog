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

                        if appLock.isLockedOut {
                            Text("Çok fazla başarısız deneme. \(appLock.lockoutRemainingSeconds) saniye bekleyin.")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        } else if appLock.authenticationFailed {
                            Text("Kimlik doğrulama başarısız oldu")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Devam etmek için kimliğinizi doğrulayın")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
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
                        .disabled(appLock.isLockedOut)
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
