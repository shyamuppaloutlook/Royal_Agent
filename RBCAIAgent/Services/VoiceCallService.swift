import Foundation
import SwiftUI
import Combine
import Speech
import AVFoundation
import CallKit

class VoiceCallService: NSObject, ObservableObject {
    @Published var isCallActive: Bool = false
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = true
    @Published var callDuration: TimeInterval = 0
    @Published var transcription: String = ""
    @Published var lastTranscription: String = ""
    @Published var agentResponse: String = ""
    @Published var isTranscribing: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var callQuality: CallQuality = .excellent
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var callHistory: [VoiceCallRecord] = []
    @Published var voiceCallSettings: VoiceCallSettings = VoiceCallSettings()
    @Published var audioLevel: Float = 0.0
    @Published var isRecording: Bool = false
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let synthesizer = AVSpeechSynthesizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var callTimer: Timer?
    private var audioSession: AVAudioSession!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Call States
    
    enum CallState: String, CaseIterable {
        case idle = "Idle"
        case connecting = "Connecting"
        case connected = "Connected"
        case speaking = "Speaking"
        case listening = "Listening"
        case processing = "Processing"
        case ended = "Ended"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .idle: return .gray
            case .connecting: return .orange
            case .connected: return .green
            case .speaking: return .blue
            case .listening: return .purple
            case .processing: return .yellow
            case .ended: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return "phone.down"
            case .connecting: return "phone.arrow.up.right"
            case .connected: return "phone.fill"
            case .speaking: return "mic.fill"
            case .listening: return "waveform"
            case .processing: return "gear.badge"
            case .ended: return "phone.down.fill"
            }
        }
    }
    
    enum CallQuality: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
        
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
        case disconnected = "Disconnected"
        case connecting = "Connecting"
        case connected = "Connected"
        case reconnecting = "Reconnecting"
        case failed = "Failed"
        
        var id: String { return rawValue }
        
        var color: Color {
            switch self {
            case .disconnected: return .red
            case .connecting: return .orange
            case .connected: return .green
            case .reconnecting: return .yellow
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .disconnected: return "wifi.slash"
            case .connecting: return "wifi"
            case .connected: return "wifi"
            case .reconnecting: return "arrow.clockwise.wifi"
            case .failed: return "xmark.wifi"
            }
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
        setupSpeechRecognizer()
        setupSynthesizer()
        setupAudioMonitoring()
        loadVoiceCallSettings()
        requestMicrophonePermission()
        requestSpeechPermission()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer?.delegate = self
    }
    
    private func setupSynthesizer() {
        synthesizer.delegate = self
    }
    
    private func setupAudioMonitoring() {
        // Monitor audio levels for visual feedback
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }
    
    private func loadVoiceCallSettings() {
        let defaults = UserDefaults.standard
        
        if let data = defaults.data(forKey: "voice_call_settings"),
           let settings = try? JSONDecoder().decode(VoiceCallSettings.self, from: data) {
            voiceCallSettings = settings
        }
        
        if let data = defaults.data(forKey: "call_history"),
           let history = try? JSONDecoder().decode([VoiceCallRecord].self, from: data) {
            callHistory = history
        }
    }
    
    private func saveVoiceCallSettings() {
        let defaults = UserDefaults.standard
        
        if let data = try? JSONEncoder().encode(voiceCallSettings) {
            defaults.set(data, forKey: "voice_call_settings")
        }
        
        if let data = try? JSONEncoder().encode(callHistory) {
            defaults.set(data, forKey: "call_history")
        }
    }
    
    // MARK: - Permission Management
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    print("Microphone permission denied")
                }
            }
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition denied")
                case .restricted:
                    print("Speech recognition restricted")
                case .notDetermined:
                    print("Speech recognition not determined")
                @unknown default:
                    print("Unknown speech recognition status")
                }
            }
        }
    }
    
    // MARK: - Call Management
    
    func startCall() {
        guard !isCallActive else { return }
        
        isCallActive = true
        connectionStatus = .connecting
        callDuration = 0
        transcription = ""
        lastTranscription = ""
        agentResponse = ""
        
        // Start call timer
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.callDuration += 1
        }
        
        // Simulate connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.connectionStatus = .connected
            self?.startListening()
        }
        
        // Create call record
        let callRecord = VoiceCallRecord(
            id: UUID().uuidString,
            startTime: Date(),
            endTime: nil,
            duration: 0,
            transcription: "",
            agentResponse: "",
            callQuality: .excellent,
            wasSuccessful: false
        )
        
        callHistory.append(callRecord)
    }
    
    func endCall() {
        guard isCallActive else { return }
        
        isCallActive = false
        connectionStatus = .disconnected
        isTranscribing = false
        isSpeaking = false
        isRecording = false
        
        // Stop recognition
        stopListening()
        
        // Stop speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Stop timer
        callTimer?.invalidate()
        callTimer = nil
        
        // Update call record
        if var lastCall = callHistory.last {
            lastCall.endTime = Date()
            lastCall.duration = callDuration
            lastCall.transcription = transcription
            lastCall.agentResponse = agentResponse
            lastCall.wasSuccessful = !transcription.isEmpty
            
            if let index = callHistory.firstIndex(where: { $0.id == lastCall.id }) {
                callHistory[index] = lastCall
            }
        }
        
        saveVoiceCallSettings()
    }
    
    func toggleMute() {
        isMuted.toggle()
        
        if isMuted {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func toggleSpeaker() {
        isSpeakerOn.toggle()
        
        do {
            try audioSession.overrideOutputAudioPort(isSpeakerOn ? .speaker : .none)
        } catch {
            print("Failed to toggle speaker: \(error)")
        }
    }
    
    // MARK: - Speech Recognition
    
    private func startListening() {
        guard !isTranscribing, speechRecognizer?.isAvailable == true else { return }
        
        isTranscribing = true
        isRecording = true
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.lastTranscription = transcribedText
                        self?.transcription += (self?.transcription.isEmpty == true ? "" : " ") + transcribedText
                        self?.processTranscription(transcribedText)
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopListening()
                    
                    // Restart listening if call is still active
                    if self?.isCallActive == true && !(self?.isMuted ?? false) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.startListening()
                        }
                    }
                }
            }
        }
        
        // Start audio engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
            stopListening()
        }
    }
    
    private func stopListening() {
        isTranscribing = false
        isRecording = false
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    private func processTranscription(_ text: String) {
        // Send transcribed text to chat backend
        sendToChatBackend(text)
    }
    
    private func sendToChatBackend(_ message: String) {
        // Simulate sending to chat backend
        print("Sending to chat backend: \(message)")
        
        // Simulate agent response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            let response = self?.generateAgentResponse(for: message) ?? "I understand. How can I help you further?"
            self?.agentResponse = response
            self?.speakResponse(response)
        }
    }
    
    private func generateAgentResponse(for message: String) -> String {
        // Simple response generation - in real implementation, this would call the AI agent
        let lowercaseMessage = message.lowercased()
        
        if lowercaseMessage.contains("hello") || lowercaseMessage.contains("hi") {
            return "Hello! How can I assist you today?"
        } else if lowercaseMessage.contains("balance") {
            return "I can help you check your account balance. Which account would you like to check?"
        } else if lowercaseMessage.contains("transfer") {
            return "I can help you with money transfers. Please tell me the amount and recipient."
        } else if lowercaseMessage.contains("help") {
            return "I'm here to help! You can ask me about your accounts, transactions, transfers, or any other banking questions."
        } else if lowercaseMessage.contains("thank") {
            return "You're welcome! Is there anything else I can help you with?"
        } else if lowercaseMessage.contains("bye") || lowercaseMessage.contains("goodbye") {
            return "Goodbye! Have a great day!"
        } else {
            return "I understand you're saying: \(message). How can I assist you with that?"
        }
    }
    
    // MARK: - Text-to-Speech
    
    private func speakResponse(_ text: String) {
        guard voiceCallSettings.enableVoiceResponse else { return }
        
        isSpeaking = true
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = voiceCallSettings.speechRate
        utterance.pitchMultiplier = voiceCallSettings.pitchMultiplier
        utterance.volume = voiceCallSettings.volume
        
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    // MARK: - Audio Monitoring
    
    private func updateAudioLevel() {
        guard isCallActive && !isMuted else {
            audioLevel = 0.0
            return
        }
        
        // Simple audio level simulation
        if isTranscribing {
            audioLevel = Float.random(in: 0.3...0.8)
        } else {
            audioLevel = 0.0
        }
    }
    
    // MARK: - Call Quality Monitoring
    
    private func updateCallQuality() {
        // Simulate call quality assessment
        let qualityFactors = [
            audioEngine.isRunning,
            speechRecognizer?.isAvailable == true,
            connectionStatus == .connected,
            callDuration < 300 // Less than 5 minutes for better quality
        ]
        
        let score = qualityFactors.filter { $0 }.count
        
        switch score {
        case 4:
            callQuality = .excellent
        case 3:
            callQuality = .good
        case 2:
            callQuality = .fair
        default:
            callQuality = .poor
        }
    }
    
    // MARK: - Settings Management
    
    func updateVoiceCallSettings(_ settings: VoiceCallSettings) {
        voiceCallSettings = settings
        saveVoiceCallSettings()
    }
    
    func enableVoiceResponse() {
        voiceCallSettings.enableVoiceResponse = true
        saveVoiceCallSettings()
    }
    
    func disableVoiceResponse() {
        voiceCallSettings.enableVoiceResponse = false
        stopSpeaking()
        saveVoiceCallSettings()
    }
    
    func clearCallHistory() {
        callHistory.removeAll()
        saveVoiceCallSettings()
    }
    
    // MARK: - Call History
    
    func getCallHistory() -> [VoiceCallRecord] {
        return callHistory.sorted { $0.startTime > $1.startTime }
    }
    
    func getCallStatistics() -> CallStatistics {
        let totalCalls = callHistory.count
        let successfulCalls = callHistory.filter { $0.wasSuccessful }.count
        let totalDuration = callHistory.map { $0.duration }.reduce(0, +)
        let averageDuration = totalCalls > 0 ? totalDuration / Double(totalCalls) : 0
        
        return CallStatistics(
            totalCalls: totalCalls,
            successfulCalls: successfulCalls,
            averageCallDuration: averageDuration,
            totalCallDuration: totalDuration,
            successRate: totalCalls > 0 ? Double(successfulCalls) / Double(totalCalls) * 100 : 0
        )
    }
    
    deinit {
        endCall()
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceCallService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available && self.isTranscribing {
                self.stopListening()
            }
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceCallService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

// MARK: - Data Structures

struct VoiceCallRecord: Identifiable, Codable {
    let id: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var transcription: String
    var agentResponse: String
    var callQuality: VoiceCallService.CallQuality
    var wasSuccessful: Bool
    
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
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}

struct VoiceCallSettings: Codable {
    var enableVoiceResponse: Bool = true
    var enableAutoTranscription: Bool = true
    var speechRate: Float = 0.5
    var pitchMultiplier: Float = 1.0
    var volume: Float = 1.0
    var enableNoiseReduction: Bool = true
    var enableEchoCancellation: Bool = true
    var enableAutomaticGainControl: Bool = true
    var maxCallDuration: TimeInterval = 1800 // 30 minutes
    var enableCallRecording: Bool = true
    var enableTranscriptionSave: Bool = true
    var language: String = "en-US"
    var accent: String = "US"
}

struct CallStatistics: Codable {
    let totalCalls: Int
    let successfulCalls: Int
    let averageCallDuration: TimeInterval
    let totalCallDuration: TimeInterval
    let successRate: Double
    
    var formattedAverageDuration: String {
        let minutes = Int(averageCallDuration) / 60
        let seconds = Int(averageCallDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalCallDuration) / 3600
        let minutes = Int(totalCallDuration) % 3600 / 60
        let seconds = Int(totalCallDuration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
