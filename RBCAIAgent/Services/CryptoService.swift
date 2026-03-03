import Foundation
import SwiftUI
import Combine
import CryptoKit
import Security

class CryptoService: ObservableObject {
    @Published var encryptionStatus: EncryptionStatus = .idle
    @Published var isEncryptionEnabled: Bool = true
    @Published var encryptionAlgorithm: EncryptionAlgorithm = .aes256
    @Published var keySize: KeySize = .bits256
    @Published var encryptionLevel: EncryptionLevel = .standard
    @Published var cryptoSettings: CryptoSettings = CryptoSettings()
    @Published var encryptionHistory: [EncryptionRecord] = []
    @Published var keyManagementStatus: KeyManagementStatus = .secure
    @Published var activeKeys: [CryptoKey] = []
    @Published var keyRotationEnabled: Bool = true
    @Published var lastKeyRotation: Date?
    @Published var securityScore: Double = 0.0
    
    private var masterKey: SymmetricKey?
    private var keyStore: [String: SymmetricKey] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Encryption Algorithms
    
    enum EncryptionAlgorithm: String, CaseIterable, Identifiable {
        case aes256 = "AES-256"
        case chacha20 = "ChaCha20"
        case aesGCM = "AES-GCM"
        case rsa = "RSA"
        case ecc = "ECC"
        
        var id: String { return rawValue }
        
        var displayName: String {
            switch self {
            case .aes256: return "AES-256"
            case .chacha20: return "ChaCha20"
            case .aesGCM: return "AES-GCM"
            case .rsa: return "RSA"
            case .ecc: return "ECC"
            }
        }
        
        var description: String {
            switch self {
            case .aes256: return "Advanced Encryption Standard with 256-bit key"
            case .chacha20: return "Stream cipher optimized for mobile devices"
            case .aesGCM: return "AES with Galois/Counter Mode for authenticated encryption"
            case .rsa: return "Public-key cryptography for digital signatures"
            case .ecc: return "Elliptic Curve Cryptography for efficient key exchange"
            }
        }
        
        var isSymmetric: Bool {
            switch self {
            case .aes256, .chacha20, .aesGCM: return true
            case .rsa, .ecc: return false
            }
        }
        
        var keyType: KeyType {
            switch self {
            case .aes256, .chacha20, .aesGCM: return .symmetric
            case .rsa: return .asymmetricRSA
            case .ecc: return .asymmetricECC
            }
        }
    }
    
    // MARK: - Key Sizes
    
    enum KeySize: String, CaseIterable, Identifiable {
        case bits128 = "128-bit"
        case bits192 = "192-bit"
        case bits256 = "256-bit"
        case bits512 = "512-bit"
        case bits1024 = "1024-bit"
        case bits2048 = "2048-bit"
        case bits4096 = "4096-bit"
        
        var id: String { return rawValue }
        
        var bitLength: Int {
            switch self {
            case .bits128: return 128
            case .bits192: return 192
            case .bits256: return 256
            case .bits512: return 512
            case .bits1024: return 1024
            case .bits2048: return 2048
            case .bits4096: return 4096
            }
        }
        
        var byteLength: Int {
            return bitLength / 8
        }
        
        var securityLevel: EncryptionLevel {
            switch self {
            case .bits128: return .basic
            case .bits192: return .standard
            case .bits256: return .high
            case .bits512: return .veryHigh
            case .bits1024: return .military
            case .bits2048: return .military
            case .bits4096: return .maximum
            }
        }
    }
    
    // MARK: - Encryption Levels
    
    enum EncryptionLevel: String, CaseIterable {
        case basic = "Basic"
        case standard = "Standard"
        case high = "High"
        case veryHigh = "Very High"
        case military = "Military"
        case maximum = "Maximum"
        
        var id: String { return rawValue }
        
        var description: String {
            switch self {
            case .basic: return "Basic encryption for non-sensitive data"
            case .standard: return "Standard encryption for general use"
            case .high: return "High-strength encryption for sensitive data"
            case .veryHigh: return "Very high-strength encryption for critical data"
            case .military: return "Military-grade encryption for maximum security"
            case .maximum: return "Maximum encryption strength available"
            }
        }
        
        var recommendedKeySize: KeySize {
            switch self {
            case .basic: return .bits128
            case .standard: return .bits192
            case .high: return .bits256
            case .veryHigh: return .bits512
            case .military: return .bits2048
            case .maximum: return .bits4096
            }
        }
        
        var keyRotationInterval: TimeInterval {
            switch self {
            case .basic: return 86400 * 365 // 1 year
            case .standard: return 86400 * 180 // 6 months
            case .high: return 86400 * 90 // 3 months
            case .veryHigh: return 86400 * 30 // 1 month
            case .military: return 86400 * 14 // 2 weeks
            case .maximum: return 86400 * 7 // 1 week
            }
        }
    }
    
    // MARK: - Key Types
    
    enum KeyType: String, CaseIterable {
        case symmetric = "Symmetric"
        case asymmetricRSA = "RSA"
        case asymmetricECC = "ECC"
        case hmac = "HMAC"
        case hash = "Hash"
        
        var id: String { return rawValue }
        
        var displayName: String {
            switch self {
            case .symmetric: return "Symmetric Key"
            case .asymmetricRSA: return "RSA Key Pair"
            case .asymmetricECC: return "ECC Key Pair"
            case .hmac: return "HMAC Key"
            case .hash: return "Hash Key"
            }
        }
    }
    
    // MARK: - Encryption Status
    
    enum EncryptionStatus: String, CaseIterable {
        case idle = "Idle"
        case encrypting = "Encrypting"
        case decrypting = "Decrypting"
        case generatingKey = "Generating Key"
        case rotatingKey = "Rotating Key"
        case error = "Error"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .idle: return .gray
            case .encrypting: return .blue
            case .decrypting: return .green
            case .generatingKey: return .orange
            case .rotatingKey: return .purple
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "lock"
            case .encrypting: return "lock.shield"
            case .decrypting: return "lock.open"
            case .generatingKey: return "key"
            case .rotatingKey: return "arrow.triangle.2.circlepath"
            case .error: return "xmark.shield"
            }
        }
    }
    
    // MARK: - Key Management Status
    
    enum KeyManagementStatus: String, CaseIterable {
        case secure = "Secure"
        case warning = "Warning"
        case compromised = "Compromised"
        case expired = "Expired"
        case rotating = "Rotating"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .secure: return .green
            case .warning: return .orange
            case .compromised: return .red
            case .expired: return .purple
            case .rotating: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .secure: return "checkmark.shield"
            case .warning: return "exclamationmark.triangle"
            case .compromised: return "xmark.shield"
            case .expired: return "clock"
            case .rotating: return "arrow.triangle.2.circlepath"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupCryptoService()
        loadCryptoSettings()
        initializeMasterKey()
        setupKeyRotation()
        calculateSecurityScore()
    }
    
    private func setupCryptoService() {
        // Initialize cryptographic components
    }
    
    private func loadCryptoSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "crypto_settings"),
           let settings = try? JSONDecoder().decode(CryptoSettings.self, from: data) {
            cryptoSettings = settings
            isEncryptionEnabled = settings.isEncryptionEnabled
            encryptionAlgorithm = settings.encryptionAlgorithm
            keySize = settings.keySize
            encryptionLevel = settings.encryptionLevel
            keyRotationEnabled = settings.keyRotationEnabled
        }
        
        if let data = defaults.data(forKey: "encryption_history"),
           let history = try? JSONDecoder().decode([EncryptionRecord].self, from: data) {
            encryptionHistory = history
        }
        
        if let data = defaults.data(forKey: "active_keys"),
           let keys = try? JSONDecoder().decode([CryptoKey].self, from: data) {
            activeKeys = keys
        }
        
        if let timestamp = defaults.object(forKey: "last_key_rotation") as? Date {
            lastKeyRotation = timestamp
        }
    }
    
    private func saveCryptoSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(cryptoSettings) {
            defaults.set(data, forKey: "crypto_settings")
        }
        
        if let data = try? JSONEncoder().encode(encryptionHistory) {
            defaults.set(data, forKey: "encryption_history")
        }
        
        if let data = try? JSONEncoder().encode(activeKeys) {
            defaults.set(data, forKey: "active_keys")
        }
        
        if let rotation = lastKeyRotation {
            defaults.set(rotation, forKey: "last_key_rotation")
        }
    }
    
    private func initializeMasterKey() {
        if let storedKey = loadKeyFromKeychain(identifier: "master_key") {
            masterKey = storedKey
        } else {
            masterKey = SymmetricKey(size: .bits256)
            saveKeyToKeychain(key: masterKey!, identifier: "master_key")
        }
    }
    
    private func setupKeyRotation() {
        guard keyRotationEnabled else { return }
        
        // Check if key rotation is needed
        if let lastRotation = lastKeyRotation {
            let timeSinceRotation = Date().timeIntervalSince(lastRotation)
            if timeSinceRotation >= encryptionLevel.keyRotationInterval {
                rotateKeys()
            }
        }
        
        // Schedule periodic key rotation checks
        Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.checkKeyRotation()
        }
    }
    
    private func checkKeyRotation() {
        guard keyRotationEnabled, let lastRotation = lastKeyRotation else { return }
        
        let timeSinceRotation = Date().timeIntervalSince(lastRotation)
        if timeSinceRotation >= encryptionLevel.keyRotationInterval {
            rotateKeys()
        }
    }
    
    private func calculateSecurityScore() {
        var score: Double = 0.0
        
        // Base score for having encryption enabled
        if isEncryptionEnabled {
            score += 20.0
        }
        
        // Score for encryption algorithm strength
        switch encryptionAlgorithm {
        case .aes256, .aesGCM:
            score += 20.0
        case .chacha20:
            score += 18.0
        case .rsa:
            score += 15.0
        case .ecc:
            score += 17.0
        }
        
        // Score for key size
        switch keySize {
        case .bits256, .bits512:
            score += 20.0
        case .bits192:
            score += 15.0
        case .bits128:
            score += 10.0
        case .bits1024, .bits2048, .bits4096:
            score += 25.0
        }
        
        // Score for encryption level
        switch encryptionLevel {
        case .maximum, .military:
            score += 20.0
        case .veryHigh:
            score += 15.0
        case .high:
            score += 10.0
        case .standard:
            score += 5.0
        case .basic:
            score += 2.0
        }
        
        // Score for key rotation
        if keyRotationEnabled {
            score += 10.0
        }
        
        // Score for key management status
        switch keyManagementStatus {
        case .secure:
            score += 10.0
        case .warning:
            score += 5.0
        case .compromised, .expired:
            score += 0.0
        case .rotating:
            score += 7.0
        }
        
        securityScore = min(score, 100.0)
    }
    
    // MARK: - Encryption Operations
    
    func encrypt(_ data: Data, key: SymmetricKey? = nil) -> EncryptionResult? {
        guard isEncryptionEnabled else { return nil }
        
        encryptionStatus = .encrypting
        let startTime = Date()
        
        let encryptionKey = key ?? masterKey!
        let result = performEncryption(data: data, key: encryptionKey)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Record encryption operation
        let record = EncryptionRecord(
            id: UUID().uuidString,
            operation: .encryption,
            algorithm: encryptionAlgorithm,
            keySize: keySize,
            dataSize: data.count,
            success: result != nil,
            timestamp: Date(),
            duration: duration
        )
        
        encryptionHistory.append(record)
        
        // Keep only recent history (last 100)
        if encryptionHistory.count > 100 {
            encryptionHistory = Array(encryptionHistory.suffix(100))
        }
        
        encryptionStatus = .idle
        saveCryptoSettings()
        
        return result
    }
    
    private func performEncryption(data: Data, key: SymmetricKey) -> EncryptionResult? {
        switch encryptionAlgorithm {
        case .aes256:
            return encryptAES256(data: data, key: key)
        case .chacha20:
            return encryptChaCha20(data: data, key: key)
        case .aesGCM:
            return encryptAESGCM(data: data, key: key)
        case .rsa, .ecc:
            return nil // Asymmetric encryption handled separately
        }
    }
    
    private func encryptAES256(data: Data, key: SymmetricKey) -> EncryptionResult? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            let encryptedData = sealedBox.combined
            
            return EncryptionResult(
                encryptedData: encryptedData,
                nonce: Data(sealedBox.nonce),
                tag: Data(sealedBox.tag),
                algorithm: .aes256,
                success: true
            )
        } catch {
            print("AES-256 encryption failed: \(error)")
            return nil
        }
    }
    
    private func encryptChaCha20(data: Data, key: SymmetricKey) -> EncryptionResult? {
        do {
            let sealedBox = try ChaChaPoly.seal(data, using: key)
            let encryptedData = sealedBox.combined
            
            return EncryptionResult(
                encryptedData: encryptedData,
                nonce: Data(sealedBox.nonce),
                tag: Data(sealedBox.tag),
                algorithm: .chacha20,
                success: true
            )
        } catch {
            print("ChaCha20 encryption failed: \(error)")
            return nil
        }
    }
    
    private func encryptAESGCM(data: Data, key: SymmetricKey) -> EncryptionResult? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            let encryptedData = sealedBox.combined
            
            return EncryptionResult(
                encryptedData: encryptedData,
                nonce: Data(sealedBox.nonce),
                tag: Data(sealedBox.tag),
                algorithm: .aesGCM,
                success: true
            )
        } catch {
            print("AES-GCM encryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Decryption Operations
    
    func decrypt(_ result: EncryptionResult, key: SymmetricKey? = nil) -> Data? {
        guard isEncryptionEnabled else { return nil }
        
        encryptionStatus = .decrypting
        let startTime = Date()
        
        let decryptionKey = key ?? masterKey!
        let decryptedData = performDecryption(result: result, key: decryptionKey)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Record decryption operation
        let record = EncryptionRecord(
            id: UUID().uuidString,
            operation: .decryption,
            algorithm: result.algorithm,
            keySize: keySize,
            dataSize: result.encryptedData.count,
            success: decryptedData != nil,
            timestamp: Date(),
            duration: duration
        )
        
        encryptionHistory.append(record)
        
        // Keep only recent history (last 100)
        if encryptionHistory.count > 100 {
            encryptionHistory = Array(encryptionHistory.suffix(100))
        }
        
        encryptionStatus = .idle
        saveCryptoSettings()
        
        return decryptedData
    }
    
    private func performDecryption(result: EncryptionResult, key: SymmetricKey) -> Data? {
        switch result.algorithm {
        case .aes256, .aesGCM:
            return decryptAESGCM(result: result, key: key)
        case .chacha20:
            return decryptChaCha20(result: result, key: key)
        case .rsa, .ecc:
            return nil // Asymmetric decryption handled separately
        }
    }
    
    private func decryptAESGCM(result: EncryptionResult, key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: result.encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("AES-GCM decryption failed: \(error)")
            return nil
        }
    }
    
    private func decryptChaCha20(result: EncryptionResult, key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try ChaChaPoly.SealedBox(combined: result.encryptedData)
            let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
            return decryptedData
        } catch {
            print("ChaCha20 decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Key Management
    
    func generateKey(identifier: String, type: KeyType = .symmetric) -> CryptoKey? {
        encryptionStatus = .generatingKey
        
        let key: CryptoKey
        
        switch type {
        case .symmetric:
            let symmetricKey = SymmetricKey(size: .bits256)
            key = CryptoKey(
                id: UUID().uuidString,
                identifier: identifier,
                type: type,
                algorithm: .aes256,
                keySize: .bits256,
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(encryptionLevel.keyRotationInterval),
                isActive: true
            )
            
            // Store the key securely
            saveKeyToKeychain(key: symmetricKey, identifier: identifier)
            
        case .asymmetricRSA, .asymmetricECC, .hmac, .hash:
            // For simplicity, we'll focus on symmetric keys in this implementation
            key = CryptoKey(
                id: UUID().uuidString,
                identifier: identifier,
                type: type,
                algorithm: .aes256,
                keySize: .bits256,
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(encryptionLevel.keyRotationInterval),
                isActive: true
            )
        }
        
        activeKeys.append(key)
        encryptionStatus = .idle
        saveCryptoSettings()
        
        return key
    }
    
    func rotateKeys() {
        encryptionStatus = .rotatingKey
        
        // Rotate master key
        let newMasterKey = SymmetricKey(size: .bits256)
        
        // Re-encrypt all data with new key (simplified for this example)
        if let oldMasterKey = masterKey {
            // In a real implementation, you would re-encrypt all encrypted data
            // For now, we'll just replace the key
        }
        
        masterKey = newMasterKey
        saveKeyToKeychain(key: newMasterKey, identifier: "master_key")
        
        // Update key rotation timestamp
        lastKeyRotation = Date()
        
        // Update active keys
        for i in activeKeys.indices {
            activeKeys[i].isActive = false
            activeKeys[i].expiresAt = Date()
        }
        
        // Generate new keys
        for key in activeKeys.filter({ $0.isActive }) {
            generateKey(identifier: key.identifier, type: key.type)
        }
        
        encryptionStatus = .idle
        saveCryptoSettings()
        calculateSecurityScore()
    }
    
    private func saveKeyToKeychain(key: SymmetricKey, identifier: String) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: identifier.data(using: .utf8)!,
            kSecValueData as String: keyData
        ]
        
        // Delete any existing key
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Failed to save key to keychain: \(status)")
        }
    }
    
    private func loadKeyFromKeychain(identifier: String) -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: identifier.data(using: .utf8)!,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }
        
        return nil
    }
    
    // MARK: - Hash Operations
    
    func hash(_ data: Data, algorithm: HashAlgorithm = .sha256) -> Data? {
        switch algorithm {
        case .sha256:
            return Data(SHA256.hash(data: data))
        case .sha384:
            return Data(SHA384.hash(data: data))
        case .sha512:
            return Data(SHA512.hash(data: data))
        }
    }
    
    func generateHMAC(for data: Data, key: SymmetricKey) -> Data? {
        return Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
    }
    
    // MARK: - Settings Management
    
    func updateCryptoSettings(_ settings: CryptoSettings) {
        cryptoSettings = settings
        isEncryptionEnabled = settings.isEncryptionEnabled
        encryptionAlgorithm = settings.encryptionAlgorithm
        keySize = settings.keySize
        encryptionLevel = settings.encryptionLevel
        keyRotationEnabled = settings.keyRotationEnabled
        
        saveCryptoSettings()
        calculateSecurityScore()
    }
    
    func enableEncryption() {
        isEncryptionEnabled = true
        cryptoSettings.isEncryptionEnabled = true
        saveCryptoSettings()
        calculateSecurityScore()
    }
    
    func disableEncryption() {
        isEncryptionEnabled = false
        cryptoSettings.isEncryptionEnabled = false
        saveCryptoSettings()
        calculateSecurityScore()
    }
    
    // MARK: - Analytics and Reporting
    
    func getCryptoReport() -> CryptoReport {
        let totalOperations = encryptionHistory.count
        let successfulOperations = encryptionHistory.filter { $0.success }.count
        let encryptionOperations = encryptionHistory.filter { $0.operation == .encryption }.count
        let decryptionOperations = encryptionHistory.filter { $0.operation == .decryption }.count
        
        let averageOperationTime = encryptionHistory.isEmpty ? 0 : encryptionHistory.map { $0.duration }.reduce(0, +) / Double(totalOperations)
        
        let totalDataEncrypted = encryptionHistory.filter { $0.operation == .encryption }.map { $0.dataSize }.reduce(0, +)
        
        return CryptoReport(
            encryptionAlgorithm: encryptionAlgorithm,
            keySize: keySize,
            encryptionLevel: encryptionLevel,
            isEncryptionEnabled: isEncryptionEnabled,
            totalOperations: totalOperations,
            successfulOperations: successfulOperations,
            encryptionOperations: encryptionOperations,
            decryptionOperations: decryptionOperations,
            averageOperationTime: averageOperationTime,
            totalDataEncrypted: totalDataEncrypted,
            activeKeysCount: activeKeys.filter { $0.isActive }.count,
            keyManagementStatus: keyManagementStatus,
            lastKeyRotation: lastKeyRotation,
            securityScore: securityScore,
            generatedAt: Date()
        )
    }
    
    deinit {
        // Clean up resources
    }
}

// MARK: - Data Structures

struct EncryptionResult: Codable {
    let encryptedData: Data
    let nonce: Data
    let tag: Data
    let algorithm: CryptoService.EncryptionAlgorithm
    let success: Bool
}

struct CryptoKey: Identifiable, Codable {
    let id: String
    let identifier: String
    let type: CryptoService.KeyType
    let algorithm: CryptoService.EncryptionAlgorithm
    let keySize: CryptoService.KeySize
    let createdAt: Date
    var expiresAt: Date
    var isActive: Bool
    var lastUsed: Date?
}

struct EncryptionRecord: Identifiable, Codable {
    let id: String
    let operation: EncryptionOperation
    let algorithm: CryptoService.EncryptionAlgorithm
    let keySize: CryptoService.KeySize
    let dataSize: Int
    let success: Bool
    let timestamp: Date
    let duration: TimeInterval
}

enum EncryptionOperation: String, Codable {
    case encryption = "Encryption"
    case decryption = "Decryption"
    case keyGeneration = "Key Generation"
    case keyRotation = "Key Rotation"
}

enum HashAlgorithm: String, CaseIterable {
    case sha256 = "SHA-256"
    case sha384 = "SHA-384"
    case sha512 = "SHA-512"
}

struct CryptoSettings: Codable {
    var isEncryptionEnabled: Bool = true
    var encryptionAlgorithm: CryptoService.EncryptionAlgorithm = .aes256
    var keySize: CryptoService.KeySize = .bits256
    var encryptionLevel: CryptoService.EncryptionLevel = .standard
    var keyRotationEnabled: Bool = true
    var autoKeyRotation: Bool = true
    var secureKeyStorage: Bool = true
    var enableLogging: Bool = true
    var maxHistoryEntries: Int = 100
    var enableHardwareAcceleration: Bool = true
    var memoryProtection: Bool = true
    var secureDeletion: Bool = true
}

struct CryptoReport {
    let encryptionAlgorithm: CryptoService.EncryptionAlgorithm
    let keySize: CryptoService.KeySize
    let encryptionLevel: CryptoService.EncryptionLevel
    let isEncryptionEnabled: Bool
    let totalOperations: Int
    let successfulOperations: Int
    let encryptionOperations: Int
    let decryptionOperations: Int
    let averageOperationTime: TimeInterval
    let totalDataEncrypted: Int
    let activeKeysCount: Int
    let keyManagementStatus: CryptoService.KeyManagementStatus
    let lastKeyRotation: Date?
    let securityScore: Double
    let generatedAt: Date
}
