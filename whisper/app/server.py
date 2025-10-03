from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
import whisper
import tempfile
import os
from mangum import Mangum

app = FastAPI()
model = None

# Pydantic models for request/response
class HealthResponse(BaseModel):
    status: str
    service: str
    model_loaded: bool

class TranscribeResponse(BaseModel):
    text: str

def get_whisper_model():
    global model
    if model is None:
        model = whisper.load_model("small")  # or medium/large
    return model

@app.get("/health", response_model=HealthResponse)
def health_check():
    try:
        # Test if Whisper model can be loaded
        whisper_model = get_whisper_model()
        return HealthResponse(
            status="healthy",
            service="whisper-transcription",
            model_loaded=whisper_model is not None
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Service unhealthy: {str(e)}")

@app.post("/transcribe", response_model=TranscribeResponse)
async def transcribe(file: UploadFile = File(...)):
    tmp_path = None
    try:
        # Save the uploaded file to a temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name

        # Pass the file path to Whisper
        whisper_model = get_whisper_model()
        result = whisper_model.transcribe(tmp_path)

        return TranscribeResponse(text=result["text"])

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")

    finally:
        # Clean up temporary file
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)

# Lambda handler - Create Mangum instance at module level
handler = Mangum(app)

def lambda_handler(event, context):
    return handler(event, context)

# For local testing (not used in Lambda)
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
