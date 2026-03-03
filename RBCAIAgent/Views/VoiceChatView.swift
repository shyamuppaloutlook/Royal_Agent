import SwiftUI
import AVFoundation

struct VoiceChatView: View {
    @StateObject private var voiceChatService = VoiceChatService()
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingExport = false
    @State private var isRecording = false
    @State private var animationPhase: Double = 0.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Audio visualization
                    if voiceChatService.isListening || voiceChatService.isSpeaking {
                        audioVisualizationView
                            .frame(height: 120)
                            .padding(.horizontal)
                    }
                    
                    // Conversation area
                    conversationView
                    
                    // Voice controls
                    voiceControlsView
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
                
                // Floating controls
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        // Settings button
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Voice Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
        }
        .onAppear {
            voiceChatService.startVoiceChat()
        }
        .onDisappear {
            voiceChatService.stopVoiceChat()
        }
        .sheet(isPresented: $showingSettings) {
            VoiceChatSettingsView(voiceChatService: voiceChatService)
        }
        .sheet(isPresented: $showingHistory) {
            VoiceChatHistoryView(voiceChatService: voiceChatService)
        }
        .sheet(isPresented: $showingExport) {
            VoiceChatExportView(voiceChatService: voiceChatService)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                // Status indicator
                Circle()
                    .fill(voiceChatService.voiceChatState.color)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(voiceChatService.voiceChatState.color.opacity(0.3), lineWidth: 4)
                            .scaleEffect(animationPhase)
                            .opacity(animationPhase > 0 ? 0 : 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(voiceChatService.voiceChatState.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(voiceChatService.voiceChatState.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Session duration
                if voiceChatService.sessionDuration > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(voiceChatService.sessionDuration))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Mode indicator
            HStack {
                Image(systemName: voiceChatService.voiceChatSettings.mode.icon)
                    .font(.caption)
                    .foregroundColor(voiceChatService.voiceChatSettings.mode.color)
                
                Text(voiceChatService.voiceChatSettings.mode.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Audio Visualization View
    
    private var audioVisualizationView: some View {
        VStack(spacing: 8) {
            // Audio level bars
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(voiceChatService.voiceChatState.color)
                        .frame(width: 4, height: max(4, voiceChatService.audioLevel * 60))
                        .animation(.easeInOut(duration: 0.1), value: voiceChatService.audioLevel)
                }
            }
            
            // Status text
            Text(voiceChatService.currentTranscript.isEmpty ? "Listening..." : voiceChatService.currentTranscript)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Conversation View
    
    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(voiceChatService.conversationHistory) { message in
                        VoiceChatMessageView(message: message)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .onChange(of: voiceChatService.conversationHistory) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(voiceChatService.conversationHistory.count - 1, anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Voice Controls View
    
    private var voiceControlsView: some View {
        HStack(spacing: 20) {
            // Microphone button
            Button(action: {
                if voiceChatService.isListening {
                    voiceChatService.stopListening()
                } else {
                    voiceChatService.startListening()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(voiceChatService.isListening ? Color.red : Color.blue)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .scaleEffect(animationPhase)
                                .opacity(animationPhase > 0 ? 0 : 1)
                        )
                    
                    Image(systemName: voiceChatService.isListening ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(voiceChatService.isListening ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: voiceChatService.isListening)
            
            // Voice output toggle
            Button(action: {
                voiceChatService.voiceChatSettings.enableVoiceOutput.toggle()
            }) {
                Image(systemName: voiceChatService.voiceChatSettings.enableVoiceOutput ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.title2)
                    .foregroundColor(voiceChatService.voiceChatSettings.enableVoiceOutput ? .blue : .gray)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            
            // Clear conversation
            Button(action: {
                voiceChatService.clearConversationHistory()
            }) {
                Image(systemName: "trash.circle")
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            
            // Export conversation
            Button(action: {
                showingExport = true
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Voice Chat Message View

struct VoiceChatMessageView: View {
    let message: VoiceChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: message.role.icon)
                        .font(.caption)
                        .foregroundColor(message.role.color)
                    
                    Text(message.role == .user ? "You" : "Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.role == .user ? Color.blue : Color(.systemGray6))
                    )
                
                if message.isVoice {
                    HStack(spacing: 2) {
                        ForEach(0..<Int(message.audioLevel * 10), id: \.self) { _ in
                            Circle()
                                .fill(message.role.color)
                                .frame(width: 3, height: 3)
                        }
                    }
                }
                
                Text(DateFormatter.localized.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .id(message.id)
    }
}

// MARK: - Voice Chat Settings View

struct VoiceChatSettingsView: View {
    @ObservedObject var voiceChatService: VoiceChatService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("General Settings") {
                    Toggle("Enable Voice Chat", isOn: $voiceChatService.isVoiceChatEnabled)
                    
                    Picker("Mode", selection: $voiceChatService.voiceChatSettings.mode) {
                        ForEach(VoiceChatService.VoiceChatMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                        }
                    }
                }
                
                Section("Voice Settings") {
                    Toggle("Enable Voice Output", isOn: $voiceChatService.voiceChatSettings.enableVoiceOutput)
                    
                    if voiceChatService.voiceChatSettings.enableVoiceOutput {
                        Slider(value: $voiceChatService.voiceChatSettings.speechRate, in: 0.1...1.0) {
                            Text("Speech Rate")
                        }
                        
                        Slider(value: $voiceChatService.voiceChatSettings.pitchMultiplier, in: 0.5...2.0) {
                            Text("Pitch")
                        }
                        
                        Slider(value: $voiceChatService.voiceChatSettings.volume, in: 0.0...1.0) {
                            Text("Volume")
                        }
                    }
                    
                    Toggle("Enable Audio Visualization", isOn: $voiceChatService.voiceChatSettings.enableAudioVisualization)
                    
                    Picker("Visualization Type", selection: $voiceChatService.voiceChatSettings.visualizationType) {
                        ForEach(VoiceChatService.AudioVisualization.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }
                }
                
                Section("Advanced Settings") {
                    Toggle("Enable Offline Recognition", isOn: $voiceChatService.voiceChatSettings.enableOfflineRecognition)
                    Toggle("Enable Auto-Restart", isOn: $voiceChatService.voiceChatSettings.enableAutoRestart)
                    Toggle("Enable Profanity Filter", isOn: $voiceChatService.voiceChatSettings.enableProfanityFilter)
                    Toggle("Enable Background Noise Reduction", isOn: $voiceChatService.voiceChatSettings.enableBackgroundNoiseReduction)
                }
                
                Section("Conversation") {
                    Stepper("Max Conversation Length", value: $voiceChatService.voiceChatSettings.maxConversationLength, in: 10...500, step: 10)
                    
                    Slider(value: $voiceChatService.voiceChatSettings.silenceTimeout, in: 1.0...10.0) {
                        Text("Silence Timeout: \(Int(voiceChatService.voiceChatSettings.silenceTimeout))s")
                    }
                    
                    Toggle("Enable Conversation Export", isOn: $voiceChatService.voiceChatSettings.enableConversationExport)
                    
                    Button("Clear Conversation History") {
                        voiceChatService.clearConversationHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Voice Chat Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Voice Chat History View

struct VoiceChatHistoryView: View {
    @ObservedObject var voiceChatService: VoiceChatService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(voiceChatService.conversationHistory) { message in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: message.role.icon)
                                .foregroundColor(message.role.color)
                            
                            Text(message.role == .user ? "You" : "Assistant")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if message.isVoice {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.blue)
                            }
                            
                            Text(DateFormatter.localized.string(from: message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(message.content)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    let message = voiceChatService.conversationHistory[indexSet.first!]
                    voiceChatService.deleteMessage(message.id)
                }
            }
            .navigationTitle("Conversation History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        voiceChatService.clearConversationHistory()
                    }
                }
            }
        }
    }
}

// MARK: - Voice Chat Export View

struct VoiceChatExportView: View {
    @ObservedObject var voiceChatService: VoiceChatService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Conversation")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Export your voice chat conversation as a text file for future reference.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    if let url = voiceChatService.exportConversation() {
                        // Share the exported file
                        let activityViewController = UIActivityViewController(
                            activityItems: [url],
                            applicationActivities: nil
                        )
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootViewController = windowScene.windows.first?.rootViewController {
                            rootViewController.present(activityViewController, animated: true)
                        }
                    }
                }) {
                    Text("Export Conversation")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VoiceChatView()
}
