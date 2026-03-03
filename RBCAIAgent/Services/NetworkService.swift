import Foundation
import SwiftUI
import Combine
import Network

class NetworkService: ObservableObject {
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .wifi
    @Published var networkQuality: NetworkQuality = .excellent
    @Published var isMonitoring: Bool = false
    @Published var networkSettings: NetworkSettings = NetworkSettings()
    @Published var networkStatistics: NetworkStatistics = NetworkStatistics()
    @Published var activeConnections: [NetworkConnection] = []
    @Published var connectionHistory: [ConnectionRecord] = []
    @Published var dataUsage: DataUsage = DataUsage()
    @Published var latency: Double = 0.0
    @Published var bandwidth: Double = 0.0
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    private var pingTimer: Timer?
    
    // MARK: - Connection Types
    
    enum ConnectionType: String, CaseIterable {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case other = "Other"
        case none = "None"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .other: return "network"
            case .none: return "wifi.slash"
            }
        }
        
        var color: Color {
            switch self {
            case .wifi: return .blue
            case .cellular: return .green
            case .ethernet: return .orange
            case .other: return .gray
            case .none: return .red
            }
        }
        
        var priority: Int {
            switch self {
            case .wifi: return 3
            case .ethernet: return 4
            case .cellular: return 2
            case .other: return 1
            case .none: return 0
            }
        }
    }
    
    // MARK: - Network Quality
    
    enum NetworkQuality: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case unknown = "Unknown"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            case .unknown: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .excellent: return "speedometer"
            case .good: return "speedometer.2"
            case .fair: return "speedometer.3"
            case .poor: return "speedometer.4"
            case .unknown: return "speedometer"
            }
        }
        
        var latencyThreshold: Double {
            switch self {
            case .excellent: return 50
            case .good: return 100
            case .fair: return 200
            case .poor: return 500
            case .unknown: return 1000
            }
        }
        
        var bandwidthThreshold: Double {
            switch self {
            case .excellent: return 10.0 // Mbps
            case .good: return 5.0
            case .fair: return 2.0
            case .poor: return 1.0
            case .unknown: return 0.5
            }
        }
    }
    
    // MARK: - Request Types
    
    enum RequestType: String, CaseIterable, Identifiable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .get: return "arrow.down.circle"
            case .post: return "arrow.up.circle"
            case .put: return "arrow.up.circle.fill"
            case .delete: return "trash.circle"
            case .patch: return "arrow.up.circle.square"
            }
        }
    }
    
    // MARK: - API Endpoints
    
    enum APIEndpoint: String, CaseIterable, Identifiable {
        case banking = "/banking"
        case transactions = "/transactions"
        case accounts = "/accounts"
        case investments = "/investments"
        case bills = "/bills"
        case budget = "/budget"
        case analytics = "/analytics"
        case settings = "/settings"
        case notifications = "/notifications"
        case security = "/security"
        
        var id: String { return rawValue }
        
        var baseURL: String {
            return "https://api.rbc.com/v1"
        }
        
        var fullURL: String {
            return baseURL + rawValue
        }
        
        var requiresAuth: Bool {
            switch self {
            case .banking, .transactions, .accounts, .investments, .bills, .budget, .analytics, .settings, .notifications, .security:
                return true
            }
        }
        
        var timeout: TimeInterval {
            switch self {
            case .analytics, .settings, .notifications:
                return 30.0
            case .banking, .transactions, .accounts, .investments, .bills, .budget, .security:
                return 60.0
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupNetworkService()
        loadNetworkSettings()
        startNetworkMonitoring()
        setupDataUsageTracking()
    }
    
    private func setupNetworkService() {
        // Initialize network service components
    }
    
    private func loadNetworkSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "network_settings"),
           let settings = try? JSONDecoder().decode(NetworkSettings.self, from: data) {
            networkSettings = settings
        }
        
        if let data = defaults.data(forKey: "connection_history"),
           let history = try? JSONDecoder().decode([ConnectionRecord].self, from: data) {
            connectionHistory = history
        }
        
        if let data = defaults.data(forKey: "data_usage"),
           let usage = try? JSONDecoder().decode(DataUsage.self, from: data) {
            dataUsage = usage
        }
    }
    
    private func saveNetworkSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(networkSettings) {
            defaults.set(data, forKey: "network_settings")
        }
        
        if let data = try? JSONEncoder().encode(connectionHistory) {
            defaults.set(data, forKey: "connection_history")
        }
        
        if let data = try? JSONEncoder().encode(dataUsage) {
            defaults.set(data, forKey: "data_usage")
        }
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        
        monitor.start(queue: monitorQueue)
        isMonitoring = true
        
        // Start periodic network quality checks
        startNetworkQualityChecks()
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        let previousConnection = isConnected
        let previousType = connectionType
        
        isConnected = path.status == .satisfied
        connectionType = determineConnectionType(path)
        
        // Record connection change
        if previousConnection != isConnected || previousType != connectionType {
            recordConnectionChange()
        }
        
        // Update network quality when connected
        if isConnected {
            updateNetworkQuality()
        } else {
            networkQuality = .unknown
            latency = 0
            bandwidth = 0
        }
    }
    
    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.other) {
            return .other
        } else {
            return .none
        }
    }
    
    private func recordConnectionChange() {
        let record = ConnectionRecord(
            id: UUID().uuidString,
            timestamp: Date(),
            isConnected: isConnected,
            connectionType: connectionType,
            networkQuality: networkQuality,
            latency: latency,
            bandwidth: bandwidth
        )
        
        connectionHistory.append(record)
        
        // Keep only recent history (last 100)
        if connectionHistory.count > 100 {
            connectionHistory = Array(connectionHistory.suffix(100))
        }
        
        saveNetworkSettings()
    }
    
    private func startNetworkQualityChecks() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            if self?.isConnected == true {
                self?.measureNetworkQuality()
            }
        }
    }
    
    private func measureNetworkQuality() {
        Task {
            await measureLatency()
            await measureBandwidth()
            updateNetworkQuality()
        }
    }
    
    private func measureLatency() async {
        let startTime = Date()
        
        do {
            let url = URL(string: "https://www.google.com")!
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 10.0
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                latency = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
            }
        } catch {
            latency = 1000 // High latency on error
        }
    }
    
    private func measureBandwidth() async {
        // Simulate bandwidth measurement
        // In a real implementation, you would download a file of known size
        let testFileSize = 1_000_000 // 1MB
        let startTime = Date()
        
        do {
            let url = URL(string: "https://httpbin.org/bytes/1000000")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let duration = Date().timeIntervalSince(startTime)
            let bytesPerSecond = Double(data.count) / duration
            bandwidth = bytesPerSecond / 1_000_000 // Convert to Mbps
            
        } catch {
            bandwidth = 0
        }
    }
    
    private func updateNetworkQuality() {
        switch (latency, bandwidth) {
        case (0..<50, 10...):
            networkQuality = .excellent
        case (0..<100, 5..<10), (50..<100, 10...):
            networkQuality = .good
        case (0..<200, 2..<5), (100..<200, 5..<10):
            networkQuality = .fair
        case (200..., 0..<2), (200..., 2..<5):
            networkQuality = .poor
        default:
            networkQuality = .unknown
        }
    }
    
    private func setupDataUsageTracking() {
        // Set up periodic data usage tracking
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateDataUsage()
        }
    }
    
    private func updateDataUsage() {
        // Simulate data usage tracking
        let currentUsage = Double.random(in: 0...10) // MB
        dataUsage.currentSessionUsage += currentUsage
        dataUsage.totalUsage += currentUsage
        
        // Update daily usage
        let today = Calendar.current.startOfDay(for: Date())
        if dataUsage.lastResetDate < today {
            dataUsage.dailyUsage = currentUsage
            dataUsage.lastResetDate = today
        } else {
            dataUsage.dailyUsage += currentUsage
        }
        
        saveNetworkSettings()
    }
    
    // MARK: - Network Requests
    
    func request<T: Codable>(
        endpoint: APIEndpoint,
        method: RequestType = .get,
        body: T? = nil,
        headers: [String: String] = [:]
    ) async throws -> NetworkResponse {
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        let url = URL(string: endpoint.fullURL)!
        var request = URLRequest(url: url)
        
        request.httpMethod = method.rawValue
        request.timeoutInterval = endpoint.timeout
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authentication if required
        if endpoint.requiresAuth {
            request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        }
        
        // Add body for POST/PUT requests
        if let body = body, [.post, .put, .patch].contains(method) {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let startTime = Date()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Update statistics
            updateNetworkStatistics(
                endpoint: endpoint,
                method: method,
                statusCode: httpResponse.statusCode,
                duration: duration,
                dataSize: data.count
            )
            
            // Update data usage
            dataUsage.currentSessionUsage += Double(data.count) / 1_000_000 // Convert to MB
            dataUsage.totalUsage += Double(data.count) / 1_000_000
            
            return NetworkResponse(
                data: data,
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                duration: duration
            )
            
        } catch {
            updateNetworkStatistics(
                endpoint: endpoint,
                method: method,
                statusCode: 0,
                duration: Date().timeIntervalSince(startTime),
                dataSize: 0
            )
            throw error
        }
    }
    
    private func getAuthToken() -> String {
        // Return authentication token
        return "mock_auth_token"
    }
    
    private func updateNetworkStatistics(
        endpoint: APIEndpoint,
        method: RequestType,
        statusCode: Int,
        duration: TimeInterval,
        dataSize: Int
    ) {
        networkStatistics.totalRequests += 1
        
        if statusCode >= 200 && statusCode < 300 {
            networkStatistics.successfulRequests += 1
        } else {
            networkStatistics.failedRequests += 1
        }
        
        networkStatistics.averageResponseTime = (networkStatistics.averageResponseTime * Double(networkStatistics.totalRequests - 1) + duration) / Double(networkStatistics.totalRequests)
        networkStatistics.totalDataTransferred += Double(dataSize) / 1_000_000 // Convert to MB
        
        // Update endpoint-specific statistics
        if let index = networkStatistics.endpointStatistics.firstIndex(where: { $0.endpoint == endpoint }) {
            networkStatistics.endpointStatistics[index].requestCount += 1
            networkStatistics.endpointStatistics[index].averageResponseTime = (networkStatistics.endpointStatistics[index].averageResponseTime * Double(networkStatistics.endpointStatistics[index].requestCount - 1) + duration) / Double(networkStatistics.endpointStatistics[index].requestCount)
        } else {
            networkStatistics.endpointStatistics.append(
                EndpointStatistics(
                    endpoint: endpoint,
                    requestCount: 1,
                    averageResponseTime: duration,
                    successRate: statusCode >= 200 && statusCode < 300 ? 100 : 0
                )
            )
        }
    }
    
    // MARK: - Connection Management
    
    func addConnection(_ connection: NetworkConnection) {
        activeConnections.append(connection)
    }
    
    func removeConnection(_ connectionId: String) {
        activeConnections.removeAll { $0.id == connectionId }
    }
    
    func getConnectionStatus(_ connectionId: String) -> ConnectionStatus? {
        return activeConnections.first { $0.id == connectionId }?.status
    }
    
    // MARK: - Settings Management
    
    func updateNetworkSettings(_ settings: NetworkSettings) {
        networkSettings = settings
        saveNetworkSettings()
    }
    
    func enableNetworkMonitoring() {
        if !isMonitoring {
            startNetworkMonitoring()
        }
    }
    
    func disableNetworkMonitoring() {
        monitor.cancel()
        pingTimer?.invalidate()
        isMonitoring = false
    }
    
    func resetDataUsage() {
        dataUsage = DataUsage()
        saveNetworkSettings()
    }
    
    // MARK: - Analytics and Reporting
    
    func getNetworkReport() -> NetworkReport {
        let uptime = calculateUptime()
        let averageLatency = connectionHistory.isEmpty ? 0 : connectionHistory.map { $0.latency }.reduce(0, +) / Double(connectionHistory.count)
        let averageBandwidth = connectionHistory.isEmpty ? 0 : connectionHistory.map { $0.bandwidth }.reduce(0, +) / Double(connectionHistory.count)
        
        return NetworkReport(
            isConnected: isConnected,
            connectionType: connectionType,
            networkQuality: networkQuality,
            uptime: uptime,
            averageLatency: averageLatency,
            averageBandwidth: averageBandwidth,
            dataUsage: dataUsage,
            networkStatistics: networkStatistics,
            activeConnections: activeConnections,
            generatedAt: Date()
        )
    }
    
    private func calculateUptime() -> Double {
        guard !connectionHistory.isEmpty else { return 0 }
        
        let connectedRecords = connectionHistory.filter { $0.isConnected }
        return Double(connectedRecords.count) / Double(connectionHistory.count) * 100
    }
    
    deinit {
        monitor.cancel()
        pingTimer?.invalidate()
    }
}

// MARK: - Data Structures

struct NetworkSettings: Codable {
    var enableMonitoring: Bool = true
    var enableDataUsageTracking: Bool = true
    var enableBackgroundRequests: Bool = true
    var allowCellularData: Bool = true
    var allowRoaming: Bool = false
    var requestTimeout: TimeInterval = 30.0
    var maxRetries: Int = 3
    var retryDelay: TimeInterval = 1.0
    var enableCompression: Bool = true
    var enableCaching: Bool = true
    var cacheSizeLimit: Int = 100 * 1024 * 1024 // 100MB
    var enableLogging: Bool = true
    var logLevel: LogLevel = .info
}

enum LogLevel: String, Codable {
    case debug = "Debug"
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
}

struct NetworkStatistics: Codable {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var averageResponseTime: TimeInterval = 0
    var totalDataTransferred: Double = 0
    var endpointStatistics: [EndpointStatistics] = []
    
    var successRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(successfulRequests) / Double(totalRequests) * 100
    }
}

struct EndpointStatistics: Codable {
    let endpoint: NetworkService.APIEndpoint
    var requestCount: Int
    var averageResponseTime: TimeInterval
    var successRate: Double
}

struct NetworkConnection: Identifiable, Codable {
    let id: String
    let name: String
    let url: String
    let type: ConnectionType
    var status: ConnectionStatus
    let createdAt: Date
    var lastUsed: Date
    
    enum ConnectionType: String, Codable {
        case api = "API"
        case websocket = "WebSocket"
        case download = "Download"
        case upload = "Upload"
    }
    
    enum ConnectionStatus: String, Codable {
        case connecting = "Connecting"
        case connected = "Connected"
        case disconnected = "Disconnected"
        case error = "Error"
    }
}

struct ConnectionRecord: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let isConnected: Bool
    let connectionType: NetworkService.ConnectionType
    let networkQuality: NetworkService.NetworkQuality
    let latency: Double
    let bandwidth: Double
}

struct DataUsage: Codable {
    var totalUsage: Double = 0 // MB
    var dailyUsage: Double = 0 // MB
    var currentSessionUsage: Double = 0 // MB
    var lastResetDate: Date = Date()
    
    var monthlyUsage: Double {
        // Calculate usage for current month
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return 0 }
        
        // In a real implementation, you would track usage by date
        return dailyUsage * Double(calendar.dateComponents([.day], from: monthStart, to: now).day ?? 1)
    }
}

struct NetworkResponse {
    let data: Data
    let statusCode: Int
    let headers: [String: String]
    let duration: TimeInterval
}

enum NetworkError: Error {
    case noConnection
    case invalidResponse
    case timeout
    case serverError(Int)
    case decodingError
}

struct NetworkReport {
    let isConnected: Bool
    let connectionType: NetworkService.ConnectionType
    let networkQuality: NetworkService.NetworkQuality
    let uptime: Double
    let averageLatency: Double
    let averageBandwidth: Double
    let dataUsage: DataUsage
    let networkStatistics: NetworkStatistics
    let activeConnections: [NetworkConnection]
    let generatedAt: Date
}
