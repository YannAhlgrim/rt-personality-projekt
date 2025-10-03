@echo off
REM Troubleshooting script for Lambda timeout issues

setlocal enabledelayedexpansion

set AWS_REGION=us-east-1
set COQUITTS_FUNCTION_NAME=personality-projekt-coquitts
set WHISPER_FUNCTION_NAME=personality-projekt-whisper

echo 🔍 Troubleshooting Lambda timeout issues
echo.

REM Check Lambda function configuration
echo 📊 Checking Lambda function configurations...
echo.

echo Coqui TTS Function Configuration:
aws lambda get-function-configuration --function-name %COQUITTS_FUNCTION_NAME% --query "{Timeout:Timeout,MemorySize:MemorySize,State:State,LastUpdateStatus:LastUpdateStatus}" --output table

echo.
echo Whisper Function Configuration:
aws lambda get-function-configuration --function-name %WHISPER_FUNCTION_NAME% --query "{Timeout:Timeout,MemorySize:MemorySize,State:State,LastUpdateStatus:LastUpdateStatus}" --output table

echo.
echo 🔧 Recommended fixes for timeout issues:
echo.
echo 1. Increase Lambda timeout to maximum (15 minutes):
echo    aws lambda update-function-configuration --function-name %COQUITTS_FUNCTION_NAME% --timeout 900
echo    aws lambda update-function-configuration --function-name %WHISPER_FUNCTION_NAME% --timeout 900
echo.
echo 2. Increase memory allocation (improves CPU performance):
echo    aws lambda update-function-configuration --function-name %COQUITTS_FUNCTION_NAME% --memory-size 3008
echo    aws lambda update-function-configuration --function-name %WHISPER_FUNCTION_NAME% --memory-size 3008
echo.
echo 3. Warm up the functions (pre-load models):
echo    aws lambda invoke --function-name %COQUITTS_FUNCTION_NAME% --payload "{\"warm_up\": true}" warm_up_tts_response.json
echo    aws lambda invoke --function-name %WHISPER_FUNCTION_NAME% --payload "{\"warm_up\": true}" warm_up_whisper_response.json
echo.

REM Check recent CloudWatch logs
echo 📝 Checking recent CloudWatch logs for errors...
echo.
echo TTS Function Logs (last 10 minutes):
aws logs filter-log-events --log-group-name "/aws/lambda/%COQUITTS_FUNCTION_NAME%" --start-time %~1 --query "events[*].[timestamp,message]" --output table

echo.
echo Whisper Function Logs (last 10 minutes):
aws logs filter-log-events --log-group-name "/aws/lambda/%WHISPER_FUNCTION_NAME%" --start-time %~1 --query "events[*].[timestamp,message]" --output table

echo.
echo 🚀 Would you like to apply the recommended fixes? (Y/N)
set /p APPLY_FIXES=

if /i "%APPLY_FIXES%"=="Y" (
    echo.
    echo 🔧 Applying fixes...

    echo Updating TTS function timeout and memory...
    aws lambda update-function-configuration --function-name %COQUITTS_FUNCTION_NAME% --timeout 900 --memory-size 3008

    echo Updating Whisper function timeout and memory...
    aws lambda update-function-configuration --function-name %WHISPER_FUNCTION_NAME% --timeout 900 --memory-size 3008

    echo.
    echo ✅ Configuration updated!
    echo 🔥 Warming up functions...

    echo Warming up TTS function...
    aws lambda invoke --function-name %COQUITTS_FUNCTION_NAME% --payload "{\"warm_up\": true}" warm_up_tts_response.json

    echo Warming up Whisper function...
    aws lambda invoke --function-name %WHISPER_FUNCTION_NAME% --payload "{\"warm_up\": true}" warm_up_whisper_response.json

    echo.
    echo ✅ Functions warmed up! You can now test the API endpoints again.
    echo.
    echo 💡 Note: For production use, consider:
    echo    - Using provisioned concurrency to keep functions warm
    echo    - Implementing model caching strategies
    echo    - Using smaller/faster models for better response times
)

pause