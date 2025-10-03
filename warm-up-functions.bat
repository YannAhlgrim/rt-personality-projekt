@echo off
REM Warm up Lambda functions to pre-load models

setlocal enabledelayedexpansion

set AWS_REGION=us-east-1
set COQUITTS_FUNCTION_NAME=personality-projekt-coquitts
set WHISPER_FUNCTION_NAME=personality-projekt-whisper

echo 🔥 Warming up Lambda Functions
echo ==============================
echo.

echo 🎤 Warming up TTS function (this will load the Coqui TTS model)...
echo This may take 2-5 minutes on first run...

aws lambda invoke ^
    --function-name %COQUITTS_FUNCTION_NAME% ^
    --payload "{\"body\": \"{\\\"text\\\": \\\"Warm up test\\\"}\"}" ^
    --cli-read-timeout 600 ^
    --cli-connect-timeout 60 ^
    tts_warmup_response.json

if exist tts_warmup_response.json (
    echo ✅ TTS function warmed up successfully!
    type tts_warmup_response.json
    echo.
) else (
    echo ❌ TTS warmup may have failed
)

echo.
echo 🎧 Warming up Whisper function (this will load the Whisper model)...
echo This may take 2-5 minutes on first run...

aws lambda invoke ^
    --function-name %WHISPER_FUNCTION_NAME% ^
    --payload "{\"body\": \"{\\\"audio_data\\\": \\\"UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA\\\"}\"}" ^
    --cli-read-timeout 600 ^
    --cli-connect-timeout 60 ^
    whisper_warmup_response.json

if exist whisper_warmup_response.json (
    echo ✅ Whisper function warmed up successfully!
    type whisper_warmup_response.json
    echo.
) else (
    echo ❌ Whisper warmup may have failed
)

echo.
echo 🎉 Warmup complete! Your functions should now respond much faster.
echo 🧪 Test your API endpoints now: python test_api_endpoints.py

pause