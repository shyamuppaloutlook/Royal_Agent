import Foundation
import SwiftUI
import Combine
import AuthenticationServices

class RBCIntegrationService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var availableAccounts: [RBCAccount] = []
    @Published var connectedAccounts: [RBCAccount] = []
    @Published var transactions: [RBCTransaction] = []
    @Published var userProfile: RBCUserProfile?
    @Published var syncErrors: [SyncError] = []
    @Published var apiLimits: APILimits?
    
    // MARK: - Configuration
    
    private let baseURL = "https://api.rbc.com/v1"
    private let clientID = "rbc_ai_agent_ios"
    private let redirectURI = "rbcaiagent://auth/callback"
    private let scopes = ["accounts.read", "transactions.read", "profile.read", "insights.read"]
    
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiryDate: Date?
    
    private let keychainService = "com.rbc.aiagent.keys"
    private let userDefaults = UserDefaults.standard
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Connection Status
    
    enum ConnectionStatus: String, CaseIterable {
        case disconnected = "Disconnected"
        case connecting = "Connecting"
        case connected = "Connected"
        case syncing = "Syncing"
        case error = "Error"
        case limited = "Limited Access"
    }
    
    // MARK: - Integration Types
    
    enum IntegrationType: String, CaseIterable {
        case fullAPI = "Full API Access"
        case dataExport = "Data Export Only"
        case readOnly = "Read Only"
        case insights = "Insights Only"
        case webhook = "Webhook Integration"
    }
    
    // MARK: - Sync Types
    
    enum SyncType: String, CaseIterable {
        case full = "Full Sync"
        case incremental = "Incremental"
        case realtime = "Real-time"
        case scheduled = "Scheduled"
        case manual = "Manual Only"
    }
    
    // MARK: - Error Types
    
    enum IntegrationError: Error, LocalizedError {
        case authenticationFailed
        case tokenExpired
        case networkError
        case apiLimitExceeded
        case invalidCredentials
        case accessDenied
        case serverError
        case dataCorruption
        case syncTimeout
        case configurationError
        
        var errorDescription: String? {
            switch self {
            case .authenticationFailed:
                return "Authentication failed. Please check your credentials."
            case .tokenExpired:
                return "Your session has expired. Please sign in again."
            case .networkError:
                return "Network connection error. Please check your internet connection."
            case .apiLimitExceeded:
                return "API limit exceeded. Please wait before trying again."
            case .invalidCredentials:
                return "Invalid credentials. Please update your login information."
            case .accessDenied:
                return "Access denied. You don't have permission for this operation."
            case .serverError:
                return "RBC server error. Please try again later."
            case .dataCorruption:
                return "Data corruption detected. Please re-sync your data."
            case .syncTimeout:
                return "Sync operation timed out. Please try again."
            case .configurationError:
                return "Configuration error. Please check your settings."
            }
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        loadStoredCredentials()
        setupNetworkMonitoring()
    }
    
    // MARK: - Authentication Methods
    
    func authenticate() {
        isConnecting = true
        connectionStatus = .connecting
        
        let authURL = buildAuthURL()
        
        guard let url = authURL else {
            handleAuthenticationError(.configurationError)
            return
        }
        
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "rbcaiagent"
        ) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleAuthenticationError(.authenticationFailed)
                } else if let callbackURL = callbackURL {
                    self?.handleAuthCallback(callbackURL)
                }
            }
        }
        
        session.presentationContextProvider = self
        session.start()
    }
    
    private func buildAuthURL() -> URL? {
        var components = URLComponents(string: "\(baseURL)/oauth/authorize")
        
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        
        return components?.url
    }
    
    private func handleAuthCallback(_ callbackURL: URL) {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            handleAuthenticationError(.authenticationFailed)
            return
        }
        
        exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) {
        let tokenURL = URL(string: "\(baseURL)/oauth/token")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI
        ]
        
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleAuthenticationError(.networkError)
                    return
                }
                
                guard let data = data else {
                    self?.handleAuthenticationError(.serverError)
                    return
                }
                
                do {
                    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                    self?.handleTokenResponse(tokenResponse)
                } catch {
                    self?.handleAuthenticationError(.dataCorruption)
                }
            }
        }.resume()
    }
    
    private func handleTokenResponse(_ response: TokenResponse) {
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        tokenExpiryDate = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        
        storeCredentials()
        isConnected = true
        connectionStatus = .connected
        isConnecting = false
        
        // Fetch initial data
        fetchAvailableAccounts()
    }
    
    private func handleAuthenticationError(_ error: IntegrationError) {
        connectionStatus = .error
        isConnecting = false
        isConnected = false
        
        let syncError = SyncError(
            id: UUID().uuidString,
            type: .authentication,
            message: error.localizedDescription,
            timestamp: Date(),
            resolved: false
        )
        
        syncErrors.append(syncError)
    }
    
    // MARK: - Token Management
    
    private func refreshAccessToken() {
        guard let refreshToken = refreshToken else {
            authenticate()
            return
        }
        
        let tokenURL = URL(string: "\(baseURL)/oauth/token")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID
        ]
        
        request.httpBody = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleAuthenticationError(.networkError)
                    return
                }
                
                guard let data = data else {
                    self?.handleAuthenticationError(.serverError)
                    return
                }
                
                do {
                    let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                    self?.handleTokenResponse(tokenResponse)
                } catch {
                    self?.handleAuthenticationError(.dataCorruption)
                }
            }
        }.resume()
    }
    
    private func isTokenValid() -> Bool {
        guard let expiryDate = tokenExpiryDate else { return false }
        return Date() < expiryDate.addingTimeInterval(-300) // Refresh 5 minutes before expiry
    }
    
    private func ensureValidToken(completion: @escaping (Result<Void, IntegrationError>) -> Void) {
        if isTokenValid() {
            completion(.success(()))
        } else if refreshToken != nil {
            refreshAccessToken()
            completion(.success(()))
        } else {
            completion(.failure(.tokenExpired))
        }
    }
    
    // MARK: - Data Fetching Methods
    
    func fetchAvailableAccounts() {
        ensureValidToken { [weak self] result in
            switch result {
            case .success:
                self?.performAccountFetch()
            case .failure(let error):
                self?.handleSyncError(error)
            }
        }
    }
    
    private func performAccountFetch() {
        let url = URL(string: "\(baseURL)/accounts")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleSyncError(.networkError)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.handleSyncError(.serverError)
                    return
                }
                
                if httpResponse.statusCode == 401 {
                    self?.refreshAccessToken()
                    return
                }
                
                if httpResponse.statusCode == 429 {
                    self?.handleSyncError(.apiLimitExceeded)
                    return
                }
                
                guard let data = data else {
                    self?.handleSyncError(.serverError)
                    return
                }
                
                do {
                    let accountsResponse = try JSONDecoder().decode(AccountsResponse.self, from: data)
                    self?.availableAccounts = accountsResponse.accounts
                    self?.updateAPILimits(from: httpResponse)
                } catch {
                    self?.handleSyncError(.dataCorruption)
                }
            }
        }.resume()
    }
    
    func syncAccount(_ account: RBCAccount) {
        guard !connectedAccounts.contains(where: { $0.id == account.id }) else { return }
        
        connectionStatus = .syncing
        syncProgress = 0.0
        
        // Add account to connected list
        connectedAccounts.append(account)
        
        // Sync transactions for this account
        syncTransactions(for: account)
    }
    
    private func syncTransactions(for account: RBCAccount) {
        syncProgress = 0.1
        
        let url = URL(string: "\(baseURL)/accounts/\(account.id)/transactions")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.syncProgress = 0.5
                
                if let error = error {
                    self?.handleSyncError(.networkError)
                    return
                }
                
                guard let data = data else {
                    self?.handleSyncError(.serverError)
                    return
                }
                
                do {
                    let transactionsResponse = try JSONDecoder().decode(TransactionsResponse.self, from: data)
                    self?.transactions.append(contentsOf: transactionsResponse.transactions)
                    self?.syncProgress = 1.0
                    self?.lastSyncDate = Date()
                    self?.connectionStatus = .connected
                } catch {
                    self?.handleSyncError(.dataCorruption)
                }
            }
        }.resume()
    }
    
    func fetchUserProfile() {
        ensureValidToken { [weak self] result in
            switch result {
            case .success:
                self?.performProfileFetch()
            case .failure(let error):
                self?.handleSyncError(error)
            }
        }
    }
    
    private func performProfileFetch() {
        let url = URL(string: "\(baseURL)/profile")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleSyncError(.networkError)
                    return
                }
                
                guard let data = data else {
                    self?.handleSyncError(.serverError)
                    return
                }
                
                do {
                    let profileResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)
                    self?.userProfile = profileResponse.profile
                } catch {
                    self?.handleSyncError(.dataCorruption)
                }
            }
        }.resume()
    }
    
    // MARK: - Real-time Sync Methods
    
    func enableRealTimeSync() {
        // Set up webhooks or push notifications for real-time updates
        setupWebhooks()
    }
    
    private func setupWebhooks() {
        let url = URL(string: "\(baseURL)/webhooks")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let webhookConfig = [
            "events": ["transaction.created", "transaction.updated", "account.updated"],
            "callback_url": "https://your-server.com/rbc-webhook",
            "secret": UUID().uuidString
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: webhookConfig)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Webhook setup failed: \(error)")
                    return
                }
                
                print("Webhooks configured successfully")
            }
        }.resume()
    }
    
    // MARK: - Data Export Methods
    
    func exportData(format: ExportFormat, completion: @escaping (Result<Data, IntegrationError>) -> Void) {
        ensureValidToken { result in
            switch result {
            case .success:
                self.performDataExport(format: format, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func performDataExport(format: ExportFormat, completion: @escaping (Result<Data, IntegrationError>) -> Void) {
        let url = URL(string: "\(baseURL)/export")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue(format.rawValue, forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError))
                return
            }
            
            guard let data = data else {
                completion(.failure(.serverError))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    // MARK: - Insights Integration
    
    func fetchRBCInsights(completion: @escaping (Result<[RBCInsight], IntegrationError>) -> Void) {
        ensureValidToken { result in
            switch result {
            case .success:
                self.performInsightsFetch(completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func performInsightsFetch(completion: @escaping (Result<[RBCInsight], IntegrationError>) -> Void) {
        let url = URL(string: "\(baseURL)/insights")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError))
                return
            }
            
            guard let data = data else {
                completion(.failure(.serverError))
                return
            }
            
            do {
                let insightsResponse = try JSONDecoder().decode(InsightsResponse.self, from: data)
                completion(.success(insightsResponse.insights))
            } catch {
                completion(.failure(.dataCorruption))
            }
        }.resume()
    }
    
    // MARK: - Error Handling
    
    private func handleSyncError(_ error: IntegrationError) {
        connectionStatus = .error
        
        let syncError = SyncError(
            id: UUID().uuidString,
            type: .sync,
            message: error.localizedDescription,
            timestamp: Date(),
            resolved: false
        )
        
        syncErrors.append(syncError)
    }
    
    // MARK: - Credential Management
    
    private func storeCredentials() {
        guard let accessToken = accessToken,
              let refreshToken = refreshToken,
              let expiryDate = tokenExpiryDate else { return }
        
        let keychain = Keychain(service: keychainService)
        
        try? keychain.set(accessToken, key: "access_token")
        try? keychain.set(refreshToken, key: "refresh_token")
        userDefaults.set(expiryDate, forKey: "token_expiry")
    }
    
    private func loadStoredCredentials() {
        let keychain = Keychain(service: keychainService)
        
        accessToken = try? keychain.get("access_token")
        refreshToken = try? keychain.get("refresh_token")
        tokenExpiryDate = userDefaults.object(forKey: "token_expiry") as? Date
        
        if isTokenValid() {
            isConnected = true
            connectionStatus = .connected
            fetchAvailableAccounts()
        }
    }
    
    func disconnect() {
        accessToken = nil
        refreshToken = nil
        tokenExpiryDate = nil
        
        let keychain = Keychain(service: keychainService)
        try? keychain.remove("access_token")
        try? keychain.remove("refresh_token")
        userDefaults.removeObject(forKey: "token_expiry")
        
        isConnected = false
        connectionStatus = .disconnected
        availableAccounts.removeAll()
        connectedAccounts.removeAll()
        transactions.removeAll()
        userProfile = nil
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // Monitor network connectivity
        // This would typically use Network framework
    }
    
    // MARK: - API Limits Management
    
    private func updateAPILimits(from response: HTTPURLResponse) {
        if let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
           let limit = response.value(forHTTPHeaderField: "X-RateLimit-Limit") {
            
            apiLimits = APILimits(
                limit: Int(limit) ?? 1000,
                remaining: Int(remaining) ?? 1000,
                resetTime: Date(timeIntervalSince1970: TimeInterval(reset) ?? 0),
                windowSize: 3600 // 1 hour window
            )
        }
    }
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// MARK: - Data Structures

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct AccountsResponse: Codable {
    let accounts: [RBCAccount]
}

struct TransactionsResponse: Codable {
    let transactions: [RBCTransaction]
    let totalCount: Int
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case transactions
        case totalCount = "total_count"
        case hasMore = "has_more"
    }
}

struct ProfileResponse: Codable {
    let profile: RBCUserProfile
}

struct InsightsResponse: Codable {
    let insights: [RBCInsight]
}

struct RBCAccount: Codable, Identifiable {
    let id: String
    let nickname: String?
    let accountType: String
    let balance: Double
    let currency: String
    let status: String
    let lastUpdated: Date
    let isSynced: Bool
}

struct RBCTransaction: Codable, Identifiable {
    let id: String
    let accountId: String
    let description: String
    let amount: Double
    let currency: String
    let date: Date
    let category: String
    let merchant: String?
    let location: String?
    let isPending: Bool
    let tags: [String]
}

struct RBCUserProfile: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let memberSince: Date
    let preferences: UserPreferences
}

struct UserPreferences: Codable {
    let language: String
    let timezone: String
    let currency: String
    let notifications: NotificationPreferences
}

struct NotificationPreferences: Codable {
    let email: Bool
    let push: Bool
    let sms: Bool
}

struct RBCInsight: Codable {
    let id: String
    let type: String
    let title: String
    let description: String
    let severity: String
    let confidence: Double
    let generatedAt: Date
    let actions: [String]
}

struct SyncError: Identifiable {
    let id: String
    let type: ErrorType
    let message: String
    let timestamp: Date
    var resolved: Bool
}

enum ErrorType {
    case authentication, sync, network, api, data
}

struct APILimits {
    let limit: Int
    let remaining: Int
    let resetTime: Date
    let windowSize: Int
}

enum ExportFormat: String {
    case json = "application/json"
    case csv = "text/csv"
    case xml = "application/xml"
    case pdf = "application/pdf"
}

// MARK: - Keychain Helper

import Foundation
import Security

class Keychain {
    private let service: String
    
    init(service: String) {
        self.service = service
    }
    
    func set(_ value: String, key: String) throws {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func remove(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
}
