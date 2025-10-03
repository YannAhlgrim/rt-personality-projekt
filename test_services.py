#!/usr/bin/env python3
"""
Local Lambda testing script for both services
"""
import json
import requests
import base64
import time

def test_coqui_tts():
    print("🎤 Testing Coqui TTS Service...")

    # Health check
    try:
        response = requests.get("http://localhost:8000/health")
        print(f"Health Check: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"Health check failed: {e}")
        return

    # TTS synthesis test
    try:
        payload = {"text": "Hallo, das ist ein Test der deutschen Sprachsynthese."}
        response = requests.post("http://localhost:8000/synthesize", json=payload)

        if response.status_code == 200:
            result = response.json()
            print(f"✅ TTS Success: Generated audio for '{result['text']}'")
            print(f"   Audio data length: {len(result['audio'])} characters (base64)")

            # Optionally save audio file
            audio_data = base64.b64decode(result['audio'])
            with open('test_output.wav', 'wb') as f:
                f.write(audio_data)
            print("   Audio saved as 'test_output.wav'")
        else:
            print(f"❌ TTS Failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ TTS Test failed: {e}")

def test_whisper():
    print("\n🎧 Testing Whisper Service...")

    # Health check
    try:
        response = requests.get("http://localhost:8001/health")
        print(f"Health Check: {response.status_code} - {response.json()}")
    except Exception as e:
        print(f"Health check failed: {e}")
        return

    # Transcription test (you need an audio file)
    try:
        # Test with sample file if it exists
        audio_file_path = "whisper/sample.m4a"

        with open(audio_file_path, 'rb') as f:
            files = {'file': ('sample.m4a', f, 'audio/m4a')}
            response = requests.post("http://localhost:8001/transcribe", files=files)

        if response.status_code == 200:
            result = response.json()
            print(f"✅ Whisper Success: '{result['text']}'")
        else:
            print(f"❌ Whisper Failed: {response.status_code} - {response.text}")

    except FileNotFoundError:
        print("❌ Sample audio file not found. Please add an audio file to test transcription.")
    except Exception as e:
        print(f"❌ Whisper Test failed: {e}")

def simulate_lambda_event():
    """
    Simulate Lambda API Gateway events for testing
    """
    print("\n🔄 Simulating Lambda Events...")

    # Test TTS Lambda event
    tts_event = {
        "httpMethod": "POST",
        "path": "/synthesize",
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"text": "Lambda test message"})
    }

    # Test Whisper Lambda event (simplified)
    whisper_event = {
        "httpMethod": "GET",
        "path": "/health",
        "headers": {}
    }

    print("Lambda events created (you can use these with AWS SAM or similar tools)")
    print(f"TTS Event: {json.dumps(tts_event, indent=2)}")
    print(f"Whisper Event: {json.dumps(whisper_event, indent=2)}")

if __name__ == "__main__":
    print("🚀 Starting Local Lambda Service Tests...")
    print("Make sure both services are running:")
    print("  - Coqui TTS: http://localhost:8000")
    print("  - Whisper: http://localhost:8001")
    print()

    # Wait a moment for services to be ready
    time.sleep(2)

    test_coqui_tts()
    test_whisper()
    simulate_lambda_event()

    print("\n✨ Testing complete!")