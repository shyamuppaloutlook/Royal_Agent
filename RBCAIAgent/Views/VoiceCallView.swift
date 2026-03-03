import SwiftUI
import AVFoundation

struct VoiceCallView: View {
    @StateObject private var voiceCallService = VoiceCallService()
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingTranscription = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Call Status
                callStatusView
                
                // Audio Visualization
                audioVisualizationView
                
                // Transcription Display
                transcriptionView
                
                // Agent Response
                agentResponseView
                
                Spacer()
                
                // Call Controls
                callControlsView
                
                // Bottom Actions
                bottomActionsView
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                VoiceCallSettingsView(voiceCallService: voiceCallService)
            }
            .sheet(isPresented: $showingHistory) {
                VoiceCallHistoryView(voiceCallService: voiceCallService)
            }
            .sheet(isPresented: $showingTranscription) {
                VoiceCallTranscriptionView(voiceCallService: voiceCallService)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button(action: {
                // Back action
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack {
                Text("Voice Call")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(voiceCallService.connectionStatus.rawValue)
                    .font(.caption)
                    .foregroundColor(voiceCallService.connectionStatus.color)
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
    
    // MARK: - Call Status View
    
    private var callStatusView: some View {
        VStack(spacing: 16) {
            // Call Timer
            Text(formatDuration(voiceCallService.callDuration))
                .font(.system(size: 48, weight: .thin, design: .monospaced))
                .foregroundColor(.primary)
            
            // Call Quality Indicator
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
            
            // Connection Status
            HStack {
                Image(systemName: voiceCallService.connectionStatus.icon)
                    .font(.caption)
                    .foregroundColor(voiceCallService.connectionStatus.color)
                
                Text(voiceCallService.connectionStatus.rawValue)
                    .font(.caption)
                    .foregroundColor(voiceCallService.connectionStatus.color)
            }
        }
        .padding()
    }
    
    // MARK: - Audio Visualization View
    
    private var audioVisualizationView: some View {
        VStack(spacing: 12) {
            // Status Indicators
            HStack(spacing: 20) {
                // Transcribing Indicator
                HStack {
                    Circle()
                        .fill(voiceCallService.isTranscribing ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(voiceCallService.isTranscribing ? 1.5 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), 
                                  value: voiceCallService.isTranscribing)
                    
                    Text("Transcribing")
                        .font(.caption)
                        .foregroundColor(voiceCallService.isTranscribing ? .red : .gray)
                }
                
                // Speaking Indicator
                HStack {
                    Circle()
                        .fill(voiceCallService.isSpeaking ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(voiceCallService.isSpeaking ? 1.5 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), 
                                  value: voiceCallService.isSpeaking)
                    
                    Text("Speaking")
                        .font(.caption)
                        .foregroundColor(voiceCallService.isSpeaking ? .blue : .gray)
                }
            }
            
            // Audio Level Visualization
            HStack(spacing: 2) {
                ForEach(0..<20) { index in
                    Rectangle()
                        .fill(voiceCallService.isCallActive ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 4, height: CGFloat.random(in: 10...50) * voiceCallService.audioLevel)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.1), value: voiceCallService.audioLevel)
                }
            }
            .frame(height: 60)
        }
        .padding()
    }
    
    // MARK: - Transcription View
    
    private var transcriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("You said:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if !voiceCallService.transcription.isEmpty {
                    Button(action: {
                        showingTranscription = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ScrollView {
                Text(voiceCallService.transcription.isEmpty ? "Start speaking to see transcription..." : voiceCallService.transcription)
                    .font(.body)
                    .foregroundColor(voiceCallService.transcription.isEmpty ? .gray : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 100)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Agent Response View
    
    private var agentResponseView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Agent response:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if voiceCallService.isSpeaking {
                    Button(action: {
                        voiceCallService.stopSpeaking()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            ScrollView {
                Text(voiceCallService.agentResponse.isEmpty ? "Agent will respond here..." : voiceCallService.agentResponse)
                    .font(.body)
                    .foregroundColor(voiceCallService.agentResponse.isEmpty ? .gray : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 100)
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Call Controls View
    
    private var callControlsView: some View {
        HStack(spacing: 40) {
            // Mute Button
            Button(action: {
                voiceCallService.toggleMute()
            }) {
                ZStack {
                    Circle()
                        .fill(voiceCallService.isMuted ? Color.red : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: voiceCallService.isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(voiceCallService.isMuted ? .white : .primary)
                }
            }
            
            // End Call Button
            Button(action: {
                if voiceCallService.isCallActive {
                    voiceCallService.endCall()
                } else {
                    voiceCallService.startCall()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(voiceCallService.isCallActive ? Color.red : Color.green)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: voiceCallService.isCallActive ? "phone.down.fill" : "phone.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            }
            
            // Speaker Button
            Button(action: {
                voiceCallService.toggleSpeaker()
            }) {
                ZStack {
                    Circle()
                        .fill(voiceCallService.isSpeakerOn ? Color.blue : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: voiceCallService.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.title2)
                        .foregroundColor(voiceCallService.isSpeakerOn ? .white : .primary)
                }
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Bottom Actions View
    
    private var bottomActionsView: some View {
        HStack {
            // History Button
            Button(action: {
                showingHistory = true
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text("History")
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
            }
            
            Spacer()
            
            // Statistics
            let stats = voiceCallService.getCallStatistics()
            Text("\(stats.totalCalls) calls • \(String(format: "%.1f", stats.successRate))% success")
                .font(.caption)
                .foregroundColor(.gray)
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

// MARK: - Settings View

struct VoiceCallSettingsView: View {
    @ObservedObject var voiceCallService: VoiceCallService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Voice Response")) {
                    Toggle("Enable Voice Response", isOn: Binding(
                        get: { voiceCallService.voiceCallSettings.enableVoiceResponse },
                        set: { _ in 
                            if voiceCallService.voiceCallSettings.enableVoiceResponse {
                                voiceCallService.disableVoiceResponse()
                            } else {
                                voiceCallService.enableVoiceResponse()
                            }
                        }
                    ))
                    
                    Toggle("Auto Transcription", isOn: Binding(
                        get: { voiceCallService.voiceCallSettings.enableAutoTranscription },
                        set: { voiceCallService.voiceCallSettings.enableAutoTranscription = $0 }
                    ))
                }
                
                Section(header: Text("Speech Settings")) {
                    HStack {
                        Text("Speech Rate")
                        Spacer()
                        Slider(value: Binding(
                            get: { voiceCallService.voiceCallSettings.speechRate },
                            set: { voiceCallService.voiceCallSettings.speechRate = $0 }
                        ), in: 0.1...1.0)
                    }
                    
                    HStack {
                        Text("Pitch")
                        Spacer()
                        Slider(value: Binding(
                            get: { voiceCallService.voiceCallSettings.pitchMultiplier },
                            set: { voiceCallService.voiceCallSettings.pitchMultiplier = $0 }
                        ), in: 0.5...2.0)
                    }
                    
                    HStack {
                        Text("Volume")
                        Spacer()
                        Slider(value: Binding(
                            get: { voiceCallService.voiceCallSettings.volume },
                            set: { voiceCallService.voiceCallSettings.volume = $0 }
                        ), in: 0.0...1.0)
                    }
                }
                
                Section(header: Text("Audio Processing")) {
                    Toggle("Noise Reduction", isOn: Binding(
                        get: { voiceCallService.voiceCallSettings.enableNoiseReduction },
                        set: { voiceCallService.voiceCallSettings.enableNoiseReduction = $0 }
                    ))
                    
                    Toggle("Echo Cancellation", isOn: Binding(
                        get: { voiceCallService.voiceCallSettings.enableEchoCancellation },
                        set: { voiceCallService.voiceCallSettings.enableEchoCancellation = $0 }
                    ))
                    
                    Toggle("Automatic Gain Control", isOn: Binding(
                        get: { voiceCallService.voiceCallSettings.enableAutomaticGainControl },
                        set: { voiceCallService.voiceCallSettings.enableAutomaticGainControl = $0 }
                    ))
                }
                
                Section(header: Text("Recording")) {
                    Toggle("Call Recording", isOn: Binding(
                        get: { voiceCallService.voiceCallSettings.enableCallRecording },
                        set: { voiceCallService.voiceCallSettings.enableCallRecording = $0 }
                    ))
                    
                    Toggle("Save Transcriptions", isOn: Binding(
                        get: { voiceCallService.voiceCallSettings.enableTranscriptionSave },
                        set: { voiceCallService.voiceCallSettings.enableTranscriptionSave = $0 }
                    ))
                    
                    HStack {
                        Text("Max Call Duration")
                        Spacer()
                        Text("\(Int(voiceCallService.voiceCallSettings.maxCallDuration / 60)) min")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Voice Call Settings")
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

// MARK: - History View

struct VoiceCallHistoryView: View {
    @ObservedObject var voiceCallService: VoiceCallService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if voiceCallService.getCallHistory().isEmpty {
                    Text("No call history")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(voiceCallService.getCallHistory()) { call in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(call.formattedDate)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Image(systemName: call.wasSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(call.wasSuccessful ? .green : .red)
                            }
                            
                            HStack {
                                Text("Duration: \(call.formattedDuration)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text(call.callQuality.rawValue)
                                    .font(.caption)
                                    .foregroundColor(call.callQuality.color)
                            }
                            
                            if !call.transcription.isEmpty {
                                Text(call.transcription)
                                    .font(.body)
                                    .lineLimit(2)
                            }
                            
                            if !call.agentResponse.isEmpty {
                                Text("Agent: \(call.agentResponse)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Call History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        voiceCallService.clearCallHistory()
                    }
                    .disabled(voiceCallService.getCallHistory().isEmpty)
                }
            }
        }
    }
}

// MARK: - Transcription View

struct VoiceCallTranscriptionView: View {
    @ObservedObject var voiceCallService: VoiceCallService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if voiceCallService.transcription.isEmpty {
                    Text("No transcription available")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ScrollView {
                        Text(voiceCallService.transcription)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        // Share transcription
                    }
                    .disabled(voiceCallService.transcription.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

struct VoiceCallView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceCallView()
    }
}
