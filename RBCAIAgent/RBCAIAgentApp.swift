import SwiftUI
import AVFoundation
import Speech

// MARK: - App Entry Point
@main
struct RBCAIAgentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Chat View with Voice and AI Integration
struct SimpleChatView: View {
    // MARK: - State Properties
    @State private var messages: [SimpleChatMessage] = []
    @State private var messageText: String = ""
    @State private var isTyping: Bool = false
    @StateObject private var voiceService = SimpleVoiceService()
    @StateObject private var llmService = RealLLMService()
    @State private var showCallInterface: Bool = false
    @State private var pulseAnimation: Bool = false
    @State private var callDuration: TimeInterval = 0
    @State private var callTimer: Timer?
    @State private var currentTypingMessage: SimpleChatMessage?
    @State private var typingText: String = ""
    @State private var typingTimer: Timer?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Conditional Interface
                if showCallInterface {
                    callInterfaceView
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .animation(.easeInOut(duration: 0.4), value: showCallInterface)
                } else {
                    chatInterfaceView
                }
            }
            .navigationTitle("RBC Assistant")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
            .onAppear {
                voiceService.requestPermissions()
                pulseAnimation = true
            }
            .onChange(of: voiceService.transcript) { newValue in
                if !newValue.isEmpty {
                    messageText = newValue
                }
            }
            .onChange(of: voiceService.finalTranscript) { newValue in
                if !newValue.isEmpty {
                    messageText = newValue
                    sendMessage()
                    voiceService.clearTranscript()
                }
            }
        }
    }
    
    // MARK: - Call Interface
    private var callInterfaceView: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Main Call Circle
            mainCallCircle
            
            // Status Section
            statusSection
            
            // Controls Section
            controlsSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .top, endPoint: .bottom)
        )
    }
    
    // MARK: - Chat Interface
    private var chatInterfaceView: some View {
        VStack(spacing: 0) {
            // Messages Section
            messagesSection
            
            // Voice Status Bar
            voiceStatusBar
            
            // Input Section
            inputSection
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
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
        }
    }
    
    // MARK: - Main Call Circle
    private var mainCallCircle: some View {
        VStack(spacing: 30) {
            ZStack {
                // Glow Effect
                if voiceService.isListening {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 250, height: 250)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseAnimation)
                }
                
                // Main Circle
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
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text(voiceService.isListening ? "Listening..." : voiceService.isSpeaking ? "Speaking..." : "On Call")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                // Mute indicator
                if !voiceService.isListening && !voiceService.isSpeaking {
                    Image(systemName: "mic.slash.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Live Transcription
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
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 60) {
            // Mute/Unmute Button
            ControlButton(
                icon: voiceService.isListening ? "mic.fill" : "mic.slash.fill",
                action: {
                    if voiceService.isListening {
                        voiceService.stopListening()
                    } else {
                        voiceService.startListening()
                    }
                },
                color: voiceService.isListening ? .white.opacity(0.2) : .red.opacity(0.3),
                isLarge: false
            )
            
            // End Call Button
            ControlButton(
                icon: "phone.down.fill",
                action: endCall,
                color: .red,
                isLarge: true
            )
            
            // Keypad Button
            ControlButton(
                icon: "circle.grid.3x3.fill",
                action: {
                    // Future keypad functionality
                },
                color: .white.opacity(0.2),
                isLarge: false
            )
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Messages Section
    private var messagesSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages) { message in
                    MessageBubble(message: message)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                // Typing Animation
                if let typingMessage = currentTypingMessage {
                    MessageBubble(message: typingMessage, isTyping: true, typingText: typingText)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                // Loading Indicator
                if isTyping && currentTypingMessage == nil {
                    LoadingIndicator(text: llmService.isLoading ? "AI is thinking..." : "Connecting to AI...")
                }
                
                // Error Indicator
                if let error = llmService.error {
                    ErrorIndicator(error: error)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Voice Status Bar
    private var voiceStatusBar: some View {
        VStack(spacing: 0) {
            // Live transcript when speaking (chat mode)
            if voiceService.isListening && !voiceService.transcript.isEmpty {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.blue)
                    Text(voiceService.transcript)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.08))
            }
            
            HStack(spacing: 8) {
                Image(systemName: voiceService.isListening ? "mic.fill" : (voiceService.isSpeaking ? "speaker.wave.2.fill" : "mic"))
                    .foregroundColor(voiceService.isListening ? .red : (voiceService.isSpeaking ? .green : .blue))
                    .scaleEffect((voiceService.isListening || voiceService.isSpeaking) && pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Text(voiceStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isTyping {
                    Button("Reset") {
                        resetTypingState()
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
                
                if voiceService.isListening {
                    Button("Stop") {
                        voiceService.stopListening()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var voiceStatusText: String {
        if voiceService.isListening { return "Listening... Tap Stop when done" }
        if voiceService.isSpeaking { return "AI is speaking..." }
        if !voiceService.isAuthorized { return "Enable mic in Settings to talk" }
        return "Tap mic to talk, or 📞 for full voice call"
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
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
                
                // Talk button - tap to speak to the agent (speech-to-text, then AI responds)
                Button(action: {
                    if voiceService.isListening {
                        voiceService.stopListening()
                    } else {
                        voiceService.startListening()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(voiceService.isListening ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: voiceService.isListening ? "mic.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundColor(voiceService.isListening ? .red : .green)
                    }
                }
                .disabled(!voiceService.isAuthorized)
                .opacity(voiceService.isAuthorized ? 1 : 0.5)
                .scaleEffect(voiceService.isListening ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: voiceService.isListening)
                .accessibilityLabel("Talk to agent")
                .accessibilityHint("Tap to speak your question, tap again to stop")
                
                // Text Input (or tap mic to talk)
                TextField("Type or tap mic to talk...", text: $messageText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .disabled(isTyping || voiceService.isListening)
                
                // Send Button
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
    
    // MARK: - Call Functions
    private func startCall() {
        voiceService.shouldAutoRestartListening = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showCallInterface = true
            callDuration = 0
        }
        
        // Start listening after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            voiceService.startListening()
        }
        
        // Add welcome message
        let welcomeMessage = SimpleChatMessage(id: UUID().uuidString, content: "Hello! Thanks for calling RBC Assistant. How can I help you today?", isFromUser: false, timestamp: Date())
        messages.append(welcomeMessage)
        
        // Speak welcome only if voice is enabled
        if voiceService.isVoiceEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                voiceService.speak("Hello! Thanks for calling RBC Assistant. How can I help you today?")
            }
        }
    }
    
    private func endCall() {
        voiceService.shouldAutoRestartListening = false
        voiceService.stopListening()
        stopCallTimer()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showCallInterface = false
        }
        
        // Add call summary
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
    
    // MARK: - Message Functions
    private func sendCallMessage() {
        sendMessageWithVoice()
    }
    
    private func sendMessage() {
        sendMessageWithVoice()
    }
    
    // MARK: - Debug Helper
    private func resetTypingState() {
        isTyping = false
        voiceService.stopListening()
        typingTimer?.invalidate()
        typingTimer = nil
        currentTypingMessage = nil
        typingText = ""
    }
    
    private func sendMessageWithVoice() {
        print("📝 Send message called with: '\(messageText)'")
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("⚠️ Message is empty, not sending")
            return;
        }
        
        let userMessage = SimpleChatMessage(id: UUID().uuidString, content: messageText, isFromUser: true, timestamp: Date())
        messages.append(userMessage)
        print("✅ User message added")
        
        let input = messageText
        messageText = ""
        isTyping = true
        print("🔄 Typing state set to true")
        
        // Generate AI response
        Task {
            print("🤖 Starting AI response generation...")
            do {
                let response = try await llmService.generateResponse(for: input, conversationHistory: messages)
                print("✅ AI response received: \(response)")
                let aiMessage = SimpleChatMessage(id: UUID().uuidString, content: response, isFromUser: false, timestamp: Date())
                
                await MainActor.run {
                    startTypingAnimation(message: aiMessage)
                }
            } catch {
                print("❌ AI response failed: \(error)")
                await MainActor.run {
                    // Reset isTyping on error to enable TextField
                    isTyping = false
                    let errorMessage = SimpleChatMessage(id: UUID().uuidString, content: "I'm having trouble connecting right now. Please try again later.", isFromUser: false, timestamp: Date())
                    messages.append(errorMessage)
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
                
                // Complete message
                messages.append(message)
                currentTypingMessage = nil
                typingText = ""
                
                // Speak response only if voice is enabled
                if voiceService.isVoiceEnabled {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        voiceService.speak(fullText)
                    }
                }
            }
        }
    }
}

// MARK: - Dashboard View
struct SimpleDashboardView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title Section
                VStack(spacing: 16) {
                    Text("RBC Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Summary Cards
                VStack(spacing: 16) {
                    SummaryCard(title: "Total Balance", value: "$2,500.00", color: .blue)
                    SummaryCard(title: "Monthly Spending", value: "$1,234.56", color: .red)
                    SummaryCard(title: "Savings Goal", value: "75%", color: .green)
                }
                .padding()
                
                // Recent Transactions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
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

// MARK: - Message Bubble
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
                        // Typing cursor
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

// MARK: - Summary Card
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

// MARK: - Transaction Row
struct TransactionRow: View {
    let description: String
    let amount: String
    let category: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            categoryIcon
            
            // Transaction Details
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
    
    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(Color(amount.hasPrefix("-") ? .red : .green).opacity(0.1))
                .frame(width: 36, height: 36)
            
            Image(systemName: getCategoryIcon(category))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(amount.hasPrefix("-") ? .red : .green)
        }
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

// MARK: - Support Views
struct ControlButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    let isLarge: Bool
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: isLarge ? 70 : 60, height: isLarge ? 70 : 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
}

struct LoadingIndicator: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.blue)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

struct ErrorIndicator: View {
    let error: String
    
    var body: some View {
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

// MARK: - Data Models
struct SimpleChatMessage: Identifiable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - Voice Service
class SimpleVoiceService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isSpeaking = false
    @Published var transcript = ""
    @Published var finalTranscript = ""
    @Published var isAuthorized = false
    @Published var isVoiceEnabled = true
    /// When true, automatically start listening after AI finishes speaking (used in call mode)
    var shouldAutoRestartListening = false
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // MARK: - Initialization
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        speechSynthesizer.delegate = self
    }
    
    // MARK: - Public Methods
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

// MARK: - AI Service
class RealLLMService: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let apiKey = "AIzaSyAmlWf2ZfoB1yWtBd6Nqud2MeV0RLFXGcU" // Gemini API key - move to env in production
    private let modelName = "gemini-1.5-flash" // Fast, capable, good for voice
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    private static let systemPrompt = """
    You are the RBC Royal Agent - a friendly, knowledgeable AI assistant for Royal Bank of Canada customers.
    
    PERSONALITY:
    - Warm, professional, and helpful
    - Conversational and natural - you're speaking to users (keep responses concise for voice)
    - Patient and clear - avoid jargon when possible
    
    CAPABILITIES:
    - Answer ANY question: banking, finances, general knowledge, life advice, recipes, tech help, etc.
    - For RBC-specific topics: accounts, transfers, mortgages, investments, credit cards, banking hours, etc.
    - For general topics: explain concepts, give advice, have casual conversation
    - If asked about something outside your knowledge, say so honestly and suggest alternatives
    
    GUIDELINES:
    - Keep responses reasonably concise (2-4 sentences typical) - users may be listening via voice
    - For complex topics, offer to elaborate
    - Never share real account data - use "your account" language for demos
    - Be helpful and engaging on all topics, not just banking
    """
    
    // MARK: - Public Methods
    func generateResponse(for input: String, conversationHistory: [SimpleChatMessage] = []) async throws -> String {
        print("🔍 Generating response for: \(input)")
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let response = try await callGeminiAPI(input: input, history: conversationHistory)
            print("✅ Generated response: \(response.prefix(100))...")
            return response
        } catch {
            print("❌ API error, using fallback: \(error)")
            await MainActor.run { self.error = error.localizedDescription }
            return getFallbackResponse(for: input)
        }
    }
    
    // MARK: - Gemini API
    private func callGeminiAPI(input: String, history: [SimpleChatMessage]) async throws -> String {
        var contents: [[String: Any]] = []
        
        // Add conversation history (last 10 messages for context)
        let recentHistory = Array(history.suffix(10))
        for msg in recentHistory {
            let role = msg.isFromUser ? "user" : "model"
            contents.append([
                "role": role,
                "parts": [["text": msg.content]]
            ])
        }
        
        // Add current user message
        contents.append([
            "role": "user",
            "parts": [["text": input]]
        ])
        
        let requestBody: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": Self.systemPrompt]]
            ],
            "contents": contents,
            "generationConfig": [
                "temperature": 0.8,
                "topP": 0.95,
                "topK": 40,
                "maxOutputTokens": 512,
                "responseMimeType": "text/plain"
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)/\(modelName):generateContent?key=\(apiKey)") else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.unknownError(NSError(domain: "LLM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No data"
            print("❌ API error \(httpResponse.statusCode): \(responseString)")
            throw LLMError.serverError(httpResponse.statusCode)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let candidate = geminiResponse.candidates?.first,
              let text = candidate.content.parts.first?.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            if let blockReason = geminiResponse.candidates?.first?.finishReason {
                print("⚠️ Response blocked: \(blockReason)")
            }
            return getFallbackResponse(for: input)
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Fallback Responses (when API fails)
    private func getFallbackResponse(for input: String) -> String {
        let lowercaseInput = input.lowercased()
        
        if lowercaseInput.contains("balance") || lowercaseInput.contains("account") {
            return "Your current account balance is $2,500.00. This includes your checking and savings accounts combined."
        } else if lowercaseInput.contains("transfer") || lowercaseInput.contains("send") {
            return "I can help you transfer money. You can transfer funds between your RBC accounts or to other banks. Would you like to make a transfer?"
        } else if lowercaseInput.contains("bill") || lowercaseInput.contains("payment") {
            return "You have 3 upcoming bills: Hydro ($85), Internet ($60), and Credit Card ($450). Would you like to pay any of these?"
        } else if lowercaseInput.contains("invest") || lowercaseInput.contains("investment") {
            return "Your investment portfolio is currently valued at $15,000 with a 5.2% return this year. Would you like to see your investment options?"
        } else if lowercaseInput.contains("help") || lowercaseInput.contains("hello") || lowercaseInput.contains("hi") {
            return "Hello! I'm your RBC AI Assistant. I can help you with account balances, transfers, bill payments, investments, and general banking questions. How can I assist you today?"
        } else if lowercaseInput.contains("thank") {
            return "You're welcome! Is there anything else I can help you with today?"
        } else {
            return "I understand you're asking about: \(input). As an RBC AI Assistant, I'm here to help with your banking needs. Could you please provide more details about what you'd like to know?"
        }
    }
}

// MARK: - AI Response Models
struct GeminiResponse: Codable {
    let candidates: [Candidate]?
}

struct Candidate: Codable {
    let content: Content
    let finishReason: String?
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

// MARK: - Error Types
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

// MARK: - Delegates
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
        // Only auto-restart listening when in call mode (hands-free conversation)
        if shouldAutoRestartListening {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startListening()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
