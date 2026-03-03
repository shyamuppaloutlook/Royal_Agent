import Foundation
import SwiftUI
import Combine
import LocalAuthentication

class BiometricService: ObservableObject {
    @Published var isBiometricAvailable: Bool = false
    @Published var isBiometricEnabled: Bool = false
    @Published var biometricType: BiometricType = .none
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var authenticationAttempts: Int = 0
    @Published var maxAttempts: Int = 5
    @Published var lastAuthenticationTime: Date?
    @Published var biometricSettings: BiometricSettings = BiometricSettings()
    @Published var authenticationHistory: [AuthenticationRecord] = []
    @Published var securityLevel: SecurityLevel = .medium
    @Published var isLocked: Bool = false
    @Published var lockReason: String?
    @Published var lockDuration: TimeInterval?
    @Published var lockExpiryTime: Date?
    
    private let context = LAContext()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Biometric Types
    
    enum BiometricType: String, CaseIterable {
        case none = "None"
        case touchID = "Touch ID"
        case faceID = "Face ID"
        case opticID = "Optic ID"
        
        var id: String { return rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "No Biometrics"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }
        
        var description: String {
            switch self {
            case .none: return "No biometric authentication available"
            case .touchID: return "Fingerprint authentication"
            case .faceID: return "Facial recognition authentication"
            case .opticID: return "Retinal scan authentication"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "person.slash"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .opticID: return "eye"
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .touchID: return .green
            case .faceID: return .blue
            case .opticID: return .purple
            }
        }
    }
    
    // MARK: - Authentication States
    
    enum AuthenticationState: String, CaseIterable {
        case unauthenticated = "Unauthenticated"
        case authenticating = "Authenticating"
        case authenticated = "Authenticated"
        case failed = "Failed"
        case locked = "Locked"
        case disabled = "Disabled"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .unauthenticated: return .gray
            case .authenticating: return .orange
            case .authenticated: return .green
            case .failed: return .red
            case .locked: return .purple
            case .disabled: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .unauthenticated: return "person.slash"
            case .authenticating: return "arrow.triangle.2.circlepath"
            case .authenticated: return "checkmark.shield"
            case .failed: return "xmark.shield"
            case .locked: return "lock.shield"
            case .disabled: return "power.slash"
            }
        }
    }
    
    // MARK: - Security Levels
    
    enum SecurityLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case maximum = "Maximum"
        
        var id: String { return rawValue }
        
        var description: String {
            switch self {
            case .low: return "Basic security with simple requirements"
            case .medium: return "Standard security with moderate requirements"
            case .high: return "Enhanced security with strict requirements"
            case .maximum: return "Maximum security with very strict requirements"
            }
        }
        
        var maxAttempts: Int {
            switch self {
            case .low: return 10
            case .medium: return 5
            case .high: return 3
            case .maximum: return 2
            }
        }
        
        var lockDuration: TimeInterval {
            switch self {
            case .low: return 300 // 5 minutes
            case .medium: return 900 // 15 minutes
            case .high: return 3600 // 1 hour
            case .maximum: return 86400 // 24 hours
            }
        }
        
        var requiresAdditionalVerification: Bool {
            switch self {
            case .low, .medium: return false
            case .high, .maximum: return true
            }
        }
    }
    
    // MARK: - Authentication Reasons
    
    enum AuthenticationReason: String, CaseIterable {
        case unlock = "Unlock"
        case transaction = "Transaction"
        case settings = "Settings"
        case sensitiveData = "Sensitive Data"
        case admin = "Admin Access"
        case emergency = "Emergency Access"
        
        var id: String { return rawValue }
        
        var description: String {
            switch self {
            case .unlock: return "Unlock the application"
            case .transaction: return "Authorize financial transactions"
            case .settings: return "Access security settings"
            case .sensitiveData: return "View sensitive financial data"
            case .admin: return "Access administrative functions"
            case .emergency: return "Emergency access override"
            }
        }
        
        var requiresHighSecurity: Bool {
            switch self {
            case .transaction, .sensitiveData, .admin: return true
            case .unlock, .settings, .emergency: return false
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupBiometricService()
        loadBiometricSettings()
        checkBiometricAvailability()
        updateAuthenticationState()
    }
    
    private func setupBiometricService() {
        // Set up biometric authentication context
        context.localizedFallbackTitle = "Use Passcode"
        context.localizedCancelTitle = "Cancel"
    }
    
    private func loadBiometricSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "biometric_settings"),
           let settings = try? JSONDecoder().decode(BiometricSettings.self, from: data) {
            biometricSettings = settings
            isBiometricEnabled = settings.isEnabled
            securityLevel = settings.securityLevel
        }
        
        if let data = defaults.data(forKey: "authentication_history"),
           let history = try? JSONDecoder().decode([AuthenticationRecord].self, from: data) {
            authenticationHistory = history
        }
    }
    
    private func saveBiometricSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(biometricSettings) {
            defaults.set(data, forKey: "biometric_settings")
        }
        
        if let data = try? JSONEncoder().encode(authenticationHistory) {
            defaults.set(data, forKey: "authentication_history")
        }
    }
    
    private func checkBiometricAvailability() {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isBiometricAvailable = false
            biometricType = .none
            return
        }
        
        isBiometricAvailable = true
        
        switch context.biometryType {
        case .none:
            biometricType = .none
        case .touchID:
            biometricType = .touchID
        case .faceID:
            biometricType = .faceID
        case .opticID:
            biometricType = .opticID
        @unknown default:
            biometricType = .none
        }
    }
    
    private func updateAuthenticationState() {
        if isLocked {
            authenticationState = .locked
        } else if !isBiometricEnabled {
            authenticationState = .disabled
        } else if lastAuthenticationTime != nil && isAuthenticatedRecently() {
            authenticationState = .authenticated
        } else {
            authenticationState = .unauthenticated
        }
    }
    
    private func isAuthenticatedRecently() -> Bool {
        guard let lastAuth = lastAuthenticationTime else { return false }
        
        let timeout: TimeInterval = biometricSettings.autoLockTimeout
        return Date().timeIntervalSince(lastAuth) < timeout
    }
    
    // MARK: - Authentication Methods
    
    func authenticate(reason: AuthenticationReason = .unlock) async -> Bool {
        guard isBiometricAvailable && isBiometricEnabled && !isLocked else {
            return false
        }
        
        authenticationState = .authenticating
        
        let success = await performBiometricAuthentication(reason: reason)
        
        await MainActor.run {
            self.processAuthenticationResult(success, reason: reason)
        }
        
        return success
    }
    
    private func performBiometricAuthentication(reason: AuthenticationReason) async -> Bool {
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason.description
            ) { success, error in
                continuation.resume(returning: success)
            }
        }
    }
    
    private func processAuthenticationResult(_ success: Bool, reason: AuthenticationReason) {
        let timestamp = Date()
        
        if success {
            authenticationState = .authenticated
            lastAuthenticationTime = timestamp
            authenticationAttempts = 0
            
            // Record successful authentication
            let record = AuthenticationRecord(
                id: UUID().uuidString,
                timestamp: timestamp,
                reason: reason,
                success: true,
                biometricType: biometricType,
                duration: 0.0
            )
            
            authenticationHistory.append(record)
            
        } else {
            authenticationAttempts += 1
            authenticationState = .failed
            
            // Check if account should be locked
            if authenticationAttempts >= securityLevel.maxAttempts {
                lockAccount(reason: "Too many failed authentication attempts")
            }
            
            // Record failed authentication
            let record = AuthenticationRecord(
                id: UUID().uuidString,
                timestamp: timestamp,
                reason: reason,
                success: false,
                biometricType: biometricType,
                duration: 0.0
            )
            
            authenticationHistory.append(record)
        }
        
        // Keep only recent authentication history (last 100)
        if authenticationHistory.count > 100 {
            authenticationHistory = Array(authenticationHistory.suffix(100))
        }
        
        saveBiometricSettings()
        updateAuthenticationState()
    }
    
    // MARK: - Account Locking
    
    private func lockAccount(reason: String) {
        isLocked = true
        lockReason = reason
        lockDuration = securityLevel.lockDuration
        lockExpiryTime = Date().addingTimeInterval(securityLevel.lockDuration)
        authenticationState = .locked
        
        // Schedule automatic unlock
        DispatchQueue.main.asyncAfter(deadline: .now() + securityLevel.lockDuration) { [weak self] in
            self?.unlockAccount()
        }
    }
    
    func unlockAccount() {
        guard let expiryTime = lockExpiryTime else { return }
        
        if Date() >= expiryTime {
            isLocked = false
            lockReason = nil
            lockDuration = nil
            lockExpiryTime = nil
            authenticationAttempts = 0
            authenticationState = .unauthenticated
            
            updateAuthenticationState()
        }
    }
    
    func forceUnlock() {
        isLocked = false
        lockReason = nil
        lockDuration = nil
        lockExpiryTime = nil
        authenticationAttempts = 0
        authenticationState = .unauthenticated
        
        updateAuthenticationState()
    }
    
    // MARK: - Biometric Management
    
    func enableBiometric() {
        guard isBiometricAvailable else { return }
        
        isBiometricEnabled = true
        biometricSettings.isEnabled = true
        authenticationState = .unauthenticated
        
        saveBiometricSettings()
        updateAuthenticationState()
    }
    
    func disableBiometric() {
        isBiometricEnabled = false
        biometricSettings.isEnabled = false
        authenticationState = .disabled
        lastAuthenticationTime = nil
        
        saveBiometricSettings()
        updateAuthenticationState()
    }
    
    func updateSecurityLevel(_ level: SecurityLevel) {
        securityLevel = level
        biometricSettings.securityLevel = level
        maxAttempts = level.maxAttempts
        
        saveBiometricSettings()
    }
    
    func updateBiometricSettings(_ settings: BiometricSettings) {
        biometricSettings = settings
        isBiometricEnabled = settings.isEnabled
        securityLevel = settings.securityLevel
        
        saveBiometricSettings()
        updateAuthenticationState()
    }
    
    // MARK: - Security Operations
    
    func requireAuthentication(for operation: String) async -> Bool {
        let reason: AuthenticationReason
        
        switch operation.lowercased() {
        case let op where op.contains("transaction") || op.contains("payment"):
            reason = .transaction
        case let op where op.contains("settings") || op.contains("config"):
            reason = .settings
        case let op where op.contains("admin"):
            reason = .admin
        case let op where op.contains("sensitive") || op.contains("private"):
            reason = .sensitiveData
        case let op where op.contains("emergency"):
            reason = .emergency
        default:
            reason = .unlock
        }
        
        return await authenticate(reason: reason)
    }
    
    func validateAuthentication() -> Bool {
        guard isBiometricEnabled else { return false }
        guard !isLocked else { return false }
        guard let lastAuth = lastAuthenticationTime else { return false }
        
        let timeout: TimeInterval = biometricSettings.autoLockTimeout
        return Date().timeIntervalSince(lastAuth) < timeout
    }
    
    func logout() {
        authenticationState = .unauthenticated
        lastAuthenticationTime = nil
        authenticationAttempts = 0
        
        updateAuthenticationState()
    }
    
    // MARK: - Analytics and Reporting
    
    func getBiometricReport() -> BiometricReport {
        let totalAuthentications = authenticationHistory.count
        let successfulAuthentications = authenticationHistory.filter { $0.success }.count
        let failedAuthentications = totalAuthentications - successfulAuthentications
        let successRate = totalAuthentications > 0 ? Double(successfulAuthentications) / Double(totalAuthentications) * 100 : 0
        
        let recentAuthentications = authenticationHistory.filter { Date().timeIntervalSince($0.timestamp) <= 86400 } // Last 24 hours
        let recentSuccessRate = recentAuthentications.count > 0 ? Double(recentAuthentications.filter { $0.success }.count) / Double(recentAuthentications.count) * 100 : 0
        
        let averageAuthenticationTime = authenticationHistory.isEmpty ? 0 : authenticationHistory.map { $0.duration }.reduce(0, +) / Double(totalAuthentications)
        
        return BiometricReport(
            biometricType: biometricType,
            isEnabled: isBiometricEnabled,
            securityLevel: securityLevel,
            totalAuthentications: totalAuthentications,
            successfulAuthentications: successfulAuthentications,
            failedAuthentications: failedAuthentications,
            successRate: successRate,
            recentSuccessRate: recentSuccessRate,
            averageAuthenticationTime: averageAuthenticationTime,
            isCurrentlyLocked: isLocked,
            lockReason: lockReason,
            lockExpiryTime: lockExpiryTime,
            generatedAt: Date()
        )
    }
    
    func getAuthenticationMetrics() -> AuthenticationMetrics {
        let last24Hours = authenticationHistory.filter { Date().timeIntervalSince($0.timestamp) <= 86400 }
        let last7Days = authenticationHistory.filter { Date().timeIntervalSince($0.timestamp) <= 604800 }
        
        let reasons = Dictionary(grouping: authenticationHistory) { $0.reason }
            .mapValues { $0.count }
        
        return AuthenticationMetrics(
            last24Hours: last24Hours.count,
            last7Days: last7Days.count,
            byReason: reasons.map { AuthenticationReasonMetrics(reason: $0.key, count: $0.value) },
            averageTime: authenticationHistory.isEmpty ? 0 : authenticationHistory.map { $0.duration }.reduce(0, +) / Double(authenticationHistory.count),
            successRate: authenticationHistory.isEmpty ? 0 : Double(authenticationHistory.filter { $0.success }.count) / Double(authenticationHistory.count) * 100
        )
    }
    
    deinit {
        // Clean up resources
    }
}

// MARK: - Data Structures

struct BiometricSettings: Codable {
    var isEnabled: Bool = false
    var securityLevel: BiometricService.SecurityLevel = .medium
    var autoLockTimeout: TimeInterval = 300 // 5 minutes
    var requireAuthenticationForTransactions: Bool = true
    var requireAuthenticationForSettings: Bool = true
    var requireAuthenticationForSensitiveData: Bool = true
    var enableBiometricLogging: Bool = true
    var maxAuthenticationHistory: Int = 100
    var enableFallbackPasscode: Bool = true
    var requireLiveDetection: Bool = false
    var enableAntiSpoofing: Bool = true
}

struct AuthenticationRecord: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let reason: BiometricService.AuthenticationReason
    let success: Bool
    let biometricType: BiometricService.BiometricType
    let duration: TimeInterval
}

struct BiometricReport {
    let biometricType: BiometricService.BiometricType
    let isEnabled: Bool
    let securityLevel: BiometricService.SecurityLevel
    let totalAuthentications: Int
    let successfulAuthentications: Int
    let failedAuthentications: Int
    let successRate: Double
    let recentSuccessRate: Double
    let averageAuthenticationTime: TimeInterval
    let isCurrentlyLocked: Bool
    let lockReason: String?
    let lockExpiryTime: Date?
    let generatedAt: Date
}

struct AuthenticationMetrics {
    let last24Hours: Int
    let last7Days: Int
    let byReason: [AuthenticationReasonMetrics]
    let averageTime: TimeInterval
    let successRate: Double
}

struct AuthenticationReasonMetrics {
    let reason: BiometricService.AuthenticationReason
    let count: Int
}
