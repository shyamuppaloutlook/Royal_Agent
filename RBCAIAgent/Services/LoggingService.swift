import Foundation
import SwiftUI
import Combine
import os.log

class LoggingService: ObservableObject {
    @Published var isLoggingEnabled: Bool = true
    @Published var logLevel: LogLevel = .info
    @Published var logs: [LogEntry] = []
    @Published var loggingSettings: LoggingSettings = LoggingSettings()
    @Published var logStatistics: LogStatistics = LogStatistics()
    @Published var activeLoggers: [LoggerInfo] = []
    @Published var logFilters: LogFilters = LogFilters()
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    
    private let logger = Logger(subsystem: "com.rbc.aiagent", category: "LoggingService")
    private var logQueue = DispatchQueue(label: "com.rbc.logging", qos: .utility)
    private var cancellables = Set<AnyCancellable>()
    private var logFileHandle: FileHandle?
    private var currentLogFile: URL?
    
    // MARK: - Log Levels
    
    enum LogLevel: String, CaseIterable, Identifiable {
        case debug = "Debug"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        case critical = "Critical"
        
        var id: String { return rawValue }
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
        
        var color: Color {
            switch self {
            case .debug: return .gray
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .debug: return "ladybug"
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .critical: return "exclamationmark.octagon"
            }
        }
        
        var priority: Int {
            switch self {
            case .debug: return 0
            case .info: return 1
            case .warning: return 2
            case .error: return 3
            case .critical: return 4
            }
        }
    }
    
    // MARK: - Log Categories
    
    enum LogCategory: String, CaseIterable, Identifiable {
        case system = "System"
        case network = "Network"
        case security = "Security"
        case performance = "Performance"
        case user = "User"
        case api = "API"
        case database = "Database"
        case ui = "UI"
        case background = "Background"
        case error = "Error"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .system: return "gear"
            case .network: return "network"
            case .security: return "shield"
            case .performance: return "speedometer"
            case .user: return "person.crop.circle"
            case .api: return "terminal"
            case .database: return "externaldrive"
            case .ui: return "rectangle.stack"
            case .background: return "clock"
            case .error: return "xmark.octagon"
            }
        }
        
        var color: Color {
            switch self {
            case .system: return .gray
            case .network: return .blue
            case .security: return .red
            case .performance: return .green
            case .user: return .orange
            case .api: return .purple
            case .database: return .indigo
            case .ui: return .pink
            case .background: return .teal
            case .error: return .red
            }
        }
    }
    
    // MARK: - Log Sources
    
    enum LogSource: String, CaseIterable, Identifiable {
        case app = "App"
        case service = "Service"
        case view = "View"
        case controller = "Controller"
        case manager = "Manager"
        case utility = "Utility"
        case extension = "Extension"
        case widget = "Widget"
        case watch = "Watch"
        case mac = "Mac"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .app: return "app"
            case .service: return "gearshape.2"
            case .view: return "rectangle"
            case .controller: return "gamecontroller"
            case .manager: return "person.2"
            case .utility: return "wrench.and.screwdriver"
            case .extension: return "puzzlepiece"
            case .widget: return "square.grid.2x2"
            case .watch: return "applewatch"
            case .mac: return "desktopcomputer"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupLoggingService()
        loadLoggingSettings()
        setupLogFile()
        startLogRotation()
        initializeLoggers()
    }
    
    private func setupLoggingService() {
        // Initialize logging service components
    }
    
    private func loadLoggingSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "logging_settings"),
           let settings = try? JSONDecoder().decode(LoggingSettings.self, from: data) {
            loggingSettings = settings
            isLoggingEnabled = settings.isEnabled
            logLevel = settings.logLevel
        }
        
        if let data = defaults.data(forKey: "log_filters"),
           let filters = try? JSONDecoder().decode(LogFilters.self, from: data) {
            logFilters = filters
        }
    }
    
    private func saveLoggingSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(loggingSettings) {
            defaults.set(data, forKey: "logging_settings")
        }
        
        if let data = try? JSONEncoder().encode(logFilters) {
            defaults.set(data, forKey: "log_filters")
        }
    }
    
    private func setupLogFile() {
        guard loggingSettings.enableFileLogging else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logsDirectory = documentsPath.appendingPathComponent("Logs")
        
        if !FileManager.default.fileExists(atPath: logsDirectory.path) {
            try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "app-\(dateFormatter.string(from: Date())).log"
        currentLogFile = logsDirectory.appendingPathComponent(fileName)
        
        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: currentLogFile!.path) {
            FileManager.default.createFile(atPath: currentLogFile!.path, contents: nil)
        }
        
        // Open file handle
        do {
            logFileHandle = try FileHandle(forWritingTo: currentLogFile!)
            logFileHandle?.seekToEndOfFile()
        } catch {
            logger.error("Failed to open log file: \(error.localizedDescription)")
        }
    }
    
    private func startLogRotation() {
        guard loggingSettings.enableLogRotation else { return }
        
        Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) { [weak self] _ in
            self?.checkLogRotation()
        }
    }
    
    private func checkLogRotation() {
        guard let logFile = currentLogFile else { return }
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: logFile.path)
        let fileSize = attributes?[.size] as? Int64 ?? 0
        
        if fileSize > loggingSettings.maxLogFileSize {
            rotateLogFile()
        }
    }
    
    private func rotateLogFile() {
        logFileHandle?.closeFile()
        
        // Rename current log file
        if let logFile = currentLogFile {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let rotatedFileName = "app-\(dateFormatter.string(from: Date())).log"
            let rotatedFile = logFile.deletingLastPathComponent().appendingPathComponent(rotatedFileName)
            
            try? FileManager.default.moveItem(at: logFile, to: rotatedFile)
        }
        
        // Create new log file
        setupLogFile()
    }
    
    private func initializeLoggers() {
        // Initialize default loggers for different components
        activeLoggers = [
            LoggerInfo(id: "app", name: "Application Logger", category: .system, level: .info, isEnabled: true),
            LoggerInfo(id: "network", name: "Network Logger", category: .network, level: .info, isEnabled: true),
            LoggerInfo(id: "security", name: "Security Logger", category: .security, level: .warning, isEnabled: true),
            LoggerInfo(id: "performance", name: "Performance Logger", category: .performance, level: .info, isEnabled: true),
            LoggerInfo(id: "api", name: "API Logger", category: .api, level: .info, isEnabled: true)
        ]
    }
    
    // MARK: - Logging Methods
    
    func log(_ level: LogLevel, _ message: String, category: LogCategory = .system, source: LogSource = .app, metadata: [String: Any] = [:]) {
        guard isLoggingEnabled && level.priority >= logLevel.priority else { return }
        
        let logEntry = LogEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            level: level,
            category: category,
            source: source,
            message: message,
            metadata: metadata,
            thread: Thread.current.name ?? "Unknown"
        )
        
        // Add to in-memory logs
        DispatchQueue.main.async {
            self.logs.append(logEntry)
            
            // Keep only recent logs (based on settings)
            if self.logs.count > self.loggingSettings.maxInMemoryLogs {
                self.logs = Array(self.logs.suffix(self.loggingSettings.maxInMemoryLogs))
            }
            
            self.updateLogStatistics()
        }
        
        // Log to system logger
        logger.log(level: level.osLogType, "\(message)")
        
        // Log to file if enabled
        if loggingSettings.enableFileLogging {
            logToFile(logEntry)
        }
        
        // Log to remote if enabled
        if loggingSettings.enableRemoteLogging {
            logToRemote(logEntry)
        }
    }
    
    private func logToFile(_ entry: LogEntry) {
        guard let fileHandle = logFileHandle else { return }
        
        let logLine = formatLogEntry(entry)
        
        logQueue.async {
            if let data = logLine.data(using: .utf8) {
                fileHandle.write(data)
            }
        }
    }
    
    private func formatLogEntry(_ entry: LogEntry) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        var logLine = "[\(formatter.string(from: entry.timestamp))] "
        logLine += "[\(entry.level.rawValue)] "
        logLine += "[\(entry.category.rawValue)] "
        logLine += "[\(entry.source.rawValue)] "
        logLine += "[\(entry.thread)] "
        logLine += "\(entry.message)"
        
        if !entry.metadata.isEmpty {
            logLine += " | Metadata: \(entry.metadata)"
        }
        
        logLine += "\n"
        
        return logLine
    }
    
    private func logToRemote(_ entry: LogEntry) {
        // Simulate remote logging
        // In a real implementation, you would send logs to a remote service
        logQueue.async {
            // Send log to remote service
            print("Remote logging: \(entry.message)")
        }
    }
    
    // MARK: - Convenience Methods
    
    func debug(_ message: String, category: LogCategory = .system, source: LogSource = .app, metadata: [String: Any] = [:]) {
        log(.debug, message, category: category, source: source, metadata: metadata)
    }
    
    func info(_ message: String, category: LogCategory = .system, source: LogSource = .app, metadata: [String: Any] = [:]) {
        log(.info, message, category: category, source: source, metadata: metadata)
    }
    
    func warning(_ message: String, category: LogCategory = .system, source: LogSource = .app, metadata: [String: Any] = [:]) {
        log(.warning, message, category: category, source: source, metadata: metadata)
    }
    
    func error(_ message: String, category: LogCategory = .system, source: LogSource = .app, metadata: [String: Any] = [:]) {
        log(.error, message, category: category, source: source, metadata: metadata)
    }
    
    func critical(_ message: String, category: LogCategory = .system, source: LogSource = .app, metadata: [String: Any] = [:]) {
        log(.critical, message, category: category, source: source, metadata: metadata)
    }
    
    // MARK: - Log Management
    
    func clearLogs() {
        logs.removeAll()
        updateLogStatistics()
    }
    
    func clearLogs(category: LogCategory) {
        logs.removeAll { $0.category == category }
        updateLogStatistics()
    }
    
    func clearLogs(level: LogLevel) {
        logs.removeAll { $0.level == level }
        updateLogStatistics()
    }
    
    func clearLogs(olderThan date: Date) {
        logs.removeAll { $0.timestamp < date }
        updateLogStatistics()
    }
    
    func filterLogs() -> [LogEntry] {
        return logs.filter { entry in
            // Filter by level
            if let minLevel = logFilters.minimumLevel, entry.level.priority < minLevel.priority {
                return false
            }
            
            // Filter by categories
            if !logFilters.categories.isEmpty && !logFilters.categories.contains(entry.category) {
                return false
            }
            
            // Filter by sources
            if !logFilters.sources.isEmpty && !logFilters.sources.contains(entry.source) {
                return false
            }
            
            // Filter by date range
            if let startDate = logFilters.startDate, entry.timestamp < startDate {
                return false
            }
            
            if let endDate = logFilters.endDate, entry.timestamp > endDate {
                return false
            }
            
            // Filter by search term
            if let searchTerm = logFilters.searchTerm, !searchTerm.isEmpty {
                return entry.message.localizedCaseInsensitiveContains(searchTerm)
            }
            
            return true
        }
    }
    
    // MARK: - Export Operations
    
    func exportLogs(format: ExportFormat = .json) async -> URL? {
        isExporting = true
        exportProgress = 0.0
        
        let filteredLogs = filterLogs()
        let totalLogs = filteredLogs.count
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportsDirectory = documentsPath.appendingPathComponent("Exports")
        
        if !FileManager.default.fileExists(atPath: exportsDirectory.path) {
            try? FileManager.default.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let fileName = "logs-\(dateFormatter.string(from: Date())).\(format.fileExtension)"
        let exportURL = exportsDirectory.appendingPathComponent(fileName)
        
        do {
            let exportData = try formatLogs(filteredLogs, format: format)
            try exportData.write(to: exportURL)
            
            isExporting = false
            exportProgress = 1.0
            
            return exportURL
            
        } catch {
            error("Failed to export logs: \(error.localizedDescription)", category: .system)
            isExporting = false
            return nil
        }
    }
    
    private func formatLogs(_ logs: [LogEntry], format: ExportFormat) throws -> Data {
        switch format {
        case .json:
            return try JSONEncoder().encode(logs)
        case .csv:
            return try formatLogsAsCSV(logs)
        case .txt:
            return try formatLogsAsText(logs)
        case .xml:
            return try formatLogsAsXML(logs)
        }
    }
    
    private func formatLogsAsCSV(_ logs: [LogEntry]) throws -> Data {
        var csvContent = "Timestamp,Level,Category,Source,Thread,Message,Metadata\n"
        
        for log in logs {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            
            csvContent += "\(formatter.string(from: log.timestamp)),"
            csvContent += "\(log.level.rawValue),"
            csvContent += "\(log.category.rawValue),"
            csvContent += "\(log.source.rawValue),"
            csvContent += "\(log.thread),"
            csvContent += "\"\(log.message.replacingOccurrences(of: "\"", with: "\"\""))\","
            
            let metadataString = log.metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
            csvContent += "\"\(metadataString)\"\n"
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func formatLogsAsText(_ logs: [LogEntry]) throws -> Data {
        var textContent = ""
        
        for log in logs {
            textContent += formatLogEntry(log)
        }
        
        return textContent.data(using: .utf8) ?? Data()
    }
    
    private func formatLogsAsXML(_ logs: [LogEntry]) throws -> Data {
        var xmlContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xmlContent += "<logs>\n"
        
        for log in logs {
            xmlContent += "  <log>\n"
            xmlContent += "    <timestamp>\(log.timestamp.timeIntervalSince1970)</timestamp>\n"
            xmlContent += "    <level>\(log.level.rawValue)</level>\n"
            xmlContent += "    <category>\(log.category.rawValue)</category>\n"
            xmlContent += "    <source>\(log.source.rawValue)</source>\n"
            xmlContent += "    <thread>\(log.thread)</thread>\n"
            xmlContent += "    <message>\(log.message.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</message>\n"
            
            if !log.metadata.isEmpty {
                xmlContent += "    <metadata>\n"
                for (key, value) in log.metadata {
                    xmlContent += "      <entry key=\"\(key)\">\(value)</entry>\n"
                }
                xmlContent += "    </metadata>\n"
            }
            
            xmlContent += "  </log>\n"
        }
        
        xmlContent += "</logs>"
        
        return xmlContent.data(using: .utf8) ?? Data()
    }
    
    // MARK: - Statistics and Analytics
    
    private func updateLogStatistics() {
        let totalLogs = logs.count
        let debugLogs = logs.filter { $0.level == .debug }.count
        let infoLogs = logs.filter { $0.level == .info }.count
        let warningLogs = logs.filter { $0.level == .warning }.count
        let errorLogs = logs.filter { $0.level == .error }.count
        let criticalLogs = logs.filter { $0.level == .critical }.count
        
        let categoryBreakdown = LogCategory.allCases.map { category in
            CategoryLogCount(
                category: category,
                count: logs.filter { $0.category == category }.count
            )
        }
        
        let sourceBreakdown = LogSource.allCases.map { source in
            SourceLogCount(
                source: source,
                count: logs.filter { $0.source == source }.count
            )
        }
        
        logStatistics = LogStatistics(
            totalLogs: totalLogs,
            debugLogs: debugLogs,
            infoLogs: infoLogs,
            warningLogs: warningLogs,
            errorLogs: errorLogs,
            criticalLogs: criticalLogs,
            categoryBreakdown: categoryBreakdown,
            sourceBreakdown: sourceBreakdown,
            averageLogsPerHour: calculateAverageLogsPerHour()
        )
    }
    
    private func calculateAverageLogsPerHour() -> Double {
        guard !logs.isEmpty else { return 0 }
        
        let sortedLogs = logs.sorted { $0.timestamp < $1.timestamp }
        let timeSpan = sortedLogs.last!.timestamp.timeIntervalSince(sortedLogs.first!.timestamp)
        let hours = timeSpan / 3600
        
        return hours > 0 ? Double(logs.count) / hours : 0
    }
    
    // MARK: - Settings Management
    
    func updateLoggingSettings(_ settings: LoggingSettings) {
        loggingSettings = settings
        isLoggingEnabled = settings.isEnabled
        logLevel = settings.logLevel
        saveLoggingSettings()
        
        // Reconfigure logging if needed
        if settings.enableFileLogging && logFileHandle == nil {
            setupLogFile()
        } else if !settings.enableFileLogging && logFileHandle != nil {
            logFileHandle?.closeFile()
            logFileHandle = nil
        }
    }
    
    func updateLogFilters(_ filters: LogFilters) {
        logFilters = filters
        saveLoggingSettings()
    }
    
    func enableLogging() {
        isLoggingEnabled = true
        loggingSettings.isEnabled = true
        saveLoggingSettings()
    }
    
    func disableLogging() {
        isLoggingEnabled = false
        loggingSettings.isEnabled = false
        saveLoggingSettings()
    }
    
    // MARK: - Analytics and Reporting
    
    func getLoggingReport() -> LoggingReport {
        return LoggingReport(
            isEnabled: isLoggingEnabled,
            logLevel: logLevel,
            logStatistics: logStatistics,
            activeLoggers: activeLoggers,
            loggingSettings: loggingSettings,
            generatedAt: Date()
        )
    }
    
    deinit {
        logFileHandle?.closeFile()
    }
}

// MARK: - Data Structures

struct LogEntry: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let level: LoggingService.LogLevel
    let category: LoggingService.LogCategory
    let source: LoggingService.LogSource
    let message: String
    let metadata: [String: Any]
    let thread: String
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, level, category, source, message, thread
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        level = try container.decode(LoggingService.LogLevel.self, forKey: .level)
        category = try container.decode(LoggingService.LogCategory.self, forKey: .category)
        source = try container.decode(LoggingService.LogSource.self, forKey: .source)
        message = try container.decode(String.self, forKey: .message)
        thread = try container.decode(String.self, forKey: .thread)
        
        // Decode metadata as JSON
        if let data = try? container.decode(Data.self, forKey: .metadata),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            metadata = dict
        } else {
            metadata = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(level, forKey: .level)
        try container.encode(category, forKey: .category)
        try container.encode(source, forKey: .source)
        try container.encode(message, forKey: .message)
        try container.encode(thread, forKey: .thread)
        
        // Encode metadata as JSON
        if let data = try? JSONSerialization.data(withJSONObject: metadata) {
            try container.encode(data, forKey: .metadata)
        }
    }
}

struct LoggerInfo: Identifiable, Codable {
    let id: String
    let name: String
    let category: LoggingService.LogCategory
    let level: LoggingService.LogLevel
    var isEnabled: Bool
}

struct LogFilters: Codable {
    var minimumLevel: LoggingService.LogLevel?
    var categories: Set<LoggingService.LogCategory> = []
    var sources: Set<LoggingService.LogSource> = []
    var startDate: Date?
    var endDate: Date?
    var searchTerm: String?
}

struct LoggingSettings: Codable {
    var isEnabled: Bool = true
    var logLevel: LoggingService.LogLevel = .info
    var enableFileLogging: Bool = true
    var enableRemoteLogging: Bool = false
    var enableLogRotation: Bool = true
    var maxLogFileSize: Int64 = 10 * 1024 * 1024 // 10MB
    var maxInMemoryLogs: Int = 1000
    var enableCompression: Bool = true
    var enableEncryption: Bool = false
    var retentionDays: Int = 30
    var enablePerformanceLogging: Bool = true
    var enableUserActionLogging: Bool = true
    var enableNetworkLogging: Bool = true
    var enableSecurityLogging: Bool = true
}

struct LogStatistics: Codable {
    var totalLogs: Int = 0
    var debugLogs: Int = 0
    var infoLogs: Int = 0
    var warningLogs: Int = 0
    var errorLogs: Int = 0
    var criticalLogs: Int = 0
    var categoryBreakdown: [CategoryLogCount] = []
    var sourceBreakdown: [SourceLogCount] = []
    var averageLogsPerHour: Double = 0
}

struct CategoryLogCount: Identifiable, Codable {
    let id = UUID()
    let category: LoggingService.LogCategory
    let count: Int
}

struct SourceLogCount: Identifiable, Codable {
    let id = UUID()
    let source: LoggingService.LogSource
    let count: Int
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"
    case txt = "TXT"
    case xml = "XML"
    
    var id: String { return rawValue }
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .txt: return "txt"
        case .xml: return "xml"
        }
    }
}

struct LoggingReport {
    let isEnabled: Bool
    let logLevel: LoggingService.LogLevel
    let logStatistics: LogStatistics
    let activeLoggers: [LoggerInfo]
    let loggingSettings: LoggingSettings
    let generatedAt: Date
}
