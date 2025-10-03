import io
import json
import base64
import tempfile
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from TTS.api import TTS
import soundfile as sf
from mangum import Mangum

app = FastAPI()
tts_model = None

# Pydantic models for request/response
class SynthesizeRequest(BaseModel):
    text: str

class HealthResponse(BaseModel):
    status: str
    service: str
    model_loaded: bool

class SynthesizeResponse(BaseModel):
    text: str
    audio: str

def get_tts_model():
    global tts_model
    if tts_model is None:
        tts_model = TTS(model_name="tts_models/de/thorsten/tacotron2-DCA", progress_bar=False, gpu=False)
    return tts_model

@app.get("/health", response_model=HealthResponse)
def health_check():
    try:
        # Test if TTS model can be loaded
        model = get_tts_model()
        return HealthResponse(
            status="healthy",
            service="coqui-tts",
            model_loaded=model is not None
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Service unhealthy: {str(e)}")

@app.post("/synthesize", response_model=SynthesizeResponse)
def synthesize(request: SynthesizeRequest):
    try:
        text = request.text.strip()

        if not text:
            raise HTTPException(status_code=400, detail="No text provided")

        # Get TTS model
        model = get_tts_model()

        # Generate audio as numpy array
        wav = model.tts(text)

        # Write audio to BytesIO
        audio_bytes = io.BytesIO()
        sf.write(audio_bytes, wav, 22050, format="WAV")
        audio_bytes.seek(0)

        # Encode as base64 for Lambda API Gateway response
        audio_b64 = base64.b64encode(audio_bytes.read()).decode("utf-8")

        return SynthesizeResponse(text=text, audio=audio_b64)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS processing failed: {str(e)}")

# Lambda handler - Create Mangum instance at module level
handler = Mangum(app)

def lambda_handler(event, context):
    return handler(event, context)

# For local testing (not used in Lambda)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
