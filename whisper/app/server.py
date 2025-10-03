from flask import Flask, request, jsonify
import whisper
import tempfile
import os
from mangum import Mangum

app = Flask(__name__)
model = None

def get_whisper_model():
    global model
    if model is None:
        model = whisper.load_model("small")  # or medium/large
    return model

@app.route("/health", methods=["GET"])
def health_check():
    try:
        # Test if Whisper model can be loaded
        whisper_model = get_whisper_model()
        return jsonify({
            "status": "healthy",
            "service": "whisper-transcription",
            "model_loaded": whisper_model is not None
        }), 200
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "service": "whisper-transcription",
            "error": str(e)
        }), 500

@app.route("/transcribe", methods=["POST"])
def transcribe():
    tmp_path = None
    try:
        if "file" not in request.files:
            return jsonify({"error": "No file uploaded"}), 400

        file = request.files["file"]

        # Save the uploaded file to a temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            file.save(tmp.name)
            tmp_path = tmp.name

        # Pass the file path to Whisper
        whisper_model = get_whisper_model()
        result = whisper_model.transcribe(tmp_path)

        return jsonify({"text": result["text"]})

    except Exception as e:
        return jsonify({"error": f"Transcription failed: {str(e)}"}), 500

    finally:
        # Clean up temporary file
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)

# Lambda handler - Create Mangum instance at module level
handler = Mangum(app)

def lambda_handler(event, context):
    return handler(event, context)

# For local testing
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8001, debug=True)
