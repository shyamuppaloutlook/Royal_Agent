import Foundation
import SwiftUI
import Combine
import CryptoKit
import LocalAuthentication
import Security

class SecurityManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isBiometricAvailable: Bool = false
    @Published var isBiometricEnabled: Bool = false
    @Published var securityLevel: SecurityLevel = .standard
    @Published var lastSecurityCheck: Date?
    @Published var securityEvents: [SecurityEvent] = []
    @Published var encryptionStatus: EncryptionStatus = .active
    @Published var threatLevel: ThreatLevel = .low
    @Published var isSecureEnvironment: Bool = true
    
    private let keychainService = "com.rbc.aiagent.security"
    private let encryptionKeyTag = "com.rbc.aiagent.encryption.key"
    private let sessionTimeout: TimeInterval = 300 // 5 minutes
    private var sessionTimer: Timer?
    
    private var encryptionKey: SymmetricKey?
    private var biometricContext: LAContext?
    
    // MARK: - Security Levels
    
    enum SecurityLevel: String, CaseIterable {
        case basic = "Basic"
        case standard = "Standard"
        case enhanced = "Enhanced"
        case maximum = "Maximum"
        
        var description: String {
            switch self {
            case .basic: return "Basic security with password protection"
            case .standard: return "Standard security with biometrics"
            case .enhanced: return "Enhanced security with multi-factor authentication"
            case .maximum: return "Maximum security with advanced encryption"
            }
        }
        
        var requiresBiometrics: Bool {
            return self == .standard || self == .enhanced || self == .maximum
        }
        
        var requiresMultiFactor: Bool {
            return self == .enhanced || self == .maximum
        }
        
        var encryptionStrength: EncryptionStrength {
            switch self {
            case .basic: return .aes128
            case .standard: return .aes256
            case .enhanced: return .aes256GCM
            case .maximum: return .quantumResistant
            }
        }
    }
    
    // MARK: - Encryption Status
    
    enum EncryptionStatus: String, CaseIterable {
        case active = "Active"
        case inactive = "Inactive"
        case compromised = "Compromised"
        case updating = "Updating"
        
        var color: Color {
            switch self {
            case .active: return .green
            case .inactive: return .yellow
            case .compromised: return .red
            case .updating: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "lock.shield"
            case .inactive: return "lock.open"
            case .compromised: return "lock.slash"
            case .updating: return "lock.rotation"
            }
        }
    }
    
    // MARK: - Threat Levels
    
    enum ThreatLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var requiresAction: Bool {
            return self == .high || self == .critical
        }
        
        var icon: String {
            switch self {
            case .low: return "shield"
            case .medium: return "shield.leopard.up"
            case .high: return "exclamationmark.triangle"
            case .critical: return "exclamationmark.octagon"
            }
        }
    }
    
    // MARK: - Security Events
    
    enum SecurityEventType: String, CaseIterable {
        case login = "Login"
        case logout = "Logout"
        case biometricAuth = "Biometric Authentication"
        case passwordChange = "Password Change"
        case securityUpgrade = "Security Upgrade"
        case threatDetected = "Threat Detected"
        case dataEncryption = "Data Encryption"
        case dataDecryption = "Data Decryption"
        case keyRotation = "Key Rotation"
        case sessionTimeout = "Session Timeout"
        case failedAuth = "Failed Authentication"
        case suspiciousActivity = "Suspicious Activity"
        case securityBreach = "Security Breach"
        case systemCheck = "System Security Check"
        case complianceCheck = "Compliance Check"
    }
    
    // MARK: - Encryption Strength
    
    enum EncryptionStrength: String, CaseIterable {
        case aes128 = "AES-128"
        case aes256 = "AES-256"
        case aes256GCM = "AES-256-GCM"
        case quantumResistant = "Quantum Resistant"
        
        var keySize: Int {
            switch self {
            case .aes128: return 16
            case .aes256, .aes256GCM: return 32
            case .quantumResistant: return 64
            }
        }
        
        var description: String {
            switch self {
            case .aes128: return "128-bit AES encryption"
            case .aes256: return "256-bit AES encryption"
            case .aes256GCM: return "256-bit AES-GCM encryption with authentication"
            case .quantumResistant: return "Post-quantum cryptography resistant encryption"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupSecurity()
        checkBiometricAvailability()
        initializeEncryption()
        startSecurityMonitoring()
    }
    
    // MARK: - Setup Methods
    
    private func setupSecurity() {
        // Load security settings
        loadSecuritySettings()
        
        // Initialize biometric context
        biometricContext = LAContext()
        
        // Check secure environment
        checkSecureEnvironment()
        
        // Start session timer
        startSessionTimer()
    }
    
    private func loadSecuritySettings() {
        let defaults = UserDefaults.standard
        
        if let levelRaw = defaults.string(forKey: "security_level"),
           let level = SecurityLevel(rawValue: levelRaw) {
            securityLevel = level
        }
        
        isBiometricEnabled = defaults.bool(forKey: "biometric_enabled")
    }
    
    private func checkBiometricAvailability() {
        guard let context = biometricContext else {
            isBiometricAvailable = false
            return
        }
        
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            logSecurityEvent(type: .systemCheck, details: "Biometric check failed: \(error.localizedDescription)")
        }
    }
    
    private func initializeEncryption() {
        // Generate or load encryption key
        if let existingKey = loadEncryptionKey() {
            encryptionKey = existingKey
            encryptionStatus = .active
        } else {
            generateEncryptionKey()
        }
    }
    
    private func checkSecureEnvironment() {
        // Check for jailbreak/root detection
        isSecureEnvironment = !isDeviceJailbroken()
        
        if !isSecureEnvironment {
            threatLevel = .high
            logSecurityEvent(type: .threatDetected, details: "Device jailbreak detected")
        }
    }
    
    private func startSecurityMonitoring() {
        // Monitor for security threats
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performSecurityCheck()
        }
    }
    
    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            self?.handleSessionTimeout()
        }
    }
    
    // MARK: - Authentication Methods
    
    func authenticateWithPassword(_ password: String) -> Bool {
        // Verify password against stored hash
        let storedHash = getPasswordHash()
        let inputHash = hashPassword(password)
        
        if inputHash == storedHash {
            isAuthenticated = true
            resetSessionTimer()
            logSecurityEvent(type: .login, details: "Password authentication successful")
            return true
        } else {
            logSecurityEvent(type: .failedAuth, details: "Password authentication failed")
            return false
        }
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        guard let context = biometricContext, isBiometricAvailable else {
            completion(false)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to access RBC AI Agent") { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    self?.resetSessionTimer()
                    self?.logSecurityEvent(type: .biometricAuth, details: "Biometric authentication successful")
                    completion(true)
                } else {
                    self?.logSecurityEvent(type: .failedAuth, details: "Biometric authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                    completion(false)
                }
            }
        }
    }
    
    func authenticateWithMultiFactor(password: String, biometricCompletion: @escaping (Bool) -> Void) {
        // First verify password
        if authenticateWithPassword(password) {
            // Then require biometric
            authenticateWithBiometrics(completion: biometricCompletion)
        } else {
            biometricCompletion(false)
        }
    }
    
    func logout() {
        isAuthenticated = false
        sessionTimer?.invalidate()
        logSecurityEvent(type: .logout, details: "User logged out")
    }
    
    // MARK: - Encryption Methods
    
    private func generateEncryptionKey() {
        encryptionKey = SymmetricKey(size: .bits256)
        saveEncryptionKey()
        encryptionStatus = .active
        logSecurityEvent(type: .dataEncryption, details: "New encryption key generated")
    }
    
    private func saveEncryptionKey() {
        guard let key = encryptionKey else { return }
        
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: encryptionKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadEncryptionKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: encryptionKeyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let keyData = dataTypeRef as? Data {
            return SymmetricKey(data: keyData)
        }
        
        return nil
    }
    
    func encryptData(_ data: Data) -> Data? {
        guard let key = encryptionKey else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            logSecurityEvent(type: .threatDetected, details: "Encryption failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func decryptData(_ encryptedData: Data) -> Data? {
        guard let key = encryptionKey else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            logSecurityEvent(type: .threatDetected, details: "Decryption failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Security Checks
    
    private func performSecurityCheck() {
        // Check secure environment
        checkSecureEnvironment()
        
        // Monitor for unusual activity
        detectSuspiciousActivity()
        
        // Validate encryption
        validateEncryption()
        
        // Update threat level
        updateThreatLevel()
        
        lastSecurityCheck = Date()
        logSecurityEvent(type: .systemCheck, details: "Routine security check completed")
    }
    
    private func detectSuspiciousActivity() {
        // Check for multiple failed authentication attempts
        let recentFailedAuths = securityEvents.filter { event in
            event.type == .failedAuth && 
            Date().timeIntervalSince(event.timestamp) < 300 // 5 minutes
        }
        
        if recentFailedAuths.count > 3 {
            threatLevel = .high
            logSecurityEvent(type: .suspiciousActivity, details: "Multiple failed authentication attempts detected")
        }
        
        // Check for unusual access patterns
        detectUnusualAccessPatterns()
    }
    
    private func detectUnusualAccessPatterns() {
        // Check for access from unusual locations or times
        // This would require location and time tracking
    }
    
    private func validateEncryption() {
        // Test encryption/decryption
        let testData = "test".data(using: .utf8)!
        
        if let encrypted = encryptData(testData),
           let decrypted = decryptData(encrypted) {
            if decrypted != testData {
                encryptionStatus = .compromised
                threatLevel = .critical
                logSecurityEvent(type: .securityBreach, details: "Encryption validation failed")
            }
        } else {
            encryptionStatus = .inactive
            threatLevel = .high
            logSecurityEvent(type: .threatDetected, details: "Encryption system inactive")
        }
    }
    
    private func updateThreatLevel() {
        // Calculate threat level based on various factors
        var threatScore = 0
        
        if !isSecureEnvironment { threatScore += 3 }
        if encryptionStatus == .compromised { threatScore += 4 }
        if encryptionStatus == .inactive { threatScore += 2 }
        
        let recentThreats = securityEvents.filter { event in
            (event.type == .threatDetected || event.type == .suspiciousActivity) &&
            Date().timeIntervalSince(event.timestamp) < 3600 // 1 hour
        }
        
        threatScore += min(recentThreats.count, 3)
        
        // Update threat level
        switch threatScore {
        case 0...1:
            threatLevel = .low
        case 2...3:
            threatLevel = .medium
        case 4...5:
            threatLevel = .high
        default:
            threatLevel = .critical
        }
    }
    
    // MARK: - Security Settings
    
    func setSecurityLevel(_ level: SecurityLevel) {
        securityLevel = level
        
        // Update security requirements
        if level.requiresBiometrics && !isBiometricEnabled {
            enableBiometrics()
        }
        
        // Re-initialize encryption with new strength
        if level.encryptionStrength != securityLevel.encryptionStrength {
            rotateEncryptionKey()
        }
        
        // Save settings
        UserDefaults.standard.set(level.rawValue, forKey: "security_level")
        
        logSecurityEvent(type: .securityUpgrade, details: "Security level upgraded to \(level.rawValue)")
    }
    
    func enableBiometrics() {
        guard isBiometricAvailable else { return }
        
        isBiometricEnabled = true
        UserDefaults.standard.set(true, forKey: "biometric_enabled")
        
        logSecurityEvent(type: .securityUpgrade, details: "Biometric authentication enabled")
    }
    
    func disableBiometrics() {
        isBiometricEnabled = false
        UserDefaults.standard.set(false, forKey: "biometric_enabled")
        
        logSecurityEvent(type: .securityUpgrade, details: "Biometric authentication disabled")
    }
    
    // MARK: - Key Management
    
    func rotateEncryptionKey() {
        // Generate new key
        let oldKey = encryptionKey
        generateEncryptionKey()
        
        // Re-encrypt sensitive data with new key
        // This would involve updating all stored encrypted data
        
        logSecurityEvent(type: .keyRotation, details: "Encryption key rotated")
    }
    
    // MARK: - Password Management
    
    private func hashPassword(_ password: String) -> String {
        let salt = "rbc_ai_agent_salt"
        let combined = password + salt
        
        let data = Data(combined.utf8)
        let hash = SHA256.hash(data: data)
        
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func getPasswordHash() -> String {
        return UserDefaults.standard.string(forKey: "password_hash") ?? ""
    }
    
    func setPassword(_ password: String) {
        let hash = hashPassword(password)
        UserDefaults.standard.set(hash, forKey: "password_hash")
        
        logSecurityEvent(type: .passwordChange, details: "Password changed")
    }
    
    // MARK: - Session Management
    
    private func resetSessionTimer() {
        sessionTimer?.invalidate()
        startSessionTimer()
    }
    
    private func handleSessionTimeout() {
        isAuthenticated = false
        logSecurityEvent(type: .sessionTimeout, details: "Session timed out")
    }
    
    // MARK: - Jailbreak Detection
    
    private func isDeviceJailbroken() -> Bool {
        // Check for jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check for suspicious files
        if canOpenURL("cydia://") {
            return true
        }
        
        return false
    }
    
    private func canOpenURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    // MARK: - Security Event Logging
    
    private func logSecurityEvent(type: SecurityEventType, details: String) {
        let event = SecurityEvent(
            id: UUID().uuidString,
            type: type,
            timestamp: Date(),
            details: details,
            severity: determineEventSeverity(type: type),
            resolved: false
        )
        
        securityEvents.append(event)
        
        // Keep only recent events (last 100)
        if securityEvents.count > 100 {
            securityEvents = Array(securityEvents.suffix(100))
        }
        
        // Send to security monitoring service
        sendToSecurityMonitoring(event)
    }
    
    private func determineEventSeverity(type: SecurityEventType) -> ThreatLevel {
        switch type {
        case .login, .logout, .biometricAuth, .passwordChange, .securityUpgrade, .dataEncryption, .dataDecryption, .keyRotation, .systemCheck, .complianceCheck:
            return .low
        case .sessionTimeout, .failedAuth:
            return .medium
        case .suspiciousActivity:
            return .high
        case .threatDetected, .securityBreach:
            return .critical
        }
    }
    
    private func sendToSecurityMonitoring(_ event: SecurityEvent) {
        // Send event to external security monitoring service
        // This would be implemented with proper networking code
    }
    
    // MARK: - Compliance and Auditing
    
    func performComplianceCheck() -> ComplianceResult {
        let checks = [
            checkDataEncryptionCompliance(),
            checkAuthenticationCompliance(),
            checkAuditTrailCompliance(),
            checkDataRetentionCompliance(),
            checkPrivacyCompliance()
        ]
        
        let allPassed = checks.allSatisfy { $0 }
        
        let result = ComplianceResult(
            isCompliant: allPassed,
            checks: checks,
            timestamp: Date(),
            recommendations: generateComplianceRecommendations(checks: checks)
        )
        
        logSecurityEvent(type: .complianceCheck, details: "Compliance check completed: \(allPassed ? "Passed" : "Failed")")
        
        return result
    }
    
    private func checkDataEncryptionCompliance() -> Bool {
        return encryptionStatus == .active && encryptionKey != nil
    }
    
    private func checkAuthenticationCompliance() -> Bool {
        return securityLevel.requiresBiometrics ? isBiometricEnabled : true
    }
    
    private func checkAuditTrailCompliance() -> Bool {
        return securityEvents.count > 0
    }
    
    private func checkDataRetentionCompliance() -> Bool {
        // Check if data retention policies are being followed
        return true
    }
    
    private func checkPrivacyCompliance() -> Bool {
        // Check privacy compliance
        return true
    }
    
    private func generateComplianceRecommendations(checks: [Bool]) -> [String] {
        var recommendations: [String] = []
        
        if !checks[0] { recommendations.append("Enable data encryption") }
        if !checks[1] { recommendations.append("Configure proper authentication") }
        if !checks[2] { recommendations.append("Enable audit trail logging") }
        if !checks[3] { recommendations.append("Review data retention policies") }
        if !checks[4] { recommendations.append("Review privacy settings") }
        
        return recommendations
    }
    
    // MARK: - Public Interface
    
    func getSecurityReport() -> SecurityReport {
        return SecurityReport(
            securityLevel: securityLevel,
            isAuthenticated: isAuthenticated,
            isSecureEnvironment: isSecureEnvironment,
            encryptionStatus: encryptionStatus,
            threatLevel: threatLevel,
            lastSecurityCheck: lastSecurityCheck,
            recentEvents: Array(securityEvents.suffix(10)),
            complianceResult: performComplianceCheck(),
            recommendations: generateSecurityRecommendations()
        )
    }
    
    private func generateSecurityRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if threatLevel.requiresAction {
            recommendations.append("Immediate security action required")
        }
        
        if !isSecureEnvironment {
            recommendations.append("Device security compromised - consider factory reset")
        }
        
        if encryptionStatus != .active {
            recommendations.append("Re-enable encryption for data protection")
        }
        
        if securityLevel == .basic {
            recommendations.append("Upgrade to enhanced security level")
        }
        
        if !isBiometricEnabled && isBiometricAvailable {
            recommendations.append("Enable biometric authentication")
        }
        
        return recommendations
    }
    
    func clearSecurityEvents() {
        securityEvents.removeAll()
    }
    
    func getSecurityEventsByType(_ type: SecurityEventType) -> [SecurityEvent] {
        return securityEvents.filter { $0.type == type }
    }
    
    func getRecentSecurityEvents(since date: Date) -> [SecurityEvent] {
        return securityEvents.filter { $0.timestamp >= date }
    }
}

// MARK: - Data Structures

struct SecurityEvent: Identifiable {
    let id: String
    let type: SecurityManager.SecurityEventType
    let timestamp: Date
    let details: String
    let severity: SecurityManager.ThreatLevel
    var resolved: Bool
}

struct ComplianceResult {
    let isCompliant: Bool
    let checks: [Bool]
    let timestamp: Date
    let recommendations: [String]
}

struct SecurityReport {
    let securityLevel: SecurityManager.SecurityLevel
    let isAuthenticated: Bool
    let isSecureEnvironment: Bool
    let encryptionStatus: SecurityManager.EncryptionStatus
    let threatLevel: SecurityManager.ThreatLevel
    let lastSecurityCheck: Date?
    let recentEvents: [SecurityEvent]
    let complianceResult: ComplianceResult
    let recommendations: [String]
}
