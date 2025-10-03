import requests
import json
import base64
import os

# Configuration
API_BASE_URL = "https://5jbmpn20cb.execute-api.us-east-1.amazonaws.com/prod"

def test_tts_endpoint():
    """Test the TTS (Text-to-Speech) endpoint"""
    url = f"{API_BASE_URL}/tts"
    payload = {
        "text": "Hello, this is a test of the text to speech service."
    }

    try:
        print(f"🎤 Testing TTS endpoint: {url}")
        print("⏱️  Note: First request may take 2-5 minutes due to model loading...")

        # Increased timeout for cold starts
        response = requests.post(url, json=payload, timeout=300)  # 5 minutes

        if response.status_code == 200:
            print("✅ TTS endpoint working!")

            # If response contains audio data, save it
            if response.headers.get('content-type') == 'audio/wav':
                with open('tts_output.wav', 'wb') as f:
                    f.write(response.content)
                print("🔊 Audio saved as 'tts_output.wav'")
            else:
                print("📄 Response:", response.text[:200])
        elif response.status_code == 504:
            print("❌ TTS endpoint timed out (504)")
            print("💡 This usually happens on cold starts when models need to load.")
            print("🔧 Troubleshooting steps:")
            print("   1. Run: troubleshoot-lambda.bat")
            print("   2. Increase Lambda timeout to 15 minutes (900 seconds)")
            print("   3. Increase Lambda memory to 3008 MB for better performance")
            print("   4. Try the request again - subsequent requests should be faster")
        else:
            print(f"❌ TTS endpoint failed with status {response.status_code}")
            print("Response:", response.text)
            if response.status_code == 502:
                print("💡 502 errors often indicate Lambda function crashes - check CloudWatch logs")

    except requests.exceptions.Timeout:
        print("❌ Request timed out after 5 minutes")
        print("💡 The Lambda function is likely still loading models.")
        print("🔧 Try running: troubleshoot-lambda.bat to optimize the function")
    except requests.exceptions.RequestException as e:
        print(f"❌ Error testing TTS endpoint: {e}")

def test_whisper_endpoint():
    """Test the Whisper (Speech-to-Text) endpoint"""
    url = f"{API_BASE_URL}/whisper"

    # Use sample audio file if it exists
    audio_file = "sample.m4a"
    if os.path.exists(f"whisper/{audio_file}"):
        with open(f"whisper/{audio_file}", "rb") as f:
            audio_data = base64.b64encode(f.read()).decode()
    else:
        # Use a minimal WAV file as fallback
        audio_data = "UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA"

    payload = {
        "audio_data": audio_data
    }

    try:
        print(f"🎧 Testing Whisper endpoint: {url}")
        print("⏱️  Note: First request may take 2-5 minutes due to model loading...")

        response = requests.post(url, json=payload, timeout=300)  # 5 minutes

        if response.status_code == 200:
            print("✅ Whisper endpoint working!")
            result = response.json()
            print("📝 Transcription:", result.get('transcription', 'No transcription returned'))
        elif response.status_code == 504:
            print("❌ Whisper endpoint timed out (504)")
            print("💡 This usually happens on cold starts when models need to load.")
            print("🔧 Run: troubleshoot-lambda.bat to fix timeout issues")
        else:
            print(f"❌ Whisper endpoint failed with status {response.status_code}")
            print("Response:", response.text)

    except requests.exceptions.Timeout:
        print("❌ Request timed out after 5 minutes")
        print("💡 The Lambda function is likely still loading models.")
    except requests.exceptions.RequestException as e:
        print(f"❌ Error testing Whisper endpoint: {e}")

def main():
    print("🧪 Testing RT Personality Project API Endpoints")
    print("=" * 50)
    print(f"🌐 API Base URL: {API_BASE_URL}")
    print()

    if "YOUR_API_ID" in API_BASE_URL:
        print("⚠️  Please update API_BASE_URL with your actual API Gateway ID!")
        return

    print("⚠️  TIMEOUT NOTICE:")
    print("   First requests may take 2-5 minutes due to model loading (cold start)")
    print("   If you get 504 timeouts, run: troubleshoot-lambda.bat")
    print()

    test_tts_endpoint()
    print()
    test_whisper_endpoint()

if __name__ == "__main__":
    main()