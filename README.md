# RT Personality Project - Local Lambda Testing

## 🚀 Quick Start

### Method 1: Docker Compose (Recommended for Development)
```bash
# Start both services
docker-compose up --build

# Test the services
python test_services.py

# Or use the batch script on Windows
test_local.bat
```

### Method 2: AWS SAM (Lambda Simulation)
```bash
# Install AWS SAM CLI first
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

# Build the application
sam build

# Start local API Gateway
sam local start-api --port 3000

# Test endpoints
curl http://localhost:3000/health
curl -X POST http://localhost:3000/synthesize -H "Content-Type: application/json" -d '{"text":"Hello World"}'
```

### Method 3: Direct Python Execution
```bash
# Terminal 1 - Coqui TTS
cd coquitts/app
python server.py

# Terminal 2 - Whisper
cd whisper/app
python server.py
```

## 🧪 Testing Endpoints

### Health Checks
- Coqui TTS: `GET http://localhost:8000/health`
- Whisper: `GET http://localhost:8001/health`

### Functional Tests
- **TTS Synthesis**: `POST http://localhost:8000/synthesize`
  ```json
  {"text": "Your German text here"}
  ```

- **Speech Transcription**: `POST http://localhost:8001/transcribe`
  - Upload audio file with key "file"
  - Supports: WAV, MP3, M4A, etc.

## 📊 Performance Testing

Both services include:
- ✅ Health check endpoints
- ✅ Error handling and logging
- ✅ Lazy model loading
- ✅ Resource cleanup
- ✅ Lambda-compatible handlers

## 🔧 Configuration

Environment variables:
- `TTS_MODEL_NAME`: Coqui TTS model (default: tts_models/de/thorsten/tacotron2-DCA)
- `WHISPER_MODEL_SIZE`: Whisper model size (default: small)

## 🐳 Docker Commands

```bash
# Build individual services
docker build -t coqui-tts ./coquitts
docker build -t whisper ./whisper

# Run individual containers
docker run -p 8000:8000 coqui-tts
docker run -p 8001:8001 whisper
```

## 📝 Notes

1. **Model Download**: First run will download models (can take time)
2. **Memory Usage**: Both services require significant RAM
3. **Cold Starts**: First request after idle will be slower
4. **File Cleanup**: Temporary files are automatically cleaned up