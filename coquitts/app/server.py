import io
import json
import base64
from flask import Flask, request, jsonify
from TTS.api import TTS
import soundfile as sf
from mangum import Mangum
import os

app = Flask(__name__)
tts_model = None

def get_tts_model():
    global tts_model
    if tts_model is None:
        tts_model = TTS(model_name="tts_models/de/thorsten/tacotron2-DCA", progress_bar=False, gpu=False)
    return tts_model

@app.route("/health", methods=["GET"])
def health_check():
    try:
        # Test if TTS model can be loaded
        model = get_tts_model()
        return jsonify({
            "status": "healthy",
            "service": "coqui-tts",
            "model_loaded": model is not None
        }), 200
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "service": "coqui-tts",
            "error": str(e)
        }), 500

@app.route("/synthesize", methods=["POST"])
def synthesize():
    try:
        # Expect JSON: {"text": "..."}
        data = request.get_json()
        text = data.get("text")
        if not text:
            return jsonify({"error": "No text provided"}), 400

        # Generate audio as numpy array
        model = get_tts_model()
        wav = model.tts(text)

        # Write audio to BytesIO
        audio_bytes = io.BytesIO()
        sf.write(audio_bytes, wav, 22050, format="WAV")
        audio_bytes.seek(0)

        # Encode as base64 for Lambda API Gateway response
        audio_b64 = base64.b64encode(audio_bytes.read()).decode("utf-8")

        return jsonify({"text": text, "audio": audio_b64})

    except Exception as e:
        return jsonify({"error": f"TTS processing failed: {str(e)}"}), 500

# Lambda handler - Create Mangum instance at module level
handler = Mangum(app)

def lambda_handler(event, context):
    return handler(event, context)

# For local testing
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
