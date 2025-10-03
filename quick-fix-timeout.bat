@echo off
REM Quick fix for Lambda timeout issues

setlocal enabledelayedexpansion

set AWS_REGION=us-east-1
set COQUITTS_FUNCTION_NAME=personality-projekt-coquitts
set WHISPER_FUNCTION_NAME=personality-projekt-whisper

echo 🚑 Quick Fix for Lambda Timeout Issues
echo =====================================
echo.

echo 🔧 Step 1: Updating Lambda timeout to 15 minutes (900 seconds)...
aws lambda update-function-configuration --function-name %COQUITTS_FUNCTION_NAME% --timeout 900
aws lambda update-function-configuration --function-name %WHISPER_FUNCTION_NAME% --timeout 900
echo ✅ Timeout updated!

echo.
echo 🚀 Step 2: Increasing memory to 3008 MB (maximum) for better performance...
aws lambda update-function-configuration --function-name %COQUITTS_FUNCTION_NAME% --memory-size 3008
aws lambda update-function-configuration --function-name %WHISPER_FUNCTION_NAME% --memory-size 3008
echo ✅ Memory increased!

echo.
echo 🔥 Step 3: Warming up functions (this will trigger model loading)...
echo This may take 5-10 minutes, please wait...

echo Warming up TTS function...
aws lambda invoke --function-name %COQUITTS_FUNCTION_NAME% --payload "{\"warm_up\": true}" warm_up_tts.json

echo Warming up Whisper function...
aws lambda invoke --function-name %WHISPER_FUNCTION_NAME% --payload "{\"warm_up\": true}" warm_up_whisper.json

echo.
echo ✅ Quick fix applied!
echo.
echo 💡 What was fixed:
echo   - Lambda timeout increased from 5 minutes to 15 minutes
echo   - Memory increased to 3008 MB (more CPU power)
echo   - Functions warmed up (models should now be loaded)
echo.
echo 🧪 You can now test your API endpoints again:
echo   python test_api_endpoints.py
echo.
echo 📊 If you want detailed diagnostics, run:
echo   troubleshoot-lambda.bat

pause