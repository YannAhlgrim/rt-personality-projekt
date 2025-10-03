@echo off
REM Test script for API Gateway endpoints
REM Replace YOUR_API_ID with your actual API Gateway ID

setlocal enabledelayedexpansion

set AWS_REGION=us-east-1
set API_ID=p97ur8duia
set API_URL=https://%API_ID%.execute-api.%AWS_REGION%.amazonaws.com/prod

echo 🧪 Testing API Gateway endpoints for RT Personality Project
echo API URL: %API_URL%
echo.

REM Test TTS endpoint
echo Testing TTS endpoint...
echo Request: POST %API_URL%/tts
curl -X POST %API_URL%/tts ^
  -H "Content-Type: application/json" ^
  -d "{\"text\": \"Hello, this is a test of the text to speech service.\"}" ^
  --verbose
echo.
echo.

REM Test Whisper endpoint (you'll need to provide actual audio data)
echo Testing Whisper endpoint...
echo Request: POST %API_URL%/whisper
curl -X POST %API_URL%/whisper ^
  -H "Content-Type: application/json" ^
  -d "{\"audio_data\": \"UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA\"}" ^
  --verbose
echo.

pause