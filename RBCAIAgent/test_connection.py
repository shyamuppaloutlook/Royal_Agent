#!/usr/bin/env python3
"""
Gemini Live API — Connection & Response Test

Tests the full WebSocket lifecycle against the real API:
  1. WebSocket connects to BidiGenerateContent endpoint
  2. Setup message sent → setupComplete received
  3. Text turn sent → model responds with turnComplete
  4. Clean disconnect

Usage:
  python3 test_connection.py <YOUR_API_KEY>
  python3 test_connection.py <YOUR_API_KEY> gemini-2.0-flash-exp   # alternate model
"""

import asyncio
import json
import sys
import time

try:
    import websockets
except ImportError:
    print("❌ Missing dependency: pip3 install --user websockets")
    sys.exit(1)

WS_URL = (
    "wss://generativelanguage.googleapis.com/ws/"
    "google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
)
TIMEOUT = 15  # seconds per step

passed = 0
failed = 0


def ok(name: str, detail: str = ""):
    global passed
    passed += 1
    suffix = f" — {detail}" if detail else ""
    print(f"  ✅ PASS: {name}{suffix}")


def fail(name: str, reason: str):
    global failed
    failed += 1
    print(f"  ❌ FAIL: {name} — {reason}")


# ── Tests ────────────────────────────────────────────────────────────────────


async def run_tests(api_key: str, model: str):
    url = f"{WS_URL}?key={api_key}"

    # Test 1 — WebSocket Connect
    print("\n  [1/5] Connecting WebSocket…")
    try:
        ws = await asyncio.wait_for(
            websockets.connect(url, max_size=10 * 1024 * 1024),
            timeout=TIMEOUT,
        )
        ok("WebSocket Connect")
    except Exception as e:
        fail("WebSocket Connect", str(e))
        return

    # Test 2 — Send Setup
    is_native_audio = "native-audio" in model
    modality = "AUDIO" if is_native_audio else "TEXT"
    print(f"  [2/5] Sending setup message… (modality={modality})")
    setup_payload = {
        "setup": {
            "model": f"models/{model}",
            "generationConfig": {
                "responseModalities": [modality],
            },
            "systemInstruction": {
                "parts": [{"text": "You are a helpful assistant. Reply concisely in one sentence."}]
            },
        }
    }
    if is_native_audio:
        setup_payload["setup"]["generationConfig"]["speechConfig"] = {
            "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": "Kore"}}
        }
    setup_msg = json.dumps(setup_payload)
    try:
        await ws.send(setup_msg)
        ok("Send Setup")
    except Exception as e:
        fail("Send Setup", str(e))
        await ws.close()
        return

    # Test 3 — Receive setupComplete
    print("  [3/5] Waiting for setupComplete…")
    setup_done = False
    deadline = time.time() + TIMEOUT
    while time.time() < deadline:
        try:
            raw = await asyncio.wait_for(ws.recv(), timeout=TIMEOUT)
            msg = json.loads(raw)
            if "setupComplete" in msg:
                setup_done = True
                ok("setupComplete Received")
                break
        except asyncio.TimeoutError:
            break
        except Exception as e:
            fail("Receive setupComplete", str(e))
            await ws.close()
            return

    if not setup_done:
        fail("setupComplete", f"Not received within {TIMEOUT}s — check model name and API key")
        await ws.close()
        return

    # Test 4 — Send text turn and receive response
    print("  [4/5] Sending text turn & waiting for response…")
    turn_msg = json.dumps({
        "clientContent": {
            "turns": [
                {"role": "user", "parts": [{"text": "Say hello in one sentence."}]}
            ],
            "turnComplete": True,
        }
    })
    try:
        t0 = time.time()
        await ws.send(turn_msg)
    except Exception as e:
        fail("Send Text Turn", str(e))
        await ws.close()
        return

    response_text = ""
    turn_complete = False
    deadline = time.time() + TIMEOUT
    while time.time() < deadline:
        try:
            raw = await asyncio.wait_for(ws.recv(), timeout=TIMEOUT)
            msg = json.loads(raw)
            sc = msg.get("serverContent", {})

            # Accumulate text or audio from modelTurn parts
            mt = sc.get("modelTurn", {})
            for part in mt.get("parts", []):
                if "text" in part:
                    response_text += part["text"]
                if "inlineData" in part:
                    response_text += "[audio chunk] "

            if sc.get("turnComplete"):
                turn_complete = True
                break
        except asyncio.TimeoutError:
            break
        except Exception as e:
            fail("Receive Response", str(e))
            await ws.close()
            return

    latency_ms = int((time.time() - t0) * 1000)

    if turn_complete:
        preview = response_text[:120] if response_text else "(audio-only, no text parts)"
        ok("Model Response", f"{latency_ms}ms — \"{preview}\"")
    else:
        fail("Model Response", f"turnComplete not received within {TIMEOUT}s")

    # Test 5 — Clean Disconnect
    print("  [5/5] Disconnecting…")
    try:
        await ws.close()
        ok("Clean Disconnect")
    except Exception:
        ok("Clean Disconnect", "connection already closed")


# ── Main ─────────────────────────────────────────────────────────────────────


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 test_connection.py <API_KEY> [MODEL_NAME]")
        print("\nModels to try:")
        print("  gemini-2.0-flash-live-001  (default)")
        print("  gemini-2.0-flash-exp")
        print("  gemini-2.5-flash-preview-native-audio-dialog")
        sys.exit(1)

    api_key = sys.argv[1]
    model = sys.argv[2] if len(sys.argv) > 2 else "gemini-2.0-flash-live-001"

    print("\n🧪 Gemini Live API — Connection Test")
    print(f"   Model: {model}")
    print("─" * 55)

    asyncio.run(run_tests(api_key, model))

    print("─" * 55)
    print(f"\n📊 Results: {passed} passed, {failed} failed")

    if failed > 0:
        print("\n💡 Troubleshooting:")
        print("   • 403 → API key is invalid or revoked. Generate a new one at:")
        print("     https://aistudio.google.com/apikey")
        print("   • 404 → Model name not found. Try: gemini-2.0-flash-exp")
        print("   • Timeout → Network issue or model doesn't support Live API")
        print()
        sys.exit(1)

    print()


if __name__ == "__main__":
    main()
