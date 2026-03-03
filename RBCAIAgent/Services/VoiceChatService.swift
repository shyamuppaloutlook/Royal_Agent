import Foundation
import SwiftUI
import Combine
import AVFoundation
import Speech

class VoiceChatService: NSObject, ObservableObject {
    @Published var isVoiceChatEnabled: Bool = false
    @Published var isListening: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var currentTranscript: String = ""
    @Published var conversationHistory: [VoiceChatMessage] = []
    @Published var voiceChatSettings: VoiceChatSettings = VoiceChatSettings()
    @Published var voiceChatState: VoiceChatState = .idle
    @Published var audioLevel: Float = 0.0
    @Published var sessionDuration: TimeInterval = 0.0
    @Published var sessionStartTime: Date?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var sessionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Voice Chat States
    
    enum VoiceChatState: String, CaseIterable {
        case idle = "Idle"
        case listening = "Listening"
        case processing = "Processing"
        case responding = "Responding"
        case error = "Error"
        case disabled = "Disabled"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .idle: return .gray
            case .listening: return .blue
            case .processing: return .orange
            case .responding: return .green
            case .error: return .red
            case .disabled: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "mic.circle"
            case .listening: return "mic.circle.fill"
            case .processing: return "brain"
            case .responding: return "speaker.wave.2.circle"
            case .error: return "mic.circle.slash"
            case .disabled: return "mic.slash"
            }
        }
        
        var description: String {
            switch self {
            case .idle: return "Voice chat is ready"
            case .listening: return "Listening to your voice"
            case .processing: return "Processing your request"
            case .responding: return "Generating response"
            case .error: return "Voice chat error occurred"
            case .disabled: return "Voice chat is disabled"
            }
        }
    }
    
    // MARK: - Voice Chat Modes
    
    enum VoiceChatMode: String, CaseIterable, Identifiable {
        case conversation = "Conversation"
        case command = "Command"
        case dictation = "Dictation"
        case translation = "Translation"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .conversation: return "bubble.left.and.bubble.right"
            case .command: return "terminal"
            case .dictation: return "textformat"
            case .translation: return "globe"
            }
        }
        
        var color: Color {
            switch self {
            case .conversation: return .blue
            case .command: return .green
            case .dictation: return .orange
            case .translation: return .purple
            }
        }
        
        var description: String {
            switch self {
            case .conversation: return "Natural conversation mode"
            case .command: return "Voice command mode"
            case .dictation: return "Dictation mode"
            case .translation: return "Translation mode"
            }
        }
    }
    
    // MARK: - Audio Visualization
    
    enum AudioVisualization: String, CaseIterable, Identifiable {
        case waveform = "Waveform"
        case bars = "Bars"
        case circle = "Circle"
        case minimal = "Minimal"
        
        var id: String { return rawValue }
        
        var icon: String {
            switch self {
            case .waveform: return "waveform"
            case .bars: return "chart.bar.fill"
            case .circle: return "circle.fill"
            case .minimal: return "circle"
            }
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupVoiceChatService()
        loadVoiceChatSettings()
        requestPermissions()
        setupAudioSession()
        setupAudioMonitoring()
    }
    
    private func setupVoiceChatService() {
        speechRecognizer.delegate = self
        speechSynthesizer.delegate = self
    }
    
    private func loadVoiceChatSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "voice_chat_settings"),
           let settings = try? JSONDecoder().decode(VoiceChatSettings.self, from: data) {
            voiceChatSettings = settings
            isVoiceChatEnabled = settings.isEnabled
        }
        
        if let data = defaults.data(forKey: "voice_chat_history"),
           let history = try? JSONDecoder().decode([VoiceChatMessage].self, from: data) {
            conversationHistory = history
        }
    }
    
    private func saveVoiceChatSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(voiceChatSettings) {
            defaults.set(data, forKey: "voice_chat_settings")
        }
        
        if let data = try? JSONEncoder().encode(conversationHistory) {
            defaults.set(data, forKey: "voice_chat_history")
        }
    }
    
    private func requestPermissions() {
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isVoiceChatEnabled = true
                case .denied, .restricted, .notDetermined:
                    self?.isVoiceChatEnabled = false
                @unknown default:
                    self?.isVoiceChatEnabled = false
                }
            }
        }
        
        // Request recording permission
        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.isVoiceChatEnabled = true
                } else {
                    self?.isVoiceChatEnabled = false
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAudioMonitoring() {
        // Monitor audio levels for visualization
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }
    
    private func updateAudioLevel() {
        guard isListening else {
            audioLevel = 0.0
            return
        }
        
        // Simulate audio level for visualization
        audioLevel = Float.random(in: 0.0...1.0)
    }
    
    // MARK: - Voice Chat Control
    
    func startVoiceChat() {
        guard isVoiceChatEnabled && !isListening else { return }
        
        voiceChatState = .listening
        sessionStartTime = Date()
        startSessionTimer()
        startListening()
        
        // Add welcome message
        let welcomeMessage = VoiceChatMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: "Voice chat started. I'm listening! How can I help you today?",
            timestamp: Date(),
            isVoice: false,
            audioLevel: 0.0
        )
        conversationHistory.append(welcomeMessage)
    }
    
    func stopVoiceChat() {
        stopListening()
        stopSpeaking()
        voiceChatState = .idle
        sessionStartTime = nil
        sessionDuration = 0.0
        stopSessionTimer()
        
        // Add goodbye message
        let goodbyeMessage = VoiceChatMessage(
            id: UUID().uuidString,
            role: .assistant,
            content: "Voice chat ended. Thank you for chatting!",
            timestamp: Date(),
            isVoice: false,
            audioLevel: 0.0
        )
        conversationHistory.append(goodbyeMessage)
        
        saveVoiceChatSettings()
    }
    
    func toggleVoiceChat() {
        if isListening {
            stopVoiceChat()
        } else {
            startVoiceChat()
        }
    }
    
    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if let startTime = self?.sessionStartTime {
                self?.sessionDuration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    // MARK: - Speech Recognition
    
    private func startListening() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            voiceChatState = .error
            return
        }
        
        // Cancel previous recognition task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = voiceChatSettings.enableOfflineRecognition
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.currentTranscript = result.bestTranscription.formattedString
                    self?.updateAudioLevel()
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopListening()
                    self?.processVoiceInput()
                }
            }
        }
        
        // Start audio engine
        do {
            try audioEngine.prepare()
            try audioEngine.start()
            
            isListening = true
            voiceChatState = .listening
            currentTranscript = ""
        } catch {
            print("Failed to start audio engine: \(error)")
            voiceChatState = .error
        }
    }
    
    private func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        audioLevel = 0.0
    }
    
    private func processVoiceInput() {
        guard !currentTranscript.isEmpty else { return }
        
        let userMessage = VoiceChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: currentTranscript,
            timestamp: Date(),
            isVoice: true,
            audioLevel: calculateAverageAudioLevel()
        )
        
        conversationHistory.append(userMessage)
        
        voiceChatState = .processing
        
        // Process the voice input
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let response = self?.generateVoiceResponse(for: self?.currentTranscript ?? "")
            
            DispatchQueue.main.async {
                self?.voiceChatState = .responding
                self?.sessionDuration = Date().timeIntervalSince(self?.sessionStartTime ?? Date())
                
                if let response = response {
                    let assistantMessage = VoiceChatMessage(
                        id: UUID().uuidString,
                        role: .assistant,
                        content: response,
                        timestamp: Date(),
                        isVoice: true,
                        audioLevel: 0.0
                    )
                    
                    self?.conversationHistory.append(assistantMessage)
                    
                    if self?.voiceChatSettings.enableVoiceOutput == true {
                        self?.speak(response)
                    }
                }
                
                self?.currentTranscript = ""
                
                // Continue listening if in conversation mode
                if self?.voiceChatSettings.mode == .conversation && self?.isVoiceChatEnabled == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.startListening()
                    }
                } else {
                    self?.voiceChatState = .idle
                }
            }
        }
    }
    
    private func generateVoiceResponse(for input: String) -> String {
        let lowercaseInput = input.lowercased()
        
        // Voice-specific responses
        if lowercaseInput.contains("hello") || lowercaseInput.contains("hi") {
            return "Hello! I'm your RBC voice assistant. How can I help you today?"
        } else if lowercaseInput.contains("balance") {
            return "Your current account balance is $12,345.67. Would you like me to help you with anything else?"
        } else if lowercaseInput.contains("transfer") {
            return "I can help you with transfers. Please tell me the amount and recipient, and I'll guide you through the process."
        } else if lowercaseInput.contains("invest") {
            return "Your investment portfolio is performing well with a 12.3% return this year. Would you like more details?"
        } else if lowercaseInput.contains("bill") {
            return "You have 3 upcoming bills totaling $1,234.56 due this week. Would you like me to help you with payment reminders?"
        } else if lowercaseInput.contains("help") {
            return "I'm here to help! You can ask me about banking, transactions, investments, bills, budget, security, or settings. What would you like to know?"
        } else if lowercaseInput.contains("stop") || lowercaseInput.contains("end") || lowercaseInput.contains("goodbye") {
            return "Goodbye! Thank you for using voice chat. Have a great day!"
        } else {
            return "I understand you're asking about: \(input). I can help you with that. Could you provide more details?"
        }
    }
    
    private func calculateAverageAudioLevel() -> Float {
        // Calculate average audio level for the message
        return Float.random(in: 0.3...0.8)
    }
    
    // MARK: - Text-to-Speech
    
    private func speak(_ text: String) {
        guard voiceChatSettings.enableVoiceOutput else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure voice
        if let voice = AVSpeechSynthesisVoice(identifier: voiceChatSettings.selectedVoiceId) {
            utterance.voice = voice
        }
        
        utterance.rate = voiceChatSettings.speechRate
        utterance.pitchMultiplier = voiceChatSettings.pitchMultiplier
        utterance.volume = voiceChatSettings.volume
        
        isSpeaking = true
        voiceChatState = .responding
        
        speechSynthesizer.speak(utterance)
    }
    
    private func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // MARK: - Voice Chat Settings
    
    func updateVoiceChatSettings(_ settings: VoiceChatSettings) {
        voiceChatSettings = settings
        isVoiceChatEnabled = settings.isEnabled
        saveVoiceChatSettings()
    }
    
    func enableVoiceChat() {
        isVoiceChatEnabled = true
        voiceChatSettings.isEnabled = true
        saveVoiceChatSettings()
    }
    
    func disableVoiceChat() {
        isVoiceChatEnabled = false
        voiceChatSettings.isEnabled = false
        stopVoiceChat()
        saveVoiceChatSettings()
    }
    
    // MARK: - Conversation Management
    
    func clearConversationHistory() {
        conversationHistory.removeAll()
        saveVoiceChatSettings()
    }
    
    func deleteMessage(_ messageId: String) {
        conversationHistory.removeAll { $0.id == messageId }
        saveVoiceChatSettings()
    }
    
    func exportConversation() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "voice-chat-\(Date().timeIntervalSince1970).txt"
        let exportURL = documentsPath.appendingPathComponent(fileName)
        
        let conversationText = conversationHistory.map { message in
            let timestamp = DateFormatter.localized.string(from: message.timestamp)
            let role = message.role == .user ? "You" : "Assistant"
            return "[\(timestamp)] \(role): \(message.content)"
        }.joined(separator: "\n\n")
        
        do {
            try conversationText.write(to: exportURL, atomically: true, encoding: .utf8)
            return exportURL
        } catch {
            print("Failed to export conversation: \(error)")
            return nil
        }
    }
    
    // MARK: - Analytics and Reporting
    
    func getVoiceChatReport() -> VoiceChatReport {
        let totalMessages = conversationHistory.count
        let userMessages = conversationHistory.filter { $0.role == .user }.count
        let assistantMessages = conversationHistory.filter { $0.role == .assistant }.count
        let voiceMessages = conversationHistory.filter { $0.isVoice }.count
        let averageSessionDuration = sessionDuration
        
        let modeBreakdown = VoiceChatMode.allCases.map { mode in
            ModeUsageStatistics(
                mode: mode,
                usageCount: conversationHistory.filter { _ in true }.count, // Simplified
                averageDuration: averageSessionDuration
            )
        }
        
        return VoiceChatReport(
            isEnabled: isVoiceChatEnabled,
            currentState: voiceChatState,
            totalMessages: totalMessages,
            userMessages: userMessages,
            assistantMessages: assistantMessages,
            voiceMessages: voiceMessages,
            averageSessionDuration: averageSessionDuration,
            modeBreakdown: modeBreakdown,
            settings: voiceChatSettings,
            generatedAt: Date()
        )
    }
    
    deinit {
        stopVoiceChat()
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceChatService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.isVoiceChatEnabled = false
                self.voiceChatState = .disabled
            }
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceChatService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        if voiceChatState == .responding {
            voiceChatState = .idle
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        voiceChatState = .idle
    }
}

// MARK: - Data Structures

struct VoiceChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date
    let isVoice: Bool
    let audioLevel: Float
    
    enum MessageRole: String, Codable {
        case user = "User"
        case assistant = "Assistant"
        
        var icon: String {
            switch self {
            case .user: return "person.crop.circle"
            case .assistant: return "brain"
            }
        }
        
        var color: Color {
            switch self {
            case .user: return .blue
            case .assistant: return .green
            }
        }
    }
}

struct VoiceChatSettings: Codable {
    var isEnabled: Bool = true
    var mode: VoiceChatService.VoiceChatMode = .conversation
    var enableVoiceOutput: Bool = true
    var enableOfflineRecognition: Bool = false
    var selectedVoiceId: String = ""
    var speechRate: Float = 0.5
    var pitchMultiplier: Float = 1.0
    var volume: Float = 1.0
    var enableAudioVisualization: Bool = true
    var visualizationType: VoiceChatService.AudioVisualization = .waveform
    var enableAutoRestart: Bool = true
    var silenceTimeout: TimeInterval = 3.0
    var maxConversationLength: Int = 100
    var enableConversationExport: Bool = true
    var enableProfanityFilter: Bool = true
    var enableBackgroundNoiseReduction: Bool = true
}

struct ModeUsageStatistics: Identifiable, Codable {
    let id = UUID()
    let mode: VoiceChatService.VoiceChatMode
    let usageCount: Int
    let averageDuration: TimeInterval
}

struct VoiceChatReport {
    let isEnabled: Bool
    let currentState: VoiceChatService.VoiceChatState
    let totalMessages: Int
    let userMessages: Int
    let assistantMessages: Int
    let voiceMessages: Int
    let averageSessionDuration: TimeInterval
    let modeBreakdown: [ModeUsageStatistics]
    let settings: VoiceChatSettings
    let generatedAt: Date
}
