import SwiftUI
import AVFoundation

struct ActiveCallView: View {
    @ObservedObject var voiceCallService: VoiceCallService
    @Environment(\.presentationMode) var presentationMode
    @State private var showingKeypad = false
    @State private var showingSettings = false
    @State private var showingTranscription = false
    @State private var showingCallSummary = false
    @State private var keypadNumber = ""
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Status Bar
                topStatusBarView
                
                // Main Call Area
                mainCallAreaView
                
                // Transcription Area
                transcriptionAreaView
                
                // Response Area
                responseAreaView
                
                // Audio Visualization
                audioVisualizationView
                
                Spacer()
                
                // Call Controls
                callControlsView
                
                // Bottom Actions
                bottomActionsView
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .sheet(isPresented: $showingKeypad) {
                CallKeypadView(keypadNumber: $keypadNumber)
            }
            .sheet(isPresented: $showingSettings) {
                VoiceCallSettingsView(voiceCallService: voiceCallService)
            }
            .sheet(isPresented: $showingTranscription) {
                VoiceCallTranscriptionView(voiceCallService: voiceCallService)
            }
            .sheet(isPresented: $showingCallSummary) {
                if let lastCall = voiceCallService.getCallHistory().first {
                    CallSummaryView(voiceCallService: voiceCallService, callRecord: lastCall)
                }
            }
        }
    }
    
    // MARK: - Top Status Bar
    
    private var topStatusBarView: some View {
        HStack {
            Button(action: {
                if voiceCallService.isCallActive {
                    voiceCallService.endCall()
                    
                    // Show summary after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let lastCall = voiceCallService.getCallHistory().first {
                            showingCallSummary = true
                        }
                    }
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack {
                Text("Voice Assistant")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Circle()
                        .fill(voiceCallService.connectionStatus.color)
                        .frame(width: 8, height: 8)
                    
                    Text(voiceCallService.connectionStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(voiceCallService.connectionStatus.color)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding()
    }
    
    // MARK: - Main Call Area
    
    private var mainCallAreaView: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            // Call Timer
            Text(formatDuration(voiceCallService.callDuration))
                .font(.system(size: 42, weight: .thin, design: .monospaced))
                .foregroundColor(.primary)
            
            // Call Status
            HStack(spacing: 20) {
                // Call Quality
                HStack {
                    ForEach(0..<4) { index in
                        Image(systemName: "cellularbars")
                            .font(.caption)
                            .foregroundColor(index < voiceCallService.callQuality.signalStrength ? 
                                           voiceCallService.callQuality.color : .gray.opacity(0.3))
                    }
                    
                    Text(voiceCallService.callQuality.rawValue)
                        .font(.caption)
                        .foregroundColor(voiceCallService.callQuality.color)
                }
                
                // Status Indicators
                HStack(spacing: 12) {
                    if voiceCallService.isTranscribing {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .scaleEffect(1.5)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), 
                                          value: voiceCallService.isTranscribing)
                            
                            Text("Transcribing")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if voiceCallService.isSpeaking {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                                .scaleEffect(1.5)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), 
                                          value: voiceCallService.isSpeaking)
                            
                            Text("Speaking")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 30)
    }
    
    // MARK: - Transcription Area
    
    private var transcriptionAreaView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("You")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if !voiceCallService.transcription.isEmpty {
                    Button(action: {
                        showingTranscription = true
                    }) {
                        Image(systemName: "expand")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ScrollView {
                Text(voiceCallService.transcription.isEmpty ? 
                     "Start speaking to see your words..." : 
                     voiceCallService.transcription)
                    .font(.body)
                    .foregroundColor(voiceCallService.transcription.isEmpty ? .gray : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .frame(maxHeight: 80)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Response Area
    
    private var responseAreaView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Assistant")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if voiceCallService.isSpeaking {
                    Button(action: {
                        voiceCallService.stopSpeaking()
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                                .font(.caption)
                            Text("Stop")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            
            ScrollView {
                Text(voiceCallService.agentResponse.isEmpty ? 
                     "Assistant will respond here..." : 
                     voiceCallService.agentResponse)
                    .font(.body)
                    .foregroundColor(voiceCallService.agentResponse.isEmpty ? .gray : .blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .frame(maxHeight: 80)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Audio Visualization
    
    private var audioVisualizationView: some View {
        VStack(spacing: 12) {
            // Audio Waveform
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<30) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    voiceCallService.isCallActive ? .green : .gray.opacity(0.3),
                                    voiceCallService.isCallActive ? .blue : .gray.opacity(0.2)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 3, height: CGFloat.random(in: 5...40) * voiceCallService.audioLevel)
                        .animation(.easeInOut(duration: 0.1), value: voiceCallService.audioLevel)
                }
            }
            .frame(height: 50)
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Call Controls
    
    private var callControlsView: some View {
        HStack(spacing: 50) {
            // Mute Button
            Button(action: {
                voiceCallService.toggleMute()
            }) {
                ZStack {
                    Circle()
                        .fill(voiceCallService.isMuted ? Color.red : Color.gray.opacity(0.2))
                        .frame(width: 65, height: 65)
                        .shadow(color: voiceCallService.isMuted ? .red.opacity(0.3) : .clear, 
                               radius: 8, x: 0, y: 4)
                    
                    Image(systemName: voiceCallService.isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(voiceCallService.isMuted ? .white : .primary)
                }
            }
            .scaleEffect(voiceCallService.isMuted ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: voiceCallService.isMuted)
            
            // End Call Button
            Button(action: {
                voiceCallService.endCall()
                
                // Show summary after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let lastCall = voiceCallService.getCallHistory().first {
                        showingCallSummary = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 85, height: 85)
                        .shadow(color: .red.opacity(0.4), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "phone.down.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: voiceCallService.isCallActive)
            
            // Speaker Button
            Button(action: {
                voiceCallService.toggleSpeaker()
            }) {
                ZStack {
                    Circle()
                        .fill(voiceCallService.isSpeakerOn ? Color.blue : Color.gray.opacity(0.2))
                        .frame(width: 65, height: 65)
                        .shadow(color: voiceCallService.isSpeakerOn ? .blue.opacity(0.3) : .clear, 
                               radius: 8, x: 0, y: 4)
                    
                    Image(systemName: voiceCallService.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.title2)
                        .foregroundColor(voiceCallService.isSpeakerOn ? .white : .primary)
                }
            }
            .scaleEffect(voiceCallService.isSpeakerOn ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: voiceCallService.isSpeakerOn)
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActionsView: some View {
        HStack {
            // Keypad Button
            Button(action: {
                showingKeypad = true
            }) {
                HStack {
                    Image(systemName: "square.grid.3x3")
                    Text("Keypad")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(15)
            }
            
            Spacer()
            
            // Add Call Button
            Button(action: {
                // Add call functionality
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(15)
            }
            
            Spacer()
            
            // Face ID / Security Button
            Button(action: {
                // Security features
            }) {
                HStack {
                    Image(systemName: "faceid")
                    Text("Secure")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(15)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
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

// MARK: - Call Keypad View

struct CallKeypadView: View {
    @Binding var keypadNumber: String
    @Environment(\.presentationMode) var presentationMode
    
    let keypadButtons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"]
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Display Area
                VStack {
                    Text("Enter number or command")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(keypadNumber.isEmpty ? "Tap to enter" : keypadNumber)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // Keypad
                VStack(spacing: 15) {
                    ForEach(keypadButtons, id: \.self) { row in
                        HStack(spacing: 20) {
                            ForEach(row, id: \.self) { button in
                                KeypadButton(title: button) {
                                    keypadNumber += button
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Keypad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Call") {
                        // Initiate call with keypad number
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(keypadNumber.isEmpty)
                }
            }
        }
    }
}

// MARK: - Keypad Button

struct KeypadButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 70, height: 70)
                
                Text(title)
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct ActiveCallView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveCallView(voiceCallService: VoiceCallService())
    }
}
