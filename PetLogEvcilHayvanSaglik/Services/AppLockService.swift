import Foundation
import LocalAuthentication
import SwiftUI

@Observable
@MainActor
class AppLockService {
    static let shared = AppLockService()

    var isLocked: Bool = false
    var isAppLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "appLockEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "appLockEnabled") }
    }

    var biometricType: LABiometryType = .none

    private init() {
        checkBiometricAvailability()
        if isAppLockEnabled {
            isLocked = true
        }
    }

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biyometrik"
        }
    }

    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "İptal"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return await authenticateWithPasscode()
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "PetLog verilerinize erişmek için kimlik doğrulayın"
            )
            if success {
                isLocked = false
            }
            return success
        } catch {
            return await authenticateWithPasscode()
        }
    }

    private func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "PetLog verilerinize erişmek için kimlik doğrulayın"
            )
            if success {
                isLocked = false
            }
            return success
        } catch {
            return false
        }
    }

    func lockIfNeeded() {
        if isAppLockEnabled {
            isLocked = true
        }
    }
}
