@echo off
REM API Gateway Creation Script for RT Personality Project
REM This script creates REST API endpoints for your Lambda functions

setlocal enabledelayedexpansion

REM Configuration
set AWS_REGION=us-east-1
set DEFAULT_ACCOUNT_ID=637423503101
set COQUITTS_FUNCTION_NAME=personality-projekt-coquitts
set WHISPER_FUNCTION_NAME=personality-projekt-whisper
set API_NAME=personality-projekt-api

echo 🚀 Creating API Gateway for RT Personality Project

REM Get current AWS Account ID
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT_ID=%%i
echo AWS Account ID: %AWS_ACCOUNT_ID%
echo Region: %AWS_REGION%

REM Create REST API
echo 📡 Creating REST API...
for /f "tokens=*" %%i in ('aws apigateway create-rest-api --name %API_NAME% --description "API for Personality Project Lambda functions" --query "id" --output text') do set API_ID=%%i
echo ✅ Created API with ID: %API_ID%

REM Get the root resource ID
for /f "tokens=*" %%i in ('aws apigateway get-resources --rest-api-id %API_ID% --query "items[0].id" --output text') do set ROOT_RESOURCE_ID=%%i
echo Root resource ID: %ROOT_RESOURCE_ID%

REM Create resources for each service
echo 📂 Creating API resources...

REM Create /tts resource
for /f "tokens=*" %%i in ('aws apigateway create-resource --rest-api-id %API_ID% --parent-id %ROOT_RESOURCE_ID% --path-part tts --query "id" --output text') do set TTS_RESOURCE_ID=%%i
echo ✅ Created /tts resource with ID: %TTS_RESOURCE_ID%

REM Create /whisper resource
for /f "tokens=*" %%i in ('aws apigateway create-resource --rest-api-id %API_ID% --parent-id %ROOT_RESOURCE_ID% --path-part whisper --query "id" --output text') do set WHISPER_RESOURCE_ID=%%i
echo ✅ Created /whisper resource with ID: %WHISPER_RESOURCE_ID%

REM Create POST methods
echo 🔧 Creating POST methods...

REM Create POST method for TTS
aws apigateway put-method --rest-api-id %API_ID% --resource-id %TTS_RESOURCE_ID% --http-method POST --authorization-type NONE
echo ✅ Created POST method for /tts

REM Create POST method for Whisper
aws apigateway put-method --rest-api-id %API_ID% --resource-id %WHISPER_RESOURCE_ID% --http-method POST --authorization-type NONE
echo ✅ Created POST method for /whisper

REM Create integrations with Lambda functions
echo 🔗 Creating Lambda integrations...

REM TTS Integration
set TTS_LAMBDA_ARN=arn:aws:lambda:%AWS_REGION%:%AWS_ACCOUNT_ID%:function:%COQUITTS_FUNCTION_NAME%
aws apigateway put-integration --rest-api-id %API_ID% --resource-id %TTS_RESOURCE_ID% --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:%AWS_REGION%:lambda:path/2015-03-31/functions/%TTS_LAMBDA_ARN%/invocations
echo ✅ Created TTS Lambda integration

REM Whisper Integration
set WHISPER_LAMBDA_ARN=arn:aws:lambda:%AWS_REGION%:%AWS_ACCOUNT_ID%:function:%WHISPER_FUNCTION_NAME%
aws apigateway put-integration --rest-api-id %API_ID% --resource-id %WHISPER_RESOURCE_ID% --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:%AWS_REGION%:lambda:path/2015-03-31/functions/%WHISPER_LAMBDA_ARN%/invocations
echo ✅ Created Whisper Lambda integration

REM Add CORS support
echo 🌐 Adding CORS support...

REM Add OPTIONS method for CORS preflight (TTS)
aws apigateway put-method --rest-api-id %API_ID% --resource-id %TTS_RESOURCE_ID% --http-method OPTIONS --authorization-type NONE
aws apigateway put-integration --rest-api-id %API_ID% --resource-id %TTS_RESOURCE_ID% --http-method OPTIONS --type MOCK --request-templates "{\"application/json\": \"{\\\"statusCode\\\": 200}\"}"
aws apigateway put-method-response --rest-api-id %API_ID% --resource-id %TTS_RESOURCE_ID% --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Origin=true"
aws apigateway put-integration-response --rest-api-id %API_ID% --resource-id %TTS_RESOURCE_ID% --http-method OPTIONS --status-code 200 --response-parameters "{\"method.response.header.Access-Control-Allow-Headers\": \"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\",\"method.response.header.Access-Control-Allow-Methods\": \"'POST,OPTIONS'\",\"method.response.header.Access-Control-Allow-Origin\": \"'*'\"}"

REM Add OPTIONS method for CORS preflight (Whisper)
aws apigateway put-method --rest-api-id %API_ID% --resource-id %WHISPER_RESOURCE_ID% --http-method OPTIONS --authorization-type NONE
aws apigateway put-integration --rest-api-id %API_ID% --resource-id %WHISPER_RESOURCE_ID% --http-method OPTIONS --type MOCK --request-templates "{\"application/json\": \"{\\\"statusCode\\\": 200}\"}"
aws apigateway put-method-response --rest-api-id %API_ID% --resource-id %WHISPER_RESOURCE_ID% --http-method OPTIONS --status-code 200 --response-parameters "method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Origin=true"
aws apigateway put-integration-response --rest-api-id %API_ID% --resource-id %WHISPER_RESOURCE_ID% --http-method OPTIONS --status-code 200 --response-parameters "{\"method.response.header.Access-Control-Allow-Headers\": \"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\",\"method.response.header.Access-Control-Allow-Methods\": \"'POST,OPTIONS'\",\"method.response.header.Access-Control-Allow-Origin\": \"'*'\"}"

echo ✅ Added CORS support

REM Grant API Gateway permission to invoke Lambda functions
echo 🔐 Granting API Gateway permissions...

REM Grant permission for TTS function
aws lambda add-permission --function-name %COQUITTS_FUNCTION_NAME% --statement-id api-gateway-invoke-tts --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:%AWS_REGION%:%AWS_ACCOUNT_ID%:%API_ID%/*/POST/tts"

REM Grant permission for Whisper function
aws lambda add-permission --function-name %WHISPER_FUNCTION_NAME% --statement-id api-gateway-invoke-whisper --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn "arn:aws:execute-api:%AWS_REGION%:%AWS_ACCOUNT_ID%:%API_ID%/*/POST/whisper"

echo ✅ Granted API Gateway permissions

REM Deploy the API
echo 🚀 Deploying API...
aws apigateway create-deployment --rest-api-id %API_ID% --stage-name prod --stage-description "Production stage" --description "Initial deployment"
echo ✅ API deployed to production stage

REM Get the API endpoint URL
set API_URL=https://%API_ID%.execute-api.%AWS_REGION%.amazonaws.com/prod
echo.
echo 🎉 API Gateway setup completed successfully!
echo.
echo API Endpoints:
echo - TTS Service: %API_URL%/tts
echo - Whisper Service: %API_URL%/whisper
echo.
echo You can test your endpoints with:
echo curl -X POST %API_URL%/tts -H "Content-Type: application/json" -d "{\"text\": \"Hello world\"}"
echo curl -X POST %API_URL%/whisper -H "Content-Type: application/json" -d "{\"audio_data\": \"base64_encoded_audio\"}"
echo.
echo API Gateway Console: https://%AWS_REGION%.console.aws.amazon.com/apigateway/home?region=%AWS_REGION%#/apis/%API_ID%

pause