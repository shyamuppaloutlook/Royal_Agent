import Foundation
import SwiftUI
import Combine
import UserNotifications

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isPermissionGranted: Bool = false
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    @Published var scheduledNotifications: [ScheduledNotification] = []
    @Published var notificationHistory: [NotificationHistory] = []
    @Published var notificationCategories: [NotificationCategory] = []
    @Published var isChatOnlyMode: Bool = true // Chat-only mode restriction
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Notification Types
    
    enum NotificationType: String, CaseIterable {
        case transactionAlert = "Transaction Alert"
        case accountUpdate = "Account Update"
        case budgetWarning = "Budget Warning"
        case investmentUpdate = "Investment Update"
        case securityAlert = "Security Alert"
        case systemUpdate = "System Update"
        case insightAvailable = "Insight Available"
        case recommendation = "Recommendation"
        case complianceReminder = "Compliance Reminder"
        case performanceAlert = "Performance Alert"
        case syncComplete = "Sync Complete"
        case errorReport = "Error Report"
        
        var icon: String {
            switch self {
            case .transactionAlert: return "creditcard"
            case .accountUpdate: return "banknote"
            case .budgetWarning: return "chart.bar"
            case .investmentUpdate: return "chart.line.uptrend.xyaxis"
            case .securityAlert: return "shield.leopard.up"
            case .systemUpdate: return "gear"
            case .insightAvailable: return "lightbulb"
            case .recommendation: return "star.circle"
            case .complianceReminder: return "doc.badge.gearshape"
            case .performanceAlert: return "speedometer"
            case .syncComplete: return "arrow.triangle.2.circlepath"
            case .errorReport: return "exclamationmark.triangle"
            }
        }
        
        var defaultSound: String {
            switch self {
            case .securityAlert, .errorReport: return UNNotificationSound.default.rawValue
            default: return UNNotificationSound.default.rawValue
            }
        }
        
        var priority: NotificationPriority {
            switch self {
            case .securityAlert, .errorReport: return .high
            case .transactionAlert, .budgetWarning, .investmentUpdate: return .medium
            default: return .low
            }
        }
    }
    
    // MARK: - Notification Priority
    
    enum NotificationPriority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var intensity: Int {
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
    }
    
    // MARK: - Delivery Methods
    
    enum DeliveryMethod: String, CaseIterable {
        case push = "Push Notification"
        case inApp = "In-App"
        case email = "Email"
        case sms = "SMS"
        case webhook = "Webhook"
        
        var requiresPermission: Bool {
            switch self {
            case .push, .sms: return true
            case .inApp, .email, .webhook: return false
            }
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupNotificationService()
        requestPermissions()
        setupNotificationCategories()
        loadNotificationSettings()
    }
    
    private func setupNotificationService() {
        notificationCenter.delegate = self
        
        // Load existing notifications
        loadNotifications()
        
        // Start monitoring
        startNotificationMonitoring()
    }
    
    private func requestPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isPermissionGranted = granted
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    private func setupNotificationCategories() {
        let categories = NotificationType.allCases.map { type in
            UNNotificationCategory(
                identifier: type.rawValue,
                actions: createActions(for: type),
                intentIdentifiers: [],
                options: []
            )
        }
        
        notificationCenter.setNotificationCategories(Set(categories))
        
        // Update local categories
        notificationCategories = NotificationType.allCases.map { type in
            NotificationCategory(
                type: type,
                enabled: notificationSettings.typeSettings[type]?.enabled ?? true,
                deliveryMethods: notificationSettings.typeSettings[type]?.deliveryMethods ?? [.inApp]
            )
        }
    }
    
    private func createActions(for type: NotificationType) -> [UNNotificationAction] {
        switch type {
        case .transactionAlert:
            return [
                UNNotificationAction(identifier: "VIEW_TRANSACTION", title: "View Transaction"),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss")
            ]
        case .budgetWarning:
            return [
                UNNotificationAction(identifier: "VIEW_BUDGET", title: "View Budget"),
                UNNotificationAction(identifier: "ADJUST_BUDGET", title: "Adjust Budget")
            ]
        case .securityAlert:
            return [
                UNNotificationAction(identifier: "VIEW_DETAILS", title: "View Details"),
                UNNotificationAction(identifier: "SECURE_ACCOUNT", title: "Secure Account")
            ]
        default:
            return [
                UNNotificationAction(identifier: "VIEW", title: "View"),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss")
            ]
        }
    }
    
    private func loadNotificationSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "notification_settings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            notificationSettings = settings
        }
    }
    
    private func saveNotificationSettings() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(notificationSettings) {
            defaults.set(data, forKey: "notification_settings")
        }
    }
    
    // MARK: - Main Notification Methods
    
    func sendNotification(
        type: NotificationType,
        title: String,
        body: String,
        data: [String: Any] = [:],
        scheduledFor: Date? = nil
    ) {
        // Chat-only mode: restrict notifications to chat-related only
        guard !isChatOnlyMode else { return }
        
        let typeSettings = notificationSettings.typeSettings[type] ?? NotificationTypeSettings()
        guard typeSettings.enabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound(named: UNNotificationSoundName(typeSettings.soundName))
        content.categoryIdentifier = type.rawValue
        content.userInfo = data
        content.interruptionLevel = mapPriorityToInterruptionLevel(type.priority)
        
        // Add badge count
        if notificationSettings.enableBadges {
            content.badge = NSNumber(value: unreadCount + 1)
        }
        
        let notification = AppNotification(
            id: UUID().uuidString,
            type: type,
            title: title,
            body: body,
            data: data,
            timestamp: Date(),
            isRead: false,
            priority: type.priority
        )
        
        if let scheduledDate = scheduledFor {
            scheduleNotification(content: content, notification: notification, for: scheduledDate)
        } else {
            deliverNotification(content: content, notification: notification)
        }
    }
    
    private func deliverNotification(content: UNNotificationContent, notification: AppNotification) {
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                print("Error delivering notification: \(error)")
            } else {
                DispatchQueue.main.async {
                    self?.addNotification(notification)
                }
            }
        }
    }
    
    private func scheduleNotification(content: UNNotificationContent, notification: AppNotification, for date: Date) {
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                DispatchQueue.main.async {
                    let scheduledNotification = ScheduledNotification(
                        id: notification.id,
                        notification: notification,
                        scheduledFor: date
                    )
                    self?.scheduledNotifications.append(scheduledNotification)
                }
            }
        }
    }
    
    private func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        unreadCount += 1
        
        // Add to history
        let history = NotificationHistory(
            id: UUID().uuidString,
            notificationId: notification.id,
            type: notification.type,
            deliveredAt: Date(),
            readAt: nil
        )
        notificationHistory.append(history)
        
        // Keep only recent notifications (last 100)
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
        }
        
        // Keep only recent history (last 500)
        if notificationHistory.count > 500 {
            notificationHistory = Array(notificationHistory.prefix(500))
        }
    }
    
    // MARK: - Specialized Notification Methods
    
    func sendTransactionAlert(amount: Double, merchant: String, category: String, account: String) {
        // Chat-only mode: disable transaction alerts
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .transactionAlert,
            title: "Transaction Alert",
            body: "You spent $\(String(format: "%.2f", amount)) at \(merchant) (\(category))",
            data: [
                "amount": amount,
                "merchant": merchant,
                "category": category,
                "account": account
            ]
        )
    }
    
    func sendBudgetWarning(category: String, spent: Double, budget: Double, percentage: Double) {
        // Chat-only mode: disable budget warnings
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .budgetWarning,
            title: "Budget Warning",
            body: "You've used \(String(format: "%.1f", percentage))% of your \(category) budget",
            data: [
                "category": category,
                "spent": spent,
                "budget": budget,
                "percentage": percentage
            ]
        )
    }
    
    func sendSecurityAlert(event: String, details: String) {
        // Chat-only mode: disable security alerts (except critical ones)
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .securityAlert,
            title: "Security Alert",
            body: "\(event): \(details)",
            data: [
                "event": event,
                "details": details
            ]
        )
    }
    
    func sendInvestmentUpdate(symbol: String, change: Double, value: Double) {
        // Chat-only mode: disable investment updates
        guard !isChatOnlyMode else { return }
        
        let changeSymbol = change >= 0 ? "+" : ""
        sendNotification(
            type: .investmentUpdate,
            title: "Investment Update",
            body: "\(symbol) is \(changeSymbol)\(String(format: "%.2f", change))% ($\(String(format: "%.2f", value)))",
            data: [
                "symbol": symbol,
                "change": change,
                "value": value
            ]
        )
    }
    
    func sendInsightAvailable(insight: String, category: String) {
        // Chat-only mode: disable insight notifications
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .insightAvailable,
            title: "New Insight Available",
            body: "Check out your latest insight about \(category)",
            data: [
                "insight": insight,
                "category": category
            ]
        )
    }
    
    func sendRecommendation(title: String, description: String, priority: NotificationPriority = .medium) {
        // Chat-only mode: disable recommendations
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .recommendation,
            title: title,
            body: description,
            data: [
                "title": title,
                "description": description
            ]
        )
    }
    
    func sendSystemUpdate(message: String) {
        // Chat-only mode: disable system updates
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .systemUpdate,
            title: "System Update",
            body: message,
            data: [
                "message": message
            ]
        )
    }
    
    func sendPerformanceAlert(metric: String, value: Double, threshold: Double) {
        // Chat-only mode: disable performance alerts
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .performanceAlert,
            title: "Performance Alert",
            body: "\(metric) is \(String(format: "%.2f", value)) (threshold: \(String(format: "%.2f", threshold)))",
            data: [
                "metric": metric,
                "value": value,
                "threshold": threshold
            ]
        )
    }
    
    func sendSyncComplete(accounts: Int, transactions: Int) {
        // Chat-only mode: disable sync notifications
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .syncComplete,
            title: "Sync Complete",
            body: "Synced \(accounts) accounts and \(transactions) transactions",
            data: [
                "accounts": accounts,
                "transactions": transactions
            ]
        )
    }
    
    func sendErrorReport(error: String, component: String) {
        // Chat-only mode: disable error reports
        guard !isChatOnlyMode else { return }
        
        sendNotification(
            type: .errorReport,
            title: "Error Report",
            body: "Error in \(component): \(error)",
            data: [
                "error": error,
                "component": component
            ]
        )
    }
    
    // MARK: - Notification Management
    
    func markAsRead(_ notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            unreadCount = max(0, unreadCount - 1)
            
            // Update history
            if let historyIndex = notificationHistory.firstIndex(where: { $0.notificationId == notificationId }) {
                notificationHistory[historyIndex].readAt = Date()
            }
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        unreadCount = 0
        
        // Update all history entries
        for index in notificationHistory.indices {
            if notificationHistory[index].readAt == nil {
                notificationHistory[index].readAt = Date()
            }
        }
    }
    
    func deleteNotification(_ notificationId: String) {
        notifications.removeAll { $0.id == notificationId }
        
        // Remove from scheduled notifications
        scheduledNotifications.removeAll { $0.id == notificationId }
        
        // Cancel system notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
        
        // Update unread count
        if let notification = notifications.first(where: { $0.id == notificationId }), !notification.isRead {
            unreadCount = max(0, unreadCount - 1)
        }
    }
    
    func clearAllNotifications() {
        notifications.removeAll()
        unreadCount = 0
        
        // Cancel all scheduled notifications
        notificationCenter.removeAllPendingNotificationRequests()
        scheduledNotifications.removeAll()
    }
    
    // MARK: - Settings Management
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        saveNotificationSettings()
        setupNotificationCategories()
    }
    
    func enableNotificationType(_ type: NotificationType, enabled: Bool) {
        notificationSettings.typeSettings[type, default: NotificationTypeSettings()].enabled = enabled
        saveNotificationSettings()
        setupNotificationCategories()
    }
    
    func setDeliveryMethods(for type: NotificationType, methods: [DeliveryMethod]) {
        notificationSettings.typeSettings[type, default: NotificationTypeSettings()].deliveryMethods = methods
        saveNotificationSettings()
    }
    
    func setSound(for type: NotificationType, soundName: String) {
        notificationSettings.typeSettings[type, default: NotificationTypeSettings()].soundName = soundName
        saveNotificationSettings()
    }
    
    // MARK: - Scheduled Notifications
    
    func getScheduledNotifications() -> [ScheduledNotification] {
        return scheduledNotifications.sorted { $0.scheduledFor < $1.scheduledFor }
    }
    
    func cancelScheduledNotification(_ notificationId: String) {
        scheduledNotifications.removeAll { $0.id == notificationId }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
    
    func rescheduleNotification(_ notificationId: String, newDate: Date) {
        if let scheduledNotification = scheduledNotifications.first(where: { $0.id == notificationId }) {
            cancelScheduledNotification(notificationId)
            
            let content = UNMutableNotificationContent()
            content.title = scheduledNotification.notification.title
            content.body = scheduledNotification.notification.body
            content.categoryIdentifier = scheduledNotification.notification.type.rawValue
            content.userInfo = scheduledNotification.notification.data
            
            scheduleNotification(content: content, notification: scheduledNotification.notification, for: newDate)
        }
    }
    
    // MARK: - Notification Monitoring
    
    private func startNotificationMonitoring() {
        // Monitor for notification interactions
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateBadgeCount()
            }
            .store(in: &cancellables)
    }
    
    private func updateBadgeCount() {
        if notificationSettings.enableBadges {
            UIApplication.shared.applicationIconBadgeNumber = unreadCount
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle notification when app is in foreground
        let options: UNNotificationPresentationOptions = notificationSettings.showInForeground ? [.alert, .sound, .badge] : []
        completionHandler(options)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleNotificationResponse(response)
        completionHandler()
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let notificationId = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier
        
        // Mark as read
        markAsRead(notificationId)
        
        // Handle action
        switch actionIdentifier {
        case "VIEW_TRANSACTION":
            // Navigate to transaction details
            NotificationCenter.default.post(name: .viewTransaction, object: response.notification.request.content.userInfo)
        case "VIEW_BUDGET":
            // Navigate to budget view
            NotificationCenter.default.post(name: .viewBudget, object: response.notification.request.content.userInfo)
        case "ADJUST_BUDGET":
            // Navigate to budget adjustment
            NotificationCenter.default.post(name: .adjustBudget, object: response.notification.request.content.userInfo)
        case "VIEW_DETAILS":
            // Navigate to security details
            NotificationCenter.default.post(name: .viewSecurityDetails, object: response.notification.request.content.userInfo)
        case "SECURE_ACCOUNT":
            // Navigate to security settings
            NotificationCenter.default.post(name: .secureAccount, object: nil)
        case "VIEW":
            // Navigate to relevant view
            NotificationCenter.default.post(name: .viewNotification, object: response.notification.request.content.userInfo)
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapPriorityToInterruptionLevel(_ priority: NotificationPriority) -> UNNotificationInterruptionLevel {
        switch priority {
        case .low: return .passive
        case .medium: return .active
        case .high: return .timeSensitive
        case .critical: return .critical
        }
    }
    
    private func loadNotifications() {
        // Load notifications from persistent storage
        // This would typically load from Core Data, SQLite, or file storage
    }
    
    // MARK: - Public Interface
    
    func getNotificationsByType(_ type: NotificationType) -> [AppNotification] {
        return notifications.filter { $0.type == type }
    }
    
    // MARK: - Chat-Only Mode Management
    
    func enableChatOnlyMode() {
        isChatOnlyMode = true
        // Clear existing notifications when switching to chat-only mode
        notifications.removeAll()
        unreadCount = 0
        scheduledNotifications.removeAll()
        notificationHistory.removeAll()
        
        // Cancel all pending notifications
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func disableChatOnlyMode() {
        isChatOnlyMode = false
    }
    
    func toggleChatOnlyMode() {
        isChatOnlyMode.toggle()
        if isChatOnlyMode {
            enableChatOnlyMode()
        } else {
            disableChatOnlyMode()
        }
    }
    
    func getUnreadNotifications() -> [AppNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    func getNotificationsInDateRange(from startDate: Date, to endDate: Date) -> [AppNotification] {
        return notifications.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    func searchNotifications(query: String) -> [AppNotification] {
        return notifications.filter { notification in
            notification.title.localizedCaseInsensitiveContains(query) ||
            notification.body.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getNotificationStatistics() -> NotificationStatistics {
        let notificationsByType = Dictionary(grouping: notifications) { $0.type }
        let notificationsByPriority = Dictionary(grouping: notifications) { $0.priority }
        
        let recentNotifications = notifications.filter { Date().timeIntervalSince($0.timestamp) <= 86400 } // Last 24 hours
        
        return NotificationStatistics(
            totalNotifications: notifications.count,
            unreadNotifications: unreadCount,
            notificationsByType: notificationsByType.mapValues { $0.count },
            notificationsByPriority: notificationsByPriority.mapValues { $0.count },
            recentNotifications: recentNotifications.count,
            averageNotificationsPerDay: calculateAverageNotificationsPerDay(),
            mostActiveType: notificationsByType.max { a, b in a.value.count < b.value.count }?.key
        )
    }
    
    private func calculateAverageNotificationsPerDay() -> Double {
        guard !notifications.isEmpty else { return 0.0 }
        
        let timeSpan = Date().timeIntervalSince(notifications.last!.timestamp)
        return Double(notifications.count) / (timeSpan / 86400.0)
    }
}

// MARK: - Data Structures

struct AppNotification: Identifiable {
    let id: String
    let type: NotificationService.NotificationType
    let title: String
    let body: String
    let data: [String: Any]
    let timestamp: Date
    var isRead: Bool
    let priority: NotificationService.NotificationPriority
}

struct NotificationSettings: Codable {
    var enableBadges: Bool = true
    var showInForeground: Bool = true
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    var quietHoursEnd: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var typeSettings: [NotificationService.NotificationType: NotificationTypeSettings] = [:]
}

struct NotificationTypeSettings: Codable {
    var enabled: Bool = true
    var deliveryMethods: [NotificationService.DeliveryMethod] = [.inApp, .push]
    var soundName: String = UNNotificationSound.default.rawValue
    var quietHoursExempt: Bool = false
}

struct ScheduledNotification: Identifiable {
    let id: String
    let notification: AppNotification
    let scheduledFor: Date
}

struct NotificationHistory: Identifiable {
    let id: String
    let notificationId: String
    let type: NotificationService.NotificationType
    let deliveredAt: Date
    var readAt: Date?
}

struct NotificationCategory {
    let type: NotificationService.NotificationType
    let enabled: Bool
    let deliveryMethods: [NotificationService.DeliveryMethod]
}

struct NotificationStatistics {
    let totalNotifications: Int
    let unreadNotifications: Int
    let notificationsByType: [NotificationService.NotificationType: Int]
    let notificationsByPriority: [NotificationService.NotificationPriority: Int]
    let recentNotifications: Int
    let averageNotificationsPerDay: Double
    let mostActiveType: NotificationService.NotificationType?
}

// MARK: - Notification Names

extension Notification.Name {
    static let viewTransaction = Notification.Name("viewTransaction")
    static let viewBudget = Notification.Name("viewBudget")
    static let adjustBudget = Notification.Name("adjustBudget")
    static let viewSecurityDetails = Notification.Name("viewSecurityDetails")
    static let secureAccount = Notification.Name("secureAccount")
    static let viewNotification = Notification.Name("viewNotification")
}
