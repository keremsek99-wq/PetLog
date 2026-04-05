import Foundation
import LocalAuthentication
import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.petlog.app", category: "AppLock")

@Observable
@MainActor
class AppLockService {
    static let shared = AppLockService()

    var isLocked: Bool = false
    var isAppLockEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "appLockEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "appLockEnabled") }
    }
    var authenticationFailed: Bool = false

    var biometricType: LABiometryType = .none
    private var isAuthenticating: Bool = false

    // Rate limiting
    private var failedAttempts: Int = 0
    private var lastFailedAttempt: Date?
    private static let maxAttempts = 5
    private static let lockoutDuration: TimeInterval = 30 // 30 seconds lockout

    // Auto-lock timeout
    private var lastActiveDate: Date = Date()
    private static let autoLockTimeout: TimeInterval = 300 // 5 minutes

    var isLockedOut: Bool {
        guard failedAttempts >= Self.maxAttempts,
              let lastFailed = lastFailedAttempt else { return false }
        return Date().timeIntervalSince(lastFailed) < Self.lockoutDuration
    }

    var lockoutRemainingSeconds: Int {
        guard let lastFailed = lastFailedAttempt else { return 0 }
        let elapsed = Date().timeIntervalSince(lastFailed)
        return max(0, Int(Self.lockoutDuration - elapsed))
    }

    private init() {
        checkBiometricAvailability()
        if isAppLockEnabled && canAuthenticate {
            isLocked = true
        }
    }

    var canAuthenticate: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
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
        case .none: return "Biyometrik"
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
        guard isLocked, !isAuthenticating else { return !isLocked }

        // Rate limiting check
        if isLockedOut {
            logger.warning("Authentication locked out for \(self.lockoutRemainingSeconds)s after \(self.failedAttempts) failed attempts")
            authenticationFailed = true
            return false
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

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
                onAuthenticationSuccess()
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
                onAuthenticationSuccess()
            } else {
                onAuthenticationFailure()
            }
            return success
        } catch {
            onAuthenticationFailure()
            return false
        }
    }

    private func onAuthenticationSuccess() {
        isLocked = false
        authenticationFailed = false
        failedAttempts = 0
        lastFailedAttempt = nil
        lastActiveDate = Date()
    }

    private func onAuthenticationFailure() {
        authenticationFailed = true
        failedAttempts += 1
        lastFailedAttempt = Date()
        logger.info("Authentication failed. Attempt \(self.failedAttempts)/\(Self.maxAttempts)")
    }

    func lockIfNeeded() {
        guard isAppLockEnabled, canAuthenticate else { return }
        isLocked = true
        authenticationFailed = false
    }

    /// Check if auto-lock timeout has elapsed and lock if needed.
    /// Call this when the app becomes active.
    func lockIfTimedOut() {
        guard isAppLockEnabled, canAuthenticate else { return }
        let elapsed = Date().timeIntervalSince(lastActiveDate)
        if elapsed >= Self.autoLockTimeout {
            isLocked = true
            authenticationFailed = false
        }
        lastActiveDate = Date()
    }

    /// Record user activity to reset the auto-lock timer.
    func recordActivity() {
        lastActiveDate = Date()
    }
}
