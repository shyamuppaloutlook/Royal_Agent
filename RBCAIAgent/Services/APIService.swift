import Foundation
import SwiftUI
import Combine

class APIService: ObservableObject {
    @Published var isAPIServiceEnabled: Bool = true
    @Published var apiEndpoints: [APIEndpoint] = []
    @Published var activeRequests: [ActiveAPIRequest] = []
    @Published var requestHistory: [APIRequestRecord] = []
    @Published var apiSettings: APISettings = APISettings()
    @Published var apiStatistics: APIStatistics = APIStatistics()
    @Published var isMakingRequest: Bool = false
    @Published var currentRequestProgress: Double = 0.0
    
    private var apiClient: APIClient
    private var requestQueue: DispatchQueue
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - API Categories
    
    enum APICategory: String, CaseIterable, Identifiable {
        case banking = "Banking"
        case transactions = "Transactions"
        case accounts = "Accounts"
        case investments = "Investments"
        case loans = "Loans"
        case mortgages = "Mortgages"
        case creditCards = "Credit Cards"
        case insurance = "Insurance"
        case wealth = "Wealth Management"
        case risk = "Risk Assessment"
        case analytics = "Analytics"
        case notifications = "Notifications"
        case support = "Customer Support"
        case compliance = "Compliance"
        case market = "Market Data"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .banking: return "building.columns"
            case .transactions: return "arrow.left.arrow.right"
            case .accounts: return "person.crop.circle"
            case .investments: return "chart.line.uptrend.xyaxis"
            case .loans: return "dollarsign.circle"
            case .mortgages: return "house"
            case .creditCards: return "creditcard"
            case .insurance: return "shield"
            case .wealth: return "chart.pie"
            case .risk: return "exclamationmark.triangle"
            case .analytics: return "chart.bar"
            case .notifications: return "bell"
            case .support: return "headphones"
            case .compliance: return "gavel"
            case .market: return "globe"
            }
        }
        
        var color: Color {
            switch self {
            case .banking: return .blue
            case .transactions: return .green
            case .accounts: return .orange
            case .investments: return .purple
            case .loans: return .red
            case .mortgages: return .teal
            case .creditCards: return .indigo
            case .insurance: return .pink
            case .wealth: return .yellow
            case .risk: return .red
            case .analytics: return .cyan
            case .notifications: return .mint
            case .support: return .gray
            case .compliance: return .purple
            case .market: return .green
            }
        }
    }
    
    // MARK: - HTTP Methods
    
    enum HTTPMethod: String, CaseIterable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case head = "HEAD"
        case options = "OPTIONS"
        
        var icon: String {
            switch self {
            case .get: return "arrow.down.circle"
            case .post: return "plus.circle"
            case .put: return "arrow.up.circle"
            case .patch: return "pencil.circle"
            case .delete: return "minus.circle"
            case .head: return "eye.circle"
            case .options: return "gear.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .get: return .green
            case .post: return .blue
            case .put: return .orange
            case .patch: return .yellow
            case .delete: return .red
            case .head: return .gray
            case .options: return .purple
            }
        }
    }
    
    // MARK: - API Status
    
    enum APIStatus: String, CaseIterable {
        case active = "Active"
        case inactive = "Inactive"
        case maintenance = "Maintenance"
        case error = "Error"
        case deprecated = "Deprecated"
        case testing = "Testing"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .active: return .green
            case .inactive: return .gray
            case .maintenance: return .orange
            case .error: return .red
            case .deprecated: return .purple
            case .testing: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle"
            case .inactive: return "pause.circle"
            case .maintenance: return "wrench"
            case .error: return "xmark.circle"
            case .deprecated: return "exclamationmark.triangle"
            case .testing: return "flask"
            }
        }
    }
    
    // MARK: - Authentication Types
    
    enum AuthType: String, CaseIterable {
        case none = "None"
        case apiKey = "API Key"
        case bearer = "Bearer Token"
        case basic = "Basic Auth"
        case oauth = "OAuth 2.0"
        case jwt = "JWT"
        case custom = "Custom"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .none: return "lock.open"
            case .apiKey: return "key"
            case .bearer: return "person.crop.circle.badge.checkmark"
            case .basic: return "person.2"
            case .oauth: return "key.horizontal"
            case .jwt: return "doc.text"
            case .custom: return "gearshape.2"
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .apiKey: return .blue
            case .bearer: return .green
            case .basic: return .orange
            case .oauth: return .purple
            case .jwt: return .red
            case .custom: return .teal
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        apiClient = APIClient()
        requestQueue = DispatchQueue(label: "com.rbc.api.requests", qos: .userInitiated)
        setupAPIService()
        loadAPISettings()
        loadAPIEndpoints()
        setupRequestMonitoring()
    }
    
    private func setupAPIService() {
        // Initialize API service components
    }
    
    private func loadAPISettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "api_settings"),
           let settings = try? JSONDecoder().decode(APISettings.self, from: data) {
            apiSettings = settings
            isAPIServiceEnabled = settings.isEnabled
        }
        
        if let data = defaults.data(forKey: "api_endpoints"),
           let endpoints = try? JSONDecoder().decode([APIEndpoint].self, from: data) {
            apiEndpoints = endpoints
        }
        
        if let data = defaults.data(forKey: "request_history"),
           let history = try? JSONDecoder().decode([APIRequestRecord].self, from: data) {
            requestHistory = history
        }
    }
    
    private func saveAPISettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(apiSettings) {
            defaults.set(data, forKey: "api_settings")
        }
        
        if let data = try? JSONEncoder().encode(apiEndpoints) {
            defaults.set(data, forKey: "api_endpoints")
        }
        
        if let data = try? JSONEncoder().encode(requestHistory) {
            defaults.set(data, forKey: "request_history")
        }
    }
    
    private func loadAPIEndpoints() {
        // Load API endpoints configuration
        apiEndpoints = [
            APIEndpoint(
                id: "rbc-banking-api",
                name: "RBC Banking API",
                description: "Core banking operations and account management",
                category: .banking,
                baseURL: "https://api.rbc.com/v1",
                version: "1.0.0",
                status: .active,
                authType: .bearer,
                timeout: 30.0,
                rateLimit: 1000,
                endpoints: [
                    APIPath(
                        path: "/accounts",
                        method: .get,
                        description: "Get user accounts",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/accounts/{id}/balance",
                        method: .get,
                        description: "Get account balance",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/transactions",
                        method: .get,
                        description: "Get transaction history",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/transfers",
                        method: .post,
                        description: "Initiate money transfer",
                        requiresAuth: true
                    )
                ]
            ),
            APIEndpoint(
                id: "rbc-investment-api",
                name: "RBC Investment API",
                description: "Investment portfolio and market data",
                category: .investments,
                baseURL: "https://api.rbc.com/v2",
                version: "2.1.0",
                status: .active,
                authType: .bearer,
                timeout: 45.0,
                rateLimit: 500,
                endpoints: [
                    APIPath(
                        path: "/portfolio",
                        method: .get,
                        description: "Get investment portfolio",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/market/data",
                        method: .get,
                        description: "Get market data",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/trades",
                        method: .post,
                        description: "Execute trade",
                        requiresAuth: true
                    )
                ]
            ),
            APIEndpoint(
                id: "rbc-analytics-api",
                name: "RBC Analytics API",
                description: "Financial analytics and insights",
                category: .analytics,
                baseURL: "https://analytics.rbc.com/v1",
                version: "1.5.0",
                status: .active,
                authType: .apiKey,
                timeout: 60.0,
                rateLimit: 200,
                endpoints: [
                    APIPath(
                        path: "/spending/analysis",
                        method: .get,
                        description: "Get spending analysis",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/budget/performance",
                        method: .get,
                        description: "Get budget performance",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/predictions",
                        method: .get,
                        description: "Get financial predictions",
                        requiresAuth: true
                    )
                ]
            ),
            APIEndpoint(
                id: "rbc-support-api",
                name: "RBC Support API",
                description: "Customer support and help services",
                category: .support,
                baseURL: "https://support.rbc.com/v1",
                version: "1.0.0",
                status: .active,
                authType: .bearer,
                timeout: 20.0,
                rateLimit: 100,
                endpoints: [
                    APIPath(
                        path: "/tickets",
                        method: .post,
                        description: "Create support ticket",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/chat",
                        method: .post,
                        description: "Start chat session",
                        requiresAuth: true
                    ),
                    APIPath(
                        path: "/faq",
                        method: .get,
                        description: "Get FAQ answers",
                        requiresAuth: false
                    )
                ]
            )
        ]
    }
    
    private func setupRequestMonitoring() {
        // Set up request monitoring and analytics
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateAPIStatistics()
        }
    }
    
    // MARK: - API Request Methods
    
    func makeRequest<T: Codable>(
        endpointId: String,
        path: String,
        method: HTTPMethod = .get,
        body: T? = nil,
        headers: [String: String] = [:]
    ) async throws -> APIResponse {
        guard isAPIServiceEnabled else {
            throw APIError.serviceDisabled
        }
        
        guard let endpoint = apiEndpoints.first(where: { $0.id == endpointId }) else {
            throw APIError.endpointNotFound
        }
        
        guard endpoint.status == .active else {
            throw APIError.endpointInactive
        }
        
        isMakingRequest = true
        currentRequestProgress = 0.0
        
        let startTime = Date()
        let requestId = UUID().uuidString
        
        // Create active request record
        let activeRequest = ActiveAPIRequest(
            id: requestId,
            endpointId: endpointId,
            path: path,
            method: method,
            startTime: startTime,
            status: .pending
        )
        
        activeRequests.append(activeRequest)
        
        do {
            // Update progress
            currentRequestProgress = 0.2
            
            // Build URL
            let url = URL(string: "\(endpoint.baseURL)\(path)")!
            var request = URLRequest(url: url)
            
            // Set method
            request.httpMethod = method.rawValue
            request.timeoutInterval = endpoint.timeout
            
            // Set headers
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            // Add authentication
            if endpoint.authType != .none {
                request.setValue(getAuthToken(for: endpoint.authType), forHTTPHeaderField: "Authorization")
            }
            
            // Add custom headers
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            // Add body for POST/PUT requests
            if let body = body, [.post, .put, .patch].contains(method) {
                request.httpBody = try JSONEncoder().encode(body)
            }
            
            currentRequestProgress = 0.4
            
            // Make request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            currentRequestProgress = 0.8
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Create response
            let apiResponse = APIResponse(
                data: data,
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                duration: duration
            )
            
            // Update active request
            if let index = activeRequests.firstIndex(where: { $0.id == requestId }) {
                activeRequests[index].status = .completed
                activeRequests[index].endTime = Date()
                activeRequests[index].duration = duration
                activeRequests[index].statusCode = httpResponse.statusCode
            }
            
            // Create request record
            let record = APIRequestRecord(
                id: requestId,
                endpointId: endpointId,
                path: path,
                method: method,
                startTime: startTime,
                endTime: Date(),
                duration: duration,
                statusCode: httpResponse.statusCode,
                success: httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                dataSize: data.count,
                error: nil
            )
            
            requestHistory.append(record)
            
            // Keep only recent history (last 100)
            if requestHistory.count > 100 {
                requestHistory = Array(requestHistory.suffix(100))
            }
            
            // Remove from active requests
            activeRequests.removeAll { $0.id == requestId }
            
            currentRequestProgress = 1.0
            isMakingRequest = false
            
            updateAPIStatistics()
            saveAPISettings()
            
            return apiResponse
            
        } catch {
            // Update active request with error
            if let index = activeRequests.firstIndex(where: { $0.id == requestId }) {
                activeRequests[index].status = .failed
                activeRequests[index].endTime = Date()
                activeRequests[index].error = error.localizedDescription
            }
            
            // Create error record
            let record = APIRequestRecord(
                id: requestId,
                endpointId: endpointId,
                path: path,
                method: method,
                startTime: startTime,
                endTime: Date(),
                duration: Date().timeIntervalSince(startTime),
                statusCode: 0,
                success: false,
                dataSize: 0,
                error: error.localizedDescription
            )
            
            requestHistory.append(record)
            
            // Remove from active requests
            activeRequests.removeAll { $0.id == requestId }
            
            currentRequestProgress = 0.0
            isMakingRequest = false
            
            updateAPIStatistics()
            saveAPISettings()
            
            throw error
        }
    }
    
    private func getAuthToken(for authType: AuthType) -> String {
        switch authType {
        case .none:
            return ""
        case .apiKey:
            return "Bearer \(apiSettings.apiKey)"
        case .bearer:
            return "Bearer \(apiSettings.bearerToken)"
        case .basic:
            let credentials = "\(apiSettings.username):\(apiSettings.password)"
            let data = credentials.data(using: .utf8) ?? Data()
            return "Basic \(data.base64EncodedString())"
        case .oauth:
            return "Bearer \(apiSettings.oauthToken)"
        case .jwt:
            return "Bearer \(apiSettings.jwtToken)"
        case .custom:
            return apiSettings.customAuthHeader
        }
    }
    
    // MARK: - Endpoint Management
    
    func addEndpoint(_ endpoint: APIEndpoint) {
        apiEndpoints.append(endpoint)
        saveAPISettings()
    }
    
    func updateEndpoint(_ endpoint: APIEndpoint) {
        if let index = apiEndpoints.firstIndex(where: { $0.id == endpoint.id }) {
            apiEndpoints[index] = endpoint
            saveAPISettings()
        }
    }
    
    func removeEndpoint(_ endpointId: String) {
        apiEndpoints.removeAll { $0.id == endpointId }
        saveAPISettings()
    }
    
    func activateEndpoint(_ endpointId: String) {
        if let index = apiEndpoints.firstIndex(where: { $0.id == endpointId }) {
            apiEndpoints[index].status = .active
            saveAPISettings()
        }
    }
    
    func deactivateEndpoint(_ endpointId: String) {
        if let index = apiEndpoints.firstIndex(where: { $0.id == endpointId }) {
            apiEndpoints[index].status = .inactive
            saveAPISettings()
        }
    }
    
    // MARK: - Request Management
    
    func cancelRequest(_ requestId: String) {
        // Cancel active request (implementation would depend on URLSession task management)
        activeRequests.removeAll { $0.id == requestId }
    }
    
    func cancelAllRequests() {
        activeRequests.removeAll()
    }
    
    func getRequestHistory(for endpointId: String? = nil) -> [APIRequestRecord] {
        if let endpointId = endpointId {
            return requestHistory.filter { $0.endpointId == endpointId }
        }
        return requestHistory
    }
    
    func clearRequestHistory() {
        requestHistory.removeAll()
        saveAPISettings()
    }
    
    // MARK: - Settings Management
    
    func updateAPISettings(_ settings: APISettings) {
        apiSettings = settings
        isAPIServiceEnabled = settings.isEnabled
        saveAPISettings()
    }
    
    func enableAPIService() {
        isAPIServiceEnabled = true
        apiSettings.isEnabled = true
        saveAPISettings()
    }
    
    func disableAPIService() {
        isAPIServiceEnabled = false
        apiSettings.isEnabled = false
        cancelAllRequests()
        saveAPISettings()
    }
    
    // MARK: - Analytics and Reporting
    
    private func updateAPIStatistics() {
        let totalRequests = requestHistory.count
        let successfulRequests = requestHistory.filter { $0.success }.count
        let failedRequests = requestHistory.filter { !$0.success }.count
        let averageResponseTime = requestHistory.isEmpty ? 0 : requestHistory.map { $0.duration }.reduce(0, +) / Double(totalRequests)
        
        let categoryBreakdown = APICategory.allCases.map { category in
            let categoryRequests = requestHistory.filter { record in
                apiEndpoints.contains { $0.id == record.endpointId && $0.category == category }
            }
            return CategoryAPIStatistics(
                category: category,
                totalRequests: categoryRequests.count,
                successfulRequests: categoryRequests.filter { $0.success }.count,
                averageResponseTime: categoryRequests.isEmpty ? 0 : categoryRequests.map { $0.duration }.reduce(0, +) / Double(categoryRequests.count)
            )
        }
        
        let methodBreakdown = HTTPMethod.allCases.map { method in
            let methodRequests = requestHistory.filter { $0.method == method }
            return MethodAPIStatistics(
                method: method,
                totalRequests: methodRequests.count,
                successfulRequests: methodRequests.filter { $0.success }.count,
                averageResponseTime: methodRequests.isEmpty ? 0 : methodRequests.map { $0.duration }.reduce(0, +) / Double(methodRequests.count)
            )
        }
        
        apiStatistics = APIStatistics(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            successRate: totalRequests > 0 ? Double(successfulRequests) / Double(totalRequests) * 100 : 0,
            averageResponseTime: averageResponseTime,
            categoryBreakdown: categoryBreakdown,
            methodBreakdown: methodBreakdown,
            activeRequests: activeRequests.count
        )
    }
    
    func getAPIReport() -> APIReport {
        return APIReport(
            isEnabled: isAPIServiceEnabled,
            totalEndpoints: apiEndpoints.count,
            activeEndpoints: apiEndpoints.filter { $0.status == .active }.count,
            apiStatistics: apiStatistics,
            apiEndpoints: apiEndpoints,
            activeRequests: activeRequests,
            requestHistory: requestHistory,
            apiSettings: apiSettings,
            generatedAt: Date()
        )
    }
    
    deinit {
        cancelAllRequests()
    }
}

// MARK: - Supporting Classes

class APIClient {
    func makeRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(for: request)
    }
}

// MARK: - Data Structures

struct APIEndpoint: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: APIService.APICategory
    let baseURL: String
    let version: String
    var status: APIService.APIStatus
    let authType: APIService.AuthType
    let timeout: TimeInterval
    let rateLimit: Int
    let endpoints: [APIPath]
}

struct APIPath: Identifiable, Codable {
    let id = UUID()
    let path: String
    let method: APIService.HTTPMethod
    let description: String
    let requiresAuth: Bool
}

struct ActiveAPIRequest: Identifiable, Codable {
    let id: String
    let endpointId: String
    let path: String
    let method: APIService.HTTPMethod
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    var status: RequestStatus
    var statusCode: Int?
    var error: String?
}

enum RequestStatus: String, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .orange
        }
    }
}

struct APIRequestRecord: Identifiable, Codable {
    let id: String
    let endpointId: String
    let path: String
    let method: APIService.HTTPMethod
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let statusCode: Int
    let success: Bool
    let dataSize: Int
    let error: String?
}

struct APIResponse: Codable {
    let data: Data
    let statusCode: Int
    let headers: [String: String]
    let duration: TimeInterval
}

struct APISettings: Codable {
    var isEnabled: Bool = true
    var enableRequestLogging: Bool = true
    var enableErrorLogging: Bool = true
    var enablePerformanceMonitoring: Bool = true
    var enableAutoRetry: Bool = true
    var maxRetryAttempts: Int = 3
    var retryDelay: TimeInterval = 1.0
    var enableRequestCaching: Bool = true
    var cacheTimeout: TimeInterval = 300 // 5 minutes
    var enableRateLimiting: Bool = true
    var maxConcurrentRequests: Int = 10
    var enableCompression: Bool = true
    var enableSSLVerification: Bool = true
    
    // Authentication settings
    var apiKey: String = ""
    var bearerToken: String = ""
    var username: String = ""
    var password: String = ""
    var oauthToken: String = ""
    var jwtToken: String = ""
    var customAuthHeader: String = ""
}

struct APIStatistics: Codable {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var successRate: Double = 0.0
    var averageResponseTime: TimeInterval = 0.0
    var categoryBreakdown: [CategoryAPIStatistics] = []
    var methodBreakdown: [MethodAPIStatistics] = []
    var activeRequests: Int = 0
}

struct CategoryAPIStatistics: Identifiable, Codable {
    let id = UUID()
    let category: APIService.APICategory
    let totalRequests: Int
    let successfulRequests: Int
    let averageResponseTime: TimeInterval
}

struct MethodAPIStatistics: Identifiable, Codable {
    let id = UUID()
    let method: APIService.HTTPMethod
    let totalRequests: Int
    let successfulRequests: Int
    let averageResponseTime: TimeInterval
}

struct APIReport {
    let isEnabled: Bool
    let totalEndpoints: Int
    let activeEndpoints: Int
    let apiStatistics: APIStatistics
    let apiEndpoints: [APIEndpoint]
    let activeRequests: [ActiveAPIRequest]
    let requestHistory: [APIRequestRecord]
    let apiSettings: APISettings
    let generatedAt: Date
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case serviceDisabled
    case endpointNotFound
    case endpointInactive
    case invalidResponse
    case authenticationFailed
    case rateLimitExceeded
    case networkError
    case timeout
    case invalidURL
    case encodingError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .serviceDisabled:
            return "API service is disabled"
        case .endpointNotFound:
            return "API endpoint not found"
        case .endpointInactive:
            return "API endpoint is inactive"
        case .invalidResponse:
            return "Invalid API response"
        case .authenticationFailed:
            return "Authentication failed"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .networkError:
            return "Network error occurred"
        case .timeout:
            return "Request timed out"
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Request encoding error"
        case .decodingError:
            return "Response decoding error"
        }
    }
}
