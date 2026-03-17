import SwiftUI

@main
struct RBCAIAgentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            SimpleChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
            
            SimpleDashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
        }
    }
}

struct SimpleChatView: View {
    @State private var messages: [SimpleChatMessage] = []
    @State private var messageText = ""
    @State private var isTyping = false
    @StateObject private var voiceService = SimpleVoiceService()
    @StateObject private var llmService = RealLLMService()
    @State private var showCallInterface = false
    @State private var pulseAnimation = false
    @State private var callDuration: TimeInterval = 0
    @State private var callTimer: Timer?
    @State private var currentTypingMessage: SimpleChatMessage?
    @State private var typingText: String = ""
    @State private var typingTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Call Interface (when active)
                if showCallInterface {
                    callInterfaceView
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .animation(.easeInOut(duration: 0.4), value: showCallInterface)
                } else {
                    // Regular Chat Interface
                    chatInterfaceView
                }
            }
            .navigationTitle("RBC Assistant")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
            .onAppear {
                voiceService.requestPermissions()
            }
            .onChange(of: voiceService.transcript) { newValue in
                if !newValue.isEmpty && showCallInterface {
                    messageText = newValue
                }
            }
            .onChange(of: voiceService.finalTranscript) { newValue in
                if !newValue.isEmpty && showCallInterface {
                    messageText = newValue
                    sendCallMessage()
                    voiceService.clearTranscript()
                }
            }
        }
    }
    
    // MARK: - Call Interface View
    private var callInterfaceView: some View {
        VStack(spacing: 0) {
            // Call Header
            VStack(spacing: 20) {
                HStack {
                    Button(action: endCall) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        Text("RBC Assistant")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(formatCallDuration(callDuration))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    // Speaker button
                    Button(action: {
                        voiceService.isVoiceEnabled.toggle()
                    }) {
                        Image(systemName: voiceService.isVoiceEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                // Main Call Circle
                VStack(spacing: 30) {
                    ZStack {
                        // Outer glow effect
                        if voiceService.isListening {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 250, height: 250)
                                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseAnimation)
                        }
                        
                        // Main circle with RBC branding
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                            .frame(width: 180, height: 180)
                            .shadow(color: .blue.opacity(0.4), radius: 30, x: 0, y: 15)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "building.columns.fill")
                                        .font(.system(size: 60, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("RBC")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            )
                    }
                    .onAppear {
                        startCallTimer()
                        pulseAnimation = true
                    }
                    .onDisappear {
                        stopCallTimer()
                    }
                    
                    // Status text
                    VStack(spacing: 12) {
                        Text(voiceService.isListening ? "Listening..." : voiceService.isSpeaking ? "Speaking..." : "On Call")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        // Live transcription
                        if !voiceService.transcript.isEmpty {
                            Text(voiceService.transcript)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(20)
                                .lineLimit(3)
                                .multilineTextAlignment(.center)
                                .animation(.easeInOut(duration: 0.3), value: voiceService.transcript)
                        }
                    }
                }
                .padding(.vertical, 40)
                
                // Call Controls
                HStack(spacing: 60) {
                    // Mute button
                    Button(action: {
                        if voiceService.isListening {
                            voiceService.stopListening()
                        } else {
                            voiceService.startListening()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: voiceService.isListening ? "mic.fill" : "mic.slash.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // End Call button
                    Button(action: endCall) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 70, height: 70)
                            Image(systemName: "phone.down.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Keypad button (optional)
                    Button(action: {
                        // Could add keypad functionality
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            Image(systemName: "circle.grid.3x3.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .top, endPoint: .bottom)
            )
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Chat Interface View
    private var chatInterfaceView: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    
                    // Typing Animation Message
                    if let typingMessage = currentTypingMessage {
                        MessageBubble(message: typingMessage, isTyping: true, typingText: typingText)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    
                    // Typing Indicator (when thinking or loading from LLM)
                    if isTyping && currentTypingMessage == nil {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.blue)
                            Text(llmService.isLoading ? "AI is thinking..." : "Connecting to AI...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    
                    // Error indicator
                    if let error = llmService.error {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamation.triangle")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .padding()
            }
            
            // Voice Status Bar (compact)
            if voiceService.isListening || voiceService.isSpeaking {
                HStack(spacing: 8) {
                    Image(systemName: voiceService.isListening ? "mic.fill" : "speaker.wave.2.fill")
                        .foregroundColor(voiceService.isListening ? .red : .green)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Text(voiceService.isListening ? "Listening..." : "Speaking...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Stop") {
                        voiceService.stopListening()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Input Area
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    // Call Button
                    Button(action: startCall) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "phone.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    .disabled(voiceService.isListening || voiceService.isSpeaking)
                    .scaleEffect(voiceService.isListening || voiceService.isSpeaking ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: voiceService.isListening)
                    
                    // Voice Toggle Button
                    Button(action: {
                        voiceService.isVoiceEnabled.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(voiceService.isVoiceEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: voiceService.isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.title2)
                                .foregroundColor(voiceService.isVoiceEnabled ? .blue : .gray)
                        }
                    }
                    
                    // Text input
                    TextField("Ask about your finances...", text: $messageText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .disabled(isTyping || voiceService.isListening)
                    
                    // Send button
                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(messageText.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                .frame(width: 44, height: 44)
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(messageText.isEmpty || isTyping || voiceService.isListening)
                    .scaleEffect(messageText.isEmpty || isTyping || voiceService.isListening ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Voice Status Indicator
                if voiceService.isVoiceEnabled {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Voice responses enabled")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Call Functions
    private func startCall() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showCallInterface = true
            callDuration = 0
        }
        
        // Start listening immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            voiceService.startListening()
        }
        
        // Add welcome message
        let welcomeMessage = SimpleChatMessage(id: UUID().uuidString, content: "Hello! Thanks for calling RBC Assistant. How can I help you today?", isFromUser: false, timestamp: Date())
        messages.append(welcomeMessage)
        
        // Speak the welcome
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            voiceService.speak("Hello! Thanks for calling RBC Assistant. How can I help you today?")
        }
    }
    
    private func endCall() {
        voiceService.stopListening()
        stopCallTimer()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showCallInterface = false
        }
        
        // Add call ended message
        let endTime = Date()
        let callSummary = SimpleChatMessage(id: UUID().uuidString, content: "Call ended. Duration: \(formatCallDuration(callDuration))", isFromUser: false, timestamp: endTime)
        messages.append(callSummary)
    }
    
    private func startCallTimer() {
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            callDuration += 1
        }
    }
    
    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
    }
    
    private func formatCallDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func sendCallMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = SimpleChatMessage(id: UUID().uuidString, content: messageText, isFromUser: true, timestamp: Date())
        messages.append(userMessage)
        
        let input = messageText
        messageText = ""
        isTyping = true
        
        // Generate response using real LLM
        Task {
            do {
                let response = try await llmService.generateResponse(for: input)
                let aiMessage = SimpleChatMessage(id: UUID().uuidString, content: response, isFromUser: false, timestamp: Date())
                
                await MainActor.run {
                    startTypingAnimation(message: aiMessage)
                }
            } catch {
                await MainActor.run {
                    let errorMessage = SimpleChatMessage(id: UUID().uuidString, content: "I'm having trouble connecting right now. Please try again later.", isFromUser: false, timestamp: Date())
                    startTypingAnimation(message: errorMessage)
                }
            }
        }
    }
    
    // MARK: - Regular Message Logic
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = SimpleChatMessage(id: UUID().uuidString, content: messageText, isFromUser: true, timestamp: Date())
        messages.append(userMessage)
        
        let input = messageText
        messageText = ""
        isTyping = true
        
        // Generate response using real LLM
        Task {
            do {
                let response = try await llmService.generateResponse(for: input)
                let aiMessage = SimpleChatMessage(id: UUID().uuidString, content: response, isFromUser: false, timestamp: Date())
                
                await MainActor.run {
                    startTypingAnimation(message: aiMessage)
                }
            } catch {
                await MainActor.run {
                    let errorMessage = SimpleChatMessage(id: UUID().uuidString, content: "I'm having trouble connecting right now. Please try again later.", isFromUser: false, timestamp: Date())
                    startTypingAnimation(message: errorMessage)
                }
            }
        }
    }
    
    // MARK: - Typing Animation
    private func startTypingAnimation(message: SimpleChatMessage) {
        currentTypingMessage = message
        typingText = ""
        isTyping = false
        
        let fullText = message.content
        var currentIndex = 0
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if currentIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                typingText += String(fullText[index])
                currentIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
                
                // Add completed message to messages
                messages.append(message)
                currentTypingMessage = nil
                typingText = ""
                
                // Speak the response
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    voiceService.speak(fullText)
                }
            }
        }
    }
}

struct SimpleDashboardView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("RBC Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    SummaryCard(title: "Total Balance", value: "$2,500.00", color: .blue)
                    SummaryCard(title: "Monthly Spending", value: "$1,234.56", color: .red)
                    SummaryCard(title: "Savings Goal", value: "75%", color: .green)
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TransactionRow(description: "Coffee Shop", amount: "-$4.50", category: "Food")
                    TransactionRow(description: "Salary Deposit", amount: "+$2,000.00", category: "Income")
                    TransactionRow(description: "Grocery Store", amount: "-$87.32", category: "Groceries")
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct MessageBubble: View {
    let message: SimpleChatMessage
    let isTyping: Bool
    let typingText: String
    
    init(message: SimpleChatMessage, isTyping: Bool = false, typingText: String = "") {
        self.message = message
        self.isTyping = isTyping
        self.typingText = typingText
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if message.isFromUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(isTyping ? typingText : message.content)
                    .font(.body)
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isFromUser ? 
                                  LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                  LinearGradient(colors: [Color(.systemGray6), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .shadow(color: message.isFromUser ? .blue.opacity(0.2) : .gray.opacity(0.1), radius: 5, x: 0, y: 2)
                    .overlay(
                        // Typing cursor effect
                        isTyping ? 
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 2, height: 20)
                            .opacity(0.8)
                            .offset(x: 8)
                        : nil,
                        alignment: .trailing
                    )
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: message.isFromUser ? .trailing : .leading)))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TransactionRow: View {
    let description: String
    let amount: String
    let category: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color(amount.hasPrefix("-") ? .red : .green).opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: getCategoryIcon(category))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(amount.hasPrefix("-") ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(description)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(amount)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(amount.hasPrefix("-") ? .red : .green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "food", "dining": return "fork.knife"
        case "transportation": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "tv.fill"
        case "bills": return "doc.text.fill"
        case "groceries": return "cart.fill"
        case "deposit", "income": return "arrow.down.circle.fill"
        default: return "circle.fill"
        }
    }
}

struct SimpleChatMessage: Identifiable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

import AVFoundation
import Speech

class SimpleVoiceService: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var transcript = ""
    @Published var finalTranscript = ""
    @Published var isAuthorized = false
    @Published var isVoiceEnabled = true
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        speechSynthesizer.delegate = self
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isAuthorized = status == .authorized
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.isAuthorized = false
                }
            }
        }
    }
    
    func startListening() {
        guard isAuthorized, !isListening else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            print("Audio engine error: \(error)")
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.finalTranscript = result.bestTranscription.formattedString
                    }
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopListening()
                }
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isListening = false
        transcript = ""
    }
    
    func speak(_ text: String) {
        guard !isSpeaking else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func clearTranscript() {
        transcript = ""
        finalTranscript = ""
    }
}

// MARK: - Real LLM Service
class RealLLMService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    private let apiKey = "YOUR_API_KEY_HERE" // User should replace this
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func generateResponse(for input: String) async throws -> String {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        // Create a prompt with RBC banking context
        let systemPrompt = """
        You are a helpful RBC (Royal Bank of Canada) AI assistant. You provide professional, accurate, and helpful information about banking, finances, and RBC services. Always be polite, professional, and helpful. If you don't know specific account details, explain that you'd need to access their actual account information. Provide general guidance and suggest they contact RBC directly for specific account queries.
        """
        
        let messages = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": input]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 150,
            "temperature": 0.7
        ]
        
        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw LLMError.encodingError
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            return response.choices.first?.message.content ?? "I'm sorry, I couldn't generate a response."
        } catch {
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                throw LLMError.noInternet
            } else if let httpResponse = error as? HTTPURLResponse {
                throw LLMError.serverError(httpResponse.statusCode)
            } else {
                throw LLMError.unknownError(error)
            }
        }
    }
}

// MARK: - OpenAI Response Models
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let role: String
    let content: String
}

// MARK: - LLM Errors
enum LLMError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case noInternet
    case serverError(Int)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request"
        case .noInternet:
            return "No internet connection. Please check your network and try again."
        case .serverError(let code):
            return "Server error with code \(code). Please try again later."
        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

extension SimpleVoiceService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            self.isAuthorized = available && self.isAuthorized
        }
    }
}

extension SimpleVoiceService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}

#Preview {
    ContentView()
}
