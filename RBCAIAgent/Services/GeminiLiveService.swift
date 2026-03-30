import Foundation
import AVFoundation
import Combine

// MARK: - Gemini Live API Service
// Bidirectional WebSocket connection to the Gemini Multimodal Live API.
// Streams user audio in real-time (PCM 16kHz), receives streaming audio/text
// responses, and handles server-side VAD for sub-3-second turn-around time.

class GeminiLiveService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var connectionState: LiveConnectionState = .disconnected
    @Published var isModelSpeaking = false
    @Published var userTranscript = ""
    @Published var modelTranscript = ""
    @Published var error: String?

    enum LiveConnectionState: Equatable {
        case disconnected
        case connecting
        case settingUp
        case ready
        case error(String)
    }

    // MARK: - Callbacks

    var onTurnComplete: ((_ userText: String, _ modelText: String) -> Void)?
    var onInterrupted: (() -> Void)?

    // MARK: - Configuration

    private let apiKey: String
    private let modelName: String
    private let systemPrompt: String

    private static let wsBaseURL =
        "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"

    // MARK: - WebSocket

    private var webSocket: URLSessionWebSocketTask?
    private var wsURLSession: URLSession?

    // MARK: - Audio Engine

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var inputConverter: AVAudioConverter?
    private var isCapturing = false
    private var isPlayerAttached = false

    private let targetInputSampleRate: Double = 16000
    private let geminiOutputSampleRate: Double = 24000

    // MARK: - Accumulation

    private var accumulatedUserText = ""
    private var accumulatedModelText = ""

    // MARK: - Init

    init(apiKey: String,
         modelName: String = "gemini-2.5-flash-native-audio-latest",
         systemPrompt: String) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.systemPrompt = systemPrompt
        super.init()
    }

    deinit {
        disconnect()
    }

    // MARK: - Connection Lifecycle

    func connect() {
        switch connectionState {
        case .disconnected, .error:
            break
        default:
            return
        }

        connectionState = .connecting
        error = nil

        let urlString = "\(Self.wsBaseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            connectionState = .error("Invalid WebSocket URL")
            return
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        wsURLSession = URLSession(configuration: config)
        webSocket = wsURLSession?.webSocketTask(with: url)
        webSocket?.resume()

        connectionState = .settingUp
        sendSetupMessage()
        receiveLoop()
    }

    func disconnect() {
        stopCapture()
        stopPlayback()
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        wsURLSession?.invalidateAndCancel()
        wsURLSession = nil
        accumulatedUserText = ""
        accumulatedModelText = ""
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .disconnected
            self?.isModelSpeaking = false
            self?.userTranscript = ""
            self?.modelTranscript = ""
        }
    }

    // MARK: - Setup Message

    private func sendSetupMessage() {
        let setup: [String: Any] = [
            "setup": [
                "model": "models/\(modelName)",
                "generationConfig": [
                    "responseModalities": ["AUDIO"],
                    "speechConfig": [
                        "voiceConfig": [
                            "prebuiltVoiceConfig": [
                                "voiceName": "Kore"
                            ]
                        ]
                    ]
                ],
                "systemInstruction": [
                    "parts": [["text": systemPrompt]]
                ],
                "realtimeInputConfig": [
                    "automaticActivityDetection": [
                        "disabled": false,
                        "startOfSpeechSensitivity": "START_SENSITIVITY_HIGH",
                        "endOfSpeechSensitivity": "END_SENSITIVITY_HIGH",
                        "silenceDurationMs": 600
                    ],
                    "activityHandling": "START_OF_ACTIVITY_INTERRUPTS"
                ],
                "inputAudioTranscription": [String: Any](),
                "outputAudioTranscription": [String: Any]()
            ]
        ]
        sendJSON(setup)
    }

    // MARK: - Audio Capture

    func startCapture() {
        guard !isCapturing else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("GeminiLive: Audio session error: \(error)")
            return
        }

        let inputNode = audioEngine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetInputSampleRate,
            channels: 1,
            interleaved: true
        ) else { return }

        inputConverter = AVAudioConverter(from: nativeFormat, to: targetFormat)

        if !isPlayerAttached {
            audioEngine.attach(playerNode)
            isPlayerAttached = true
        }

        // Player format: float32 at Gemini's output rate for direct buffer scheduling
        guard let playbackFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: geminiOutputSampleRate,
            channels: 1,
            interleaved: false
        ) else { return }
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: playbackFormat)

        // Capture ~40ms chunks of audio
        let chunkFrames = AVAudioFrameCount(nativeFormat.sampleRate * 0.040)
        inputNode.installTap(onBus: 0, bufferSize: chunkFrames, format: nativeFormat) {
            [weak self] buffer, _ in
            self?.processAndStreamInput(buffer, targetFormat: targetFormat)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isCapturing = true
        } catch {
            print("GeminiLive: Audio engine start error: \(error)")
        }
    }

    func stopCapture() {
        guard isCapturing else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        playerNode.stop()
        audioEngine.stop()
        if isPlayerAttached {
            audioEngine.disconnectNodeOutput(playerNode)
            audioEngine.detach(playerNode)
            isPlayerAttached = false
        }
        isCapturing = false
    }

    // MARK: - Input Processing

    private func processAndStreamInput(_ buffer: AVAudioPCMBuffer,
                                       targetFormat: AVAudioFormat) {
        guard let converter = inputConverter else { return }

        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard outputFrameCount > 0,
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat,
                                                  frameCapacity: outputFrameCount)
        else { return }

        var conversionError: NSError?
        var consumed = false
        converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if consumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return buffer
        }

        if conversionError != nil || outputBuffer.frameLength == 0 { return }

        guard let channelData = outputBuffer.int16ChannelData else { return }
        let byteCount = Int(outputBuffer.frameLength) * MemoryLayout<Int16>.size
        let data = Data(bytes: channelData[0], count: byteCount)
        let base64 = data.base64EncodedString()

        let message: [String: Any] = [
            "realtimeInput": [
                "audio": [
                    "mimeType": "audio/pcm;rate=16000",
                    "data": base64
                ]
            ]
        ]
        sendJSON(message)
    }

    // MARK: - Audio Playback

    private func playAudioChunk(_ rawPCMData: Data) {
        let sampleCount = rawPCMData.count / MemoryLayout<Int16>.size
        guard sampleCount > 0 else { return }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: geminiOutputSampleRate,
            channels: 1,
            interleaved: false
        ),
        let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format,
                                         frameCapacity: AVAudioFrameCount(sampleCount))
        else { return }

        pcmBuffer.frameLength = AVAudioFrameCount(sampleCount)

        rawPCMData.withUnsafeBytes { rawBuffer in
            guard let src = rawBuffer.bindMemory(to: Int16.self).baseAddress,
                  let dst = pcmBuffer.floatChannelData?[0] else { return }
            for i in 0..<sampleCount {
                dst[i] = Float(src[i]) / 32768.0
            }
        }

        if isCapturing && !playerNode.isPlaying {
            playerNode.play()
        }
        playerNode.scheduleBuffer(pcmBuffer)
    }

    private func stopPlayback() {
        playerNode.stop()
        DispatchQueue.main.async { [weak self] in
            self?.isModelSpeaking = false
        }
    }

    // MARK: - Receive Loop

    private func receiveLoop() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleServerMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleServerMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receiveLoop()

            case .failure(let err):
                print("GeminiLive: WebSocket receive error: \(err)")
                DispatchQueue.main.async {
                    self.connectionState = .error(err.localizedDescription)
                    self.error = err.localizedDescription
                }
            }
        }
    }

    // MARK: - Server Message Handling

    private func handleServerMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        if json["setupComplete"] != nil {
            DispatchQueue.main.async { [weak self] in
                self?.connectionState = .ready
                print("GeminiLive: Session ready")
            }
            return
        }

        if let serverContent = json["serverContent"] as? [String: Any] {
            handleServerContent(serverContent)
            return
        }

        if let goAway = json["goAway"] as? [String: Any] {
            print("GeminiLive: Server go-away: \(goAway)")
            return
        }
    }

    private func handleServerContent(_ content: [String: Any]) {
        // Model turn — audio and/or text parts
        if let modelTurn = content["modelTurn"] as? [String: Any],
           let parts = modelTurn["parts"] as? [[String: Any]] {
            for part in parts {
                if let inlineData = part["inlineData"] as? [String: Any],
                   let base64Str = inlineData["data"] as? String,
                   let audioData = Data(base64Encoded: base64Str) {
                    playAudioChunk(audioData)
                }
                if let text = part["text"] as? String {
                    accumulatedModelText += text
                    DispatchQueue.main.async { [weak self] in
                        self?.modelTranscript = self?.accumulatedModelText ?? ""
                    }
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.isModelSpeaking = true
            }
        }

        // Input (user) transcription — streamed incrementally by the server
        if let inputTranscription = content["inputTranscription"] as? [String: Any],
           let text = inputTranscription["text"] as? String {
            accumulatedUserText += text
            DispatchQueue.main.async { [weak self] in
                self?.userTranscript = self?.accumulatedUserText ?? ""
            }
        }

        // Output (model) transcription of the audio response
        if let outputTranscription = content["outputTranscription"] as? [String: Any],
           let text = outputTranscription["text"] as? String {
            accumulatedModelText += text
            DispatchQueue.main.async { [weak self] in
                self?.modelTranscript = self?.accumulatedModelText ?? ""
            }
        }

        // Interrupted — user barged in while model was speaking
        if let interrupted = content["interrupted"] as? Bool, interrupted {
            stopPlayback()
            accumulatedModelText = ""
            DispatchQueue.main.async { [weak self] in
                self?.isModelSpeaking = false
                self?.modelTranscript = ""
                self?.onInterrupted?()
            }
        }

        // Turn complete — full exchange done, commit to history
        if let turnComplete = content["turnComplete"] as? Bool, turnComplete {
            let userText = accumulatedUserText
            let modelText = accumulatedModelText
            accumulatedUserText = ""
            accumulatedModelText = ""
            DispatchQueue.main.async { [weak self] in
                self?.userTranscript = ""
                self?.modelTranscript = ""
                self?.isModelSpeaking = false
                self?.onTurnComplete?(userText, modelText)
            }
        }
    }

    // MARK: - Send Helpers

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }
        webSocket?.send(.string(text)) { error in
            if let error = error {
                print("GeminiLive: send error: \(error)")
            }
        }
    }

    /// Send a text message to the model as part of the conversation
    func sendTextTurn(_ text: String) {
        let message: [String: Any] = [
            "clientContent": [
                "turns": [
                    [
                        "role": "user",
                        "parts": [["text": text]]
                    ]
                ],
                "turnComplete": true
            ]
        ]
        sendJSON(message)
    }
}
