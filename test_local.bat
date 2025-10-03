@echo off
echo 🚀 Starting Local Lambda Testing Environment...

echo.
echo 📦 Building and starting services with Docker Compose...
docker-compose up --build -d

echo.
echo ⏳ Waiting for services to start...
timeout /t 10 /nobreak

echo.
echo 🧪 Running service tests...
python test_services.py

echo.
echo 📊 Service Status:
echo Coqui TTS Health:
curl -s http://localhost:8000/health
echo.
echo Whisper Health:
curl -s http://localhost:8001/health

echo.
echo 📝 To test manually:
echo   - Coqui TTS: POST http://localhost:8000/synthesize
echo   - Whisper: POST http://localhost:8001/transcribe
echo   - Health checks: GET http://localhost:8000/health and http://localhost:8001/health

echo.
echo 🛑 To stop services: docker-compose down
pause