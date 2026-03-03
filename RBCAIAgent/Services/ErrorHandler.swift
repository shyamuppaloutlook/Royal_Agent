import Foundation
import SwiftUI
import Combine

class ErrorHandler: ObservableObject {
    @Published var errors: [AppError] = []
    @Published var hasCriticalError: Bool = false
    @Published var errorCount: Int = 0
    @Published var lastErrorDate: Date?
    @Published var errorCategories: [ErrorCategory: Int] = [:]
    @Published var isRecovering: Bool = false
    @Published var recoveryProgress: Double = 0.0
    
    private let errorQueue = DispatchQueue(label: "com.rbc.error.handler", qos: .userInitiated)
    private var errorHistory: [ErrorHistory] = []
    private var recoveryStrategies: [ErrorCategory: RecoveryStrategy] = [:]
    
    // MARK: - Error Categories
    
    enum ErrorCategory: String, CaseIterable {
        case network = "Network"
        case authentication = "Authentication"
        case dataCorruption = "Data Corruption"
        case apiLimit = "API Limit"
        case validation = "Validation"
        case permission = "Permission"
        case timeout = "Timeout"
        case configuration = "Configuration"
        case memory = "Memory"
        case storage = "Storage"
        case parsing = "Parsing"
        case calculation = "Calculation"
        case ui = "User Interface"
        case sync = "Synchronization"
        case security = "Security"
        case performance = "Performance"
        case unknown = "Unknown"
        
        var severity: ErrorSeverity {
            switch self {
            case .network, .timeout, .sync:
                return .medium
            case .authentication, .security, .permission:
                return .high
            case .dataCorruption, .memory, .storage:
                return .critical
            case .apiLimit, .validation, .configuration, .parsing, .calculation, .ui, .performance:
                return .medium
            case .unknown:
                return .low
            }
        }
        
        var icon: String {
            switch self {
            case .network: return "wifi.slash"
            case .authentication: return "person.crop.circle.badge.exclamationmark"
            case .dataCorruption: return "doc.text.magnifyingglass"
            case .apiLimit: return "speedometer"
            case .validation: return "checkmark.circle.badge.exclamationmark"
            case .permission: return "lock.shield"
            case .timeout: return "clock.badge.exclamationmark"
            case .configuration: return "gear.badge"
            case .memory: return "memorychip"
            case .storage: return "internaldrive"
            case .parsing: return "doc.badge.gearshape"
            case .calculation: return "function"
            case .ui: return "app.badge"
            case .sync: return "arrow.triangle.2.circlepath"
            case .security: return "shield.leopard.up"
            case .performance: return "gauge.high"
            case .unknown: return "questionmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .network, .timeout, .sync:
                return .orange
            case .authentication, .security, .permission:
                return .red
            case .dataCorruption, .memory, .storage:
                return .purple
            case .apiLimit, .validation, .configuration, .parsing, .calculation, .ui, .performance:
                return .yellow
            case .unknown:
                return .gray
            }
        }
    }
    
    // MARK: - Error Severity
    
    enum ErrorSeverity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var priority: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var requiresImmediateAction: Bool {
            return self == .critical || self == .high
        }
    }
    
    // MARK: - Error Status
    
    enum ErrorStatus: String, CaseIterable {
        case pending = "Pending"
        case investigating = "Investigating"
        case recovering = "Recovering"
        case resolved = "Resolved"
        case ignored = "Ignored"
        case escalated = "Escalated"
    }
    
    // MARK: - Recovery Strategy
    
    enum RecoveryStrategy: String, CaseIterable {
        case retry = "Retry Operation"
        case refresh = "Refresh Data"
        case reauthenticate = "Re-authenticate"
        case clearCache = "Clear Cache"
        case resetConfiguration = "Reset Configuration"
        case contactSupport = "Contact Support"
        case manualIntervention = "Manual Intervention"
        case automaticRecovery = "Automatic Recovery"
        case fallbackMode = "Fallback Mode"
        case restartService = "Restart Service"
        case rebuildData = "Rebuild Data"
        case updateSettings = "Update Settings"
        case checkPermissions = "Check Permissions"
        case verifyConnection = "Verify Connection"
        case optimizePerformance = "Optimize Performance"
    }
    
    // MARK: - Main Error Handling
    
    func handleError(_ error: Error, context: ErrorContext? = nil) {
        let appError = createAppError(from: error, context: context)
        
        errorQueue.async {
            self.processError(appError)
        }
    }
    
    private func createAppError(from error: Error, context: ErrorContext?) -> AppError {
        let category = categorizeError(error)
        let severity = determineSeverity(error: error, category: category)
        let id = UUID().uuidString
        
        return AppError(
            id: id,
            category: category,
            severity: severity,
            title: generateErrorTitle(error: error, category: category),
            message: error.localizedDescription,
            underlyingError: error,
            context: context,
            timestamp: Date(),
            status: .pending,
            recoveryStrategies: determineRecoveryStrategies(category: category, severity: severity),
            userFriendlyMessage: generateUserFriendlyMessage(error: error, category: category),
            technicalDetails: generateTechnicalDetails(error: error),
            affectedComponents: identifyAffectedComponents(error: error, context: context),
            impact: assessImpact(error: error, category: category, severity: severity)
        )
    }
    
    private func processError(_ error: AppError) {
        // Add to error list
        DispatchQueue.main.async {
            self.errors.append(error)
            self.errorCount += 1
            self.lastErrorDate = error.timestamp
            
            // Update category counts
            self.errorCategories[error.category, default: 0] += 1
            
            // Check for critical errors
            if error.severity == .critical {
                self.hasCriticalError = true
            }
            
            // Sort errors by severity and timestamp
            self.errors.sort { first, second in
                if first.severity.priority != second.severity.priority {
                    return first.severity.priority > second.severity.priority
                }
                return first.timestamp > second.timestamp
            }
        }
        
        // Add to history
        let history = ErrorHistory(
            errorId: error.id,
            timestamp: error.timestamp,
            category: error.category,
            severity: error.severity,
            resolutionTime: nil,
            resolution: nil
        )
        errorHistory.append(history)
        
        // Attempt automatic recovery
        if error.severity.priority >= ErrorSeverity.medium.priority {
            attemptRecovery(for: error)
        }
        
        // Log error
        logError(error)
        
        // Update metrics
        updateErrorMetrics(error)
    }
    
    // MARK: - Error Categorization
    
    private func categorizeError(_ error: Error) -> ErrorCategory {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost:
                return .network
            case .timedOut:
                return .timeout
            case .badServerResponse, .badURL:
                return .apiLimit
            default:
                return .network
            }
        }
        
        if error.localizedDescription.contains("authentication") || 
           error.localizedDescription.contains("unauthorized") ||
           error.localizedDescription.contains("token") {
            return .authentication
        }
        
        if error.localizedDescription.contains("permission") || 
           error.localizedDescription.contains("access denied") {
            return .permission
        }
        
        if error.localizedDescription.contains("corrupt") || 
           error.localizedDescription.contains("invalid data") {
            return .dataCorruption
        }
        
        if error.localizedDescription.contains("limit") || 
           error.localizedDescription.contains("quota") {
            return .apiLimit
        }
        
        if error.localizedDescription.contains("validation") || 
           error.localizedDescription.contains("invalid") {
            return .validation
        }
        
        if error.localizedDescription.contains("memory") || 
           error.localizedDescription.contains("out of memory") {
            return .memory
        }
        
        if error.localizedDescription.contains("storage") || 
           error.localizedDescription.contains("disk") {
            return .storage
        }
        
        if error.localizedDescription.contains("parse") || 
           error.localizedDescription.contains("json") {
            return .parsing
        }
        
        if error.localizedDescription.contains("calculation") || 
           error.localizedDescription.contains("math") {
            return .calculation
        }
        
        if error.localizedDescription.contains("sync") || 
           error.localizedDescription.contains("synchronization") {
            return .sync
        }
        
        if error.localizedDescription.contains("security") || 
           error.localizedDescription.contains("encryption") {
            return .security
        }
        
        if error.localizedDescription.contains("performance") || 
           error.localizedDescription.contains("slow") {
            return .performance
        }
        
        return .unknown
    }
    
    private func determineSeverity(error: Error, category: ErrorCategory) -> ErrorSeverity {
        // Base severity from category
        var severity = category.severity
        
        // Adjust based on error characteristics
        if error.localizedDescription.contains("critical") || 
           error.localizedDescription.contains("fatal") {
            severity = .critical
        }
        
        if error.localizedDescription.contains("warning") || 
           error.localizedDescription.contains("minor") {
            severity = .low
        }
        
        // Check for repeated occurrences
        let recentSimilarErrors = errors.filter { recentError in
            recentError.category == category && 
            Date().timeIntervalSince(recentError.timestamp) < 300 // 5 minutes
        }
        
        if recentSimilarErrors.count > 3 {
            severity = .critical
        } else if recentSimilarErrors.count > 1 {
            severity = .high
        }
        
        return severity
    }
    
    // MARK: - Recovery Methods
    
    private func attemptRecovery(for error: AppError) {
        DispatchQueue.main.async {
            self.isRecovering = true
            self.recoveryProgress = 0.0
        }
        
        let strategies = error.recoveryStrategies
        
        for (index, strategy) in strategies.enumerated() {
            executeRecoveryStrategy(strategy, for: error) { success in
                DispatchQueue.main.async {
                    self.recoveryProgress = Double(index + 1) / Double(strategies.count)
                    
                    if success {
                        self.markErrorAsResolved(error.id, resolution: "Automatic recovery using \(strategy.rawValue)")
                        self.isRecovering = false
                    } else if index == strategies.count - 1 {
                        // All strategies failed
                        self.escalateError(error)
                        self.isRecovering = false
                    }
                }
            }
        }
    }
    
    private func executeRecoveryStrategy(_ strategy: RecoveryStrategy, for error: AppError, completion: @escaping (Bool) -> Void) {
        switch strategy {
        case .retry:
            executeRetryStrategy(for: error, completion: completion)
        case .refresh:
            executeRefreshStrategy(for: error, completion: completion)
        case .reauthenticate:
            executeReauthenticationStrategy(for: error, completion: completion)
        case .clearCache:
            executeClearCacheStrategy(for: error, completion: completion)
        case .resetConfiguration:
            executeResetConfigurationStrategy(for: error, completion: completion)
        case .contactSupport:
            executeContactSupportStrategy(for: error, completion: completion)
        case .manualIntervention:
            executeManualInterventionStrategy(for: error, completion: completion)
        case .automaticRecovery:
            executeAutomaticRecoveryStrategy(for: error, completion: completion)
        case .fallbackMode:
            executeFallbackModeStrategy(for: error, completion: completion)
        case .restartService:
            executeRestartServiceStrategy(for: error, completion: completion)
        case .rebuildData:
            executeRebuildDataStrategy(for: error, completion: completion)
        case .updateSettings:
            executeUpdateSettingsStrategy(for: error, completion: completion)
        case .checkPermissions:
            executeCheckPermissionsStrategy(for: error, completion: completion)
        case .verifyConnection:
            executeVerifyConnectionStrategy(for: error, completion: completion)
        case .optimizePerformance:
            executeOptimizePerformanceStrategy(for: error, completion: completion)
        }
    }
    
    private func executeRetryStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement retry logic based on error context
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(true) // Simulate successful retry
        }
    }
    
    private func executeRefreshStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement data refresh logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true) // Simulate successful refresh
        }
    }
    
    private func executeReauthenticationStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement reauthentication logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            completion(true) // Simulate successful reauthentication
        }
    }
    
    private func executeClearCacheStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement cache clearing logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true) // Simulate successful cache clear
        }
    }
    
    private func executeResetConfigurationStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement configuration reset logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(true) // Simulate successful reset
        }
    }
    
    private func executeContactSupportStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement support contact logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(false) // Requires manual intervention
        }
    }
    
    private func executeManualInterventionStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Mark as requiring manual intervention
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(false) // Requires manual intervention
        }
    }
    
    private func executeAutomaticRecoveryStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement automatic recovery logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            completion(true) // Simulate successful automatic recovery
        }
    }
    
    private func executeFallbackModeStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement fallback mode logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true) // Simulate successful fallback activation
        }
    }
    
    private func executeRestartServiceStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement service restart logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(true) // Simulate successful service restart
        }
    }
    
    private func executeRebuildDataStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement data rebuild logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            completion(true) // Simulate successful data rebuild
        }
    }
    
    private func executeUpdateSettingsStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement settings update logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true) // Simulate successful settings update
        }
    }
    
    private func executeCheckPermissionsStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement permission check logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true) // Simulate successful permission check
        }
    }
    
    private func executeVerifyConnectionStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement connection verification logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(true) // Simulate successful connection verification
        }
    }
    
    private func executeOptimizePerformanceStrategy(for error: AppError, completion: @escaping (Bool) -> Void) {
        // Implement performance optimization logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            completion(true) // Simulate successful optimization
        }
    }
    
    // MARK: - Error Resolution
    
    func markErrorAsResolved(_ errorId: String, resolution: String) {
        DispatchQueue.main.async {
            if let index = self.errors.firstIndex(where: { $0.id == errorId }) {
                self.errors[index].status = .resolved
                self.errors[index].resolution = resolution
                
                // Update history
                if let historyIndex = self.errorHistory.firstIndex(where: { $0.errorId == errorId }) {
                    self.errorHistory[historyIndex].resolutionTime = Date()
                    self.errorHistory[historyIndex].resolution = resolution
                }
                
                // Check for critical errors
                self.hasCriticalError = self.errors.contains { $0.severity == .critical && $0.status != .resolved }
            }
        }
    }
    
    func ignoreError(_ errorId: String) {
        DispatchQueue.main.async {
            if let index = self.errors.firstIndex(where: { $0.id == errorId }) {
                self.errors[index].status = .ignored
            }
        }
    }
    
    func escalateError(_ error: AppError) {
        DispatchQueue.main.async {
            if let index = self.errors.firstIndex(where: { $0.id == error.id }) {
                self.errors[index].status = .escalated
            }
        }
        
        // Send to monitoring service
        sendToMonitoringService(error)
    }
    
    // MARK: - Error Analysis
    
    func getErrorStatistics() -> ErrorStatistics {
        let totalErrors = errors.count
        let resolvedErrors = errors.filter { $0.status == .resolved }.count
        let criticalErrors = errors.filter { $0.severity == .critical }.count
        let averageResolutionTime = calculateAverageResolutionTime()
        
        return ErrorStatistics(
            totalErrors: totalErrors,
            resolvedErrors: resolvedErrors,
            pendingErrors: totalErrors - resolvedErrors,
            criticalErrors: criticalErrors,
            averageResolutionTime: averageResolutionTime,
            errorRate: calculateErrorRate(),
            categoryBreakdown: errorCategories,
            mostCommonCategory: findMostCommonCategory(),
            trend: calculateErrorTrend()
        )
    }
    
    private func calculateAverageResolutionTime() -> TimeInterval {
        let resolvedHistory = errorHistory.filter { $0.resolutionTime != nil }
        guard !resolvedHistory.isEmpty else { return 0 }
        
        let totalTime = resolvedHistory.reduce(0) { total, history in
            total + (history.resolutionTime?.timeIntervalSince(history.timestamp) ?? 0)
        }
        
        return totalTime / Double(resolvedHistory.count)
    }
    
    private func calculateErrorRate() -> Double {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let recentErrors = errors.filter { $0.timestamp >= oneHourAgo }
        
        return Double(recentErrors.count)
    }
    
    private func findMostCommonCategory() -> ErrorCategory? {
        return errorCategories.max { a, b in a.value < b.value }?.key
    }
    
    private func calculateErrorTrend() -> ErrorTrend {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let twoHoursAgo = now.addingTimeInterval(-7200)
        
        let recentErrors = errors.filter { $0.timestamp >= oneHourAgo }.count
        let previousErrors = errors.filter { $0.timestamp >= twoHoursAgo && $0.timestamp < oneHourAgo }.count
        
        if recentErrors > previousErrors * 1.2 {
            return .increasing
        } else if recentErrors < previousErrors * 0.8 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateErrorTitle(error: Error, category: ErrorCategory) -> String {
        return "\(category.rawValue) Error"
    }
    
    private func generateUserFriendlyMessage(error: Error, category: ErrorCategory) -> String {
        switch category {
        case .network:
            return "Network connection issue. Please check your internet connection."
        case .authentication:
            return "Authentication required. Please sign in again."
        case .dataCorruption:
            return "Data issue detected. We're working to fix it."
        case .apiLimit:
            return "Service temporarily unavailable. Please try again later."
        case .validation:
            return "Invalid input provided. Please check your data."
        case .permission:
            return "Permission denied. Please check your settings."
        case .timeout:
            return "Operation timed out. Please try again."
        case .configuration:
            return "Configuration issue. Please check your settings."
        case .memory:
            return "Memory issue detected. Please restart the app."
        case .storage:
            return "Storage issue. Please free up space."
        case .parsing:
            return "Data format issue. We're working to fix it."
        case .calculation:
            return "Calculation error. Please try again."
        case .ui:
            return "Display issue. Please restart the app."
        case .sync:
            return "Synchronization issue. We're working to fix it."
        case .security:
            return "Security issue detected. Please contact support."
        case .performance:
            return "Performance issue detected. We're optimizing."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    private func generateTechnicalDetails(error: Error) -> String {
        return """
        Error: \(error.localizedDescription)
        Type: \(type(of: error))
        Code: \((error as NSError).code)
        Domain: \((error as NSError).domain)
        """
    }
    
    private func identifyAffectedComponents(error: Error, context: ErrorContext?) -> [String] {
        var components: [String] = []
        
        if let context = context {
            components.append(context.component)
            components.append(contentsOf: context.dependencies)
        }
        
        // Add components based on error type
        if error is URLError {
            components.append("NetworkService")
        }
        
        return components
    }
    
    private func assessImpact(error: Error, category: ErrorCategory, severity: ErrorSeverity) -> ErrorImpact {
        switch (category, severity) {
        case (.critical, _), (_, .critical):
            return .critical
        case (.authentication, .high), (.security, .high), (.dataCorruption, .high):
            return .high
        case (.network, .medium), (.sync, .medium), (.apiLimit, .medium):
            return .medium
        default:
            return .low
        }
    }
    
    private func determineRecoveryStrategies(category: ErrorCategory, severity: ErrorSeverity) -> [RecoveryStrategy] {
        var strategies: [RecoveryStrategy] = []
        
        switch category {
        case .network:
            strategies = [.verifyConnection, .retry, .fallbackMode]
        case .authentication:
            strategies = [.reauthenticate, .checkPermissions, .contactSupport]
        case .dataCorruption:
            strategies = [.rebuildData, .clearCache, .contactSupport]
        case .apiLimit:
            strategies = [.retry, .automaticRecovery]
        case .validation:
            strategies = [.updateSettings, .manualIntervention]
        case .permission:
            strategies = [.checkPermissions, .updateSettings]
        case .timeout:
            strategies = [.retry, .optimizePerformance]
        case .configuration:
            strategies = [.resetConfiguration, .updateSettings]
        case .memory:
            strategies = [.restartService, .clearCache]
        case .storage:
            strategies = [.clearCache, .manualIntervention]
        case .parsing:
            strategies = [.refresh, .rebuildData]
        case .calculation:
            strategies = [.retry, .automaticRecovery]
        case .ui:
            strategies = [.restartService, .fallbackMode]
        case .sync:
            strategies = [.retry, .refresh, .rebuildData]
        case .security:
            strategies = [.contactSupport, .manualIntervention]
        case .performance:
            strategies = [.optimizePerformance, .clearCache]
        case .unknown:
            strategies = [.automaticRecovery, .contactSupport]
        }
        
        // Adjust strategies based on severity
        if severity == .critical {
            strategies.insert(.contactSupport, at: 0)
        }
        
        return strategies
    }
    
    private func logError(_ error: AppError) {
        // Implement logging to file or service
        print("Error logged: \(error.title) - \(error.message)")
    }
    
    private func updateErrorMetrics(_ error: AppError) {
        // Update error metrics for monitoring
    }
    
    private func sendToMonitoringService(_ error: AppError) {
        // Send error to external monitoring service
    }
    
    // MARK: - Public Interface
    
    func clearResolvedErrors() {
        DispatchQueue.main.async {
            self.errors.removeAll { $0.status == .resolved }
            self.errorCount = self.errors.count
        }
    }
    
    func clearAllErrors() {
        DispatchQueue.main.async {
            self.errors.removeAll()
            self.errorCount = 0
            self.hasCriticalError = false
            self.errorCategories.removeAll()
        }
    }
    
    func getErrorsByCategory(_ category: ErrorCategory) -> [AppError] {
        return errors.filter { $0.category == category }
    }
    
    func getErrorsBySeverity(_ severity: ErrorSeverity) -> [AppError] {
        return errors.filter { $0.severity == severity }
    }
    
    func getPendingErrors() -> [AppError] {
        return errors.filter { $0.status == .pending }
    }
    
    func getCriticalErrors() -> [AppError] {
        return errors.filter { $0.severity == .critical && $0.status != .resolved }
    }
}

// MARK: - Data Structures

struct AppError: Identifiable {
    let id: String
    let category: ErrorHandler.ErrorCategory
    let severity: ErrorHandler.ErrorSeverity
    let title: String
    let message: String
    let underlyingError: Error
    let context: ErrorContext?
    let timestamp: Date
    var status: ErrorHandler.ErrorStatus
    let recoveryStrategies: [ErrorHandler.RecoveryStrategy]
    let userFriendlyMessage: String
    let technicalDetails: String
    let affectedComponents: [String]
    let impact: ErrorImpact
    var resolution: String?
}

struct ErrorContext {
    let component: String
    let operation: String
    let dependencies: [String]
    let additionalInfo: [String: Any]
}

enum ErrorImpact {
    case low, medium, high, critical
    
    var description: String {
        switch self {
        case .low: return "Minimal impact"
        case .medium: return "Some functionality affected"
        case .high: return "Major functionality affected"
        case .critical: return "System stability at risk"
        }
    }
}

struct ErrorHistory {
    let errorId: String
    let timestamp: Date
    let category: ErrorHandler.ErrorCategory
    let severity: ErrorHandler.ErrorSeverity
    let resolutionTime: Date?
    let resolution: String?
}

struct ErrorStatistics {
    let totalErrors: Int
    let resolvedErrors: Int
    let pendingErrors: Int
    let criticalErrors: Int
    let averageResolutionTime: TimeInterval
    let errorRate: Double
    let categoryBreakdown: [ErrorHandler.ErrorCategory: Int]
    let mostCommonCategory: ErrorHandler.ErrorCategory?
    let trend: ErrorTrend
}

enum ErrorTrend {
    case increasing, decreasing, stable
    
    var description: String {
        switch self {
        case .increasing: return "Errors are increasing"
        case .decreasing: return "Errors are decreasing"
        case .stable: return "Error rate is stable"
        }
    }
}
