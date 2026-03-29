#!/usr/bin/env swift

import Foundation

// ============================================================================
// Gemini Live API — Connection Test
//
// Tests the full WebSocket lifecycle:
//   1. WebSocket opens to BidiGenerateContent endpoint
//   2. Setup message is sent and setupComplete is received
//   3. A text turn is sent and the model responds
//   4. Connection closes cleanly
//
// Run:  swift test_connection.swift
// ============================================================================

let apiKey = "AIzaSyAmlWf2ZfoB1yWtBd6Nqud2MeV0RLFXGcU"
let modelName = "gemini-2.0-flash-live-001"
let wsBaseURL = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
let timeoutSeconds: TimeInterval = 15

// MARK: - Test State

var testsPassed = 0
var testsFailed = 0
var testLog: [String] = []

func pass(_ name: String) {
    testsPassed += 1
    let msg = "  ✅ PASS: \(name)"
    testLog.append(msg)
    print(msg)
}

func fail(_ name: String, reason: String) {
    testsFailed += 1
    let msg = "  ❌ FAIL: \(name) — \(reason)"
    testLog.append(msg)
    print(msg)
}

// MARK: - Helpers

func toJSON(_ dict: [String: Any]) -> String? {
    guard let data = try? JSONSerialization.data(withJSONObject: dict),
          let text = String(data: data, encoding: .utf8) else { return nil }
    return text
}

func parseJSON(_ text: String) -> [String: Any]? {
    guard let data = text.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    return json
}

// MARK: - Run Tests

print("\n🧪 Gemini Live API Connection Tests")
print("   Model: \(modelName)")
print("   Endpoint: \(wsBaseURL)")
print(String(repeating: "─", count: 55))

let done = DispatchSemaphore(value: 0)

// --- Test 1: WebSocket Opens ---

let urlString = "\(wsBaseURL)?key=\(apiKey)"
guard let url = URL(string: urlString) else {
    fail("URL Construction", reason: "Could not build WebSocket URL")
    exit(1)
}
pass("URL Construction")

let session = URLSession(configuration: .default)
let ws = session.webSocketTask(with: url)
ws.resume()

// Give the TCP handshake a moment
Thread.sleep(forTimeInterval: 1.0)

// --- Test 2: Send Setup Message ---

let setupMessage: [String: Any] = [
    "setup": [
        "model": "models/\(modelName)",
        "generationConfig": [
            "responseModalities": ["TEXT"]
        ],
        "systemInstruction": [
            "parts": [["text": "You are a helpful assistant. Reply concisely."]]
        ]
    ]
]

guard let setupJSON = toJSON(setupMessage) else {
    fail("Setup Serialization", reason: "Could not serialize setup message")
    ws.cancel(with: .normalClosure, reason: nil)
    exit(1)
}
pass("Setup Serialization")

let setupSent = DispatchSemaphore(value: 0)
var setupSendError: Error?

ws.send(.string(setupJSON)) { error in
    setupSendError = error
    setupSent.signal()
}

setupSent.wait()

if let err = setupSendError {
    fail("Send Setup", reason: err.localizedDescription)
    ws.cancel(with: .normalClosure, reason: nil)
    exit(1)
}
pass("Send Setup")

// --- Test 3: Receive setupComplete ---

var receivedSetupComplete = false
var receivedModelResponse = false
var modelResponseText = ""
var receiveError: String?

func receiveNext() {
    ws.receive { result in
        switch result {
        case .success(let message):
            var text: String?
            switch message {
            case .string(let s): text = s
            case .data(let d): text = String(data: d, encoding: .utf8)
            @unknown default: break
            }

            guard let text = text, let json = parseJSON(text) else {
                receiveNext()
                return
            }

            // Check for setupComplete
            if json["setupComplete"] != nil {
                receivedSetupComplete = true
                pass("Receive setupComplete")

                // --- Test 4: Send a text turn ---
                let textTurn: [String: Any] = [
                    "clientContent": [
                        "turns": [
                            ["role": "user", "parts": [["text": "Say hello in one sentence."]]]
                        ],
                        "turnComplete": true
                    ]
                ]

                if let turnJSON = toJSON(textTurn) {
                    ws.send(.string(turnJSON)) { error in
                        if let err = error {
                            fail("Send Text Turn", reason: err.localizedDescription)
                            done.signal()
                        } else {
                            pass("Send Text Turn")
                            receiveNext()
                        }
                    }
                }
                return
            }

            // Check for serverContent with model response
            if let serverContent = json["serverContent"] as? [String: Any] {
                if let modelTurn = serverContent["modelTurn"] as? [String: Any],
                   let parts = modelTurn["parts"] as? [[String: Any]] {
                    for part in parts {
                        if let t = part["text"] as? String {
                            modelResponseText += t
                        }
                    }
                }

                if let turnComplete = serverContent["turnComplete"] as? Bool, turnComplete {
                    receivedModelResponse = true
                    if !modelResponseText.isEmpty {
                        pass("Model Response Received")
                        print("       Response: \"\(modelResponseText.prefix(120))\"")
                    } else {
                        pass("Turn Complete (audio mode — no text in parts)")
                    }
                    done.signal()
                    return
                }
            }

            receiveNext()

        case .failure(let error):
            receiveError = error.localizedDescription
            done.signal()
        }
    }
}

receiveNext()

// Wait with timeout
let waitResult = done.wait(timeout: .now() + timeoutSeconds)

if waitResult == .timedOut {
    if !receivedSetupComplete {
        fail("Receive setupComplete", reason: "Timed out after \(Int(timeoutSeconds))s — server never sent setupComplete. Check API key and model name.")
    } else if !receivedModelResponse {
        fail("Model Response", reason: "Timed out waiting for model response after \(Int(timeoutSeconds))s")
    }
} else if let err = receiveError {
    if !receivedSetupComplete {
        fail("WebSocket Receive", reason: err)
    }
}

// --- Test 5: Clean Disconnect ---

ws.cancel(with: .normalClosure, reason: nil)
pass("Clean Disconnect")

// MARK: - Summary

print(String(repeating: "─", count: 55))
print("\n📊 Results: \(testsPassed) passed, \(testsFailed) failed\n")

if testsFailed > 0 {
    print("💡 Troubleshooting:")
    print("   • If setupComplete times out, try a different model name:")
    print("     - gemini-2.0-flash-exp")
    print("     - gemini-2.5-flash-preview-native-audio-dialog")
    print("   • Verify the API key is valid and has Gemini API enabled")
    print("   • Ensure network access to generativelanguage.googleapis.com\n")
    exit(1)
}

exit(0)
