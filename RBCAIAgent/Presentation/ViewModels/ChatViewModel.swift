import Foundation
import Combine

// MARK: - Presentation ViewModels
// Following SOLID: MVVM Pattern with Dependency Injection

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var currentContext: ChatContext?
    
    private let chatUseCase: ChatUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Dependency Inversion Principle
    init(chatUseCase: ChatUseCaseProtocol) {
        self.chatUseCase = chatUseCase
        loadMessages()
        setupBindings()
    }
    
    private func loadMessages() {
        messages = chatUseCase.getMessages()
    }
    
    private func setupBindings() {
        // Update messages when repository changes
        // This would be implemented with proper binding to the repository
    }
    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isTyping = true
        errorMessage = nil
        showError = false
        
        Task {
            let result = await chatUseCase.sendMessage(content)
            
            await MainActor.run {
                isTyping = false
                
                switch result {
                case .success(let message):
                    // Messages are automatically updated through the use case
                    loadMessages()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    func clearChat() {
        let result = chatUseCase.clearChat()
        
        switch result {
        case .success:
            messages = []
            errorMessage = nil
            showError = false
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func dismissError() {
        errorMessage = nil
        showError = false
    }
    
    func retryLastMessage() {
        // Implementation for retrying last failed message
    }
}

// MARK: - Voice Call ViewModel

@MainActor
class VoiceCallViewModel: ObservableObject {
    @Published var isCallActive = false
    @Published var isMuted = false
    @Published var isSpeakerOn = true
    @Published var callDuration: TimeInterval = 0
    @Published var transcription = ""
    @Published var agentResponse = ""
    @Published var isTranscribing = false
    @Published var isSpeaking = false
    @Published var callQuality: CallQuality = .excellent
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var callHistory: [VoiceCallRecord] = []
    @Published var audioLevel: Float = 0.0
    
    private let voiceCallUseCase: VoiceCallUseCaseProtocol
    private var callTimer: Timer?
    
    init(voiceCallUseCase: VoiceCallUseCaseProtocol) {
        self.voiceCallUseCase = voiceCallUseCase
        loadCallHistory()
    }
    
    private func loadCallHistory() {
        callHistory = voiceCallUseCase.getCallHistory()
    }
    
    func startCall() {
        isCallActive = true
        connectionStatus = .connecting
        callDuration = 0
        transcription = ""
        agentResponse = ""
        
        startCallTimer()
        
        Task {
            await voiceCallUseCase.startCall()
            await MainActor.run {
                self.connectionStatus = .connected
            }
        }
    }
    
    func endCall() {
        isCallActive = false
        connectionStatus = .disconnected
        isTranscribing = false
        isSpeaking = false
        
        stopCallTimer()
        
        Task {
            await voiceCallUseCase.endCall(transcription: transcription, response: agentResponse)
            await MainActor.run {
                self.loadCallHistory()
            }
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        Task {
            await voiceCallUseCase.setMuted(isMuted)
        }
    }
    
    func toggleSpeaker() {
        isSpeakerOn.toggle()
        Task {
            await voiceCallUseCase.setSpeakerEnabled(isSpeakerOn)
        }
    }
    
    private func startCallTimer() {
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.callDuration += 1
        }
    }
    
    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
    }
}

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var recentTransactions: [Transaction] = []
    @Published var spendingByCategory: [CategorySpending] = []
    @Published var totalBalance: Double = 0
    @Published var totalDebt: Double = 0
    @Published var netWorth: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let dashboardUseCase: DashboardUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(dashboardUseCase: DashboardUseCaseProtocol) {
        self.dashboardUseCase = dashboardUseCase
        loadDashboardData()
    }
    
    func refreshData() {
        loadDashboardData()
    }
    
    private func loadDashboardData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await dashboardUseCase.getDashboardData()
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let data):
                    self.accounts = data.accounts
                    self.recentTransactions = data.recentTransactions
                    self.spendingByCategory = data.spendingByCategory
                    self.totalBalance = data.totalBalance
                    self.totalDebt = data.totalDebt
                    self.netWorth = data.netWorth
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    func dismissError() {
        errorMessage = nil
        showError = false
    }
}

// MARK: - Settings ViewModel

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userPreferences: UserPreferences
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccessMessage = false
    
    private let settingsUseCase: SettingsUseCaseProtocol
    
    init(settingsUseCase: SettingsUseCaseProtocol) {
        self.settingsUseCase = settingsUseCase
        self.userPreferences = settingsUseCase.getUserPreferences()
    }
    
    func updatePreferences(_ preferences: UserPreferences) {
        isSaving = true
        errorMessage = nil
        
        Task {
            let result = await settingsUseCase.updateUserPreferences(preferences)
            
            await MainActor.run {
                isSaving = false
                
                switch result {
                case .success:
                    self.userPreferences = preferences
                    self.showSuccessMessage = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    func resetToDefaults() {
        let defaultPreferences = UserPreferences()
        updatePreferences(defaultPreferences)
    }
    
    func dismissError() {
        errorMessage = nil
        showError = false
    }
    
    func dismissSuccess() {
        showSuccessMessage = false
    }
}

// MARK: - Use Case Protocols

protocol VoiceCallUseCaseProtocol {
    func startCall() async
    func endCall(transcription: String, response: String) async
    func setMuted(_ muted: Bool) async
    func setSpeakerEnabled(_ enabled: Bool) async
    func getCallHistory() -> [VoiceCallRecord]
}

protocol DashboardUseCaseProtocol {
    func getDashboardData() async -> Result<DashboardData, ChatError>
}

protocol SettingsUseCaseProtocol {
    func getUserPreferences() -> UserPreferences
    func updateUserPreferences(_ preferences: UserPreferences) async -> Result<Void, ChatError>
}

// MARK: - Data Models

struct DashboardData {
    let accounts: [Account]
    let recentTransactions: [Transaction]
    let spendingByCategory: [CategorySpending]
    let totalBalance: Double
    let totalDebt: Double
    let netWorth: Double
}

enum CallQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var signalStrength: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        }
    }
}

enum ConnectionStatus: String, CaseIterable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case failed = "failed"
}

struct VoiceCallRecord: Identifiable, Codable {
    let id: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var transcription: String
    var agentResponse: String
    var callQuality: CallQuality
    var wasSuccessful: Bool
    
    init(
        id: String = UUID().uuidString,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        transcription: String = "",
        agentResponse: String = "",
        callQuality: CallQuality = .excellent,
        wasSuccessful: Bool = false
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.transcription = transcription
        self.agentResponse = agentResponse
        self.callQuality = callQuality
        self.wasSuccessful = wasSuccessful
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
