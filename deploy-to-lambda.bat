@echo off
REM AWS Lambda Deployment Script for RT Personality Project (Windows)
REM This script automates the deployment of both Coqui TTS and Whisper services to AWS Lambda

setlocal enabledelayedexpansion

REM Configuration
set AWS_REGION=us-east-1
set DEFAULT_ACCOUNT_ID=637423503101
set COQUITTS_REPO_NAME=personality-projekt-coquitts
set WHISPER_REPO_NAME=personality-projekt-whisper
set LAMBDA_ROLE_NAME=LabRole

echo 🚀 Starting AWS Lambda deployment for RT Personality Project

REM Get current AWS Account ID and verify
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set CURRENT_ACCOUNT_ID=%%i
if "%CURRENT_ACCOUNT_ID%" neq "%DEFAULT_ACCOUNT_ID%" (
    echo ⚠️  Warning: Current AWS account (%CURRENT_ACCOUNT_ID%^) doesn't match expected account (%DEFAULT_ACCOUNT_ID%^)
    echo Proceeding with current account ID...
    set AWS_ACCOUNT_ID=%CURRENT_ACCOUNT_ID%
) else (
    set AWS_ACCOUNT_ID=%DEFAULT_ACCOUNT_ID%
)
echo AWS Account ID: %AWS_ACCOUNT_ID%
echo Region: %AWS_REGION%

REM Check if AWS CLI is configured
echo Checking AWS CLI configuration...
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ❌ AWS CLI is not configured. Please run 'aws configure' first.
    exit /b 1
)
echo ✅ AWS CLI is configured

REM Create ECR repositories
echo 📦 Creating ECR repositories...

REM Check if Coqui TTS repository exists
aws ecr describe-repositories --repository-names %COQUITTS_REPO_NAME% --region %AWS_REGION% >nul 2>&1
if errorlevel 1 (
    aws ecr create-repository --repository-name %COQUITTS_REPO_NAME% --region %AWS_REGION%
    echo ✅ Created ECR repository %COQUITTS_REPO_NAME%
) else (
    echo ✅ ECR repository %COQUITTS_REPO_NAME% already exists
)

REM Check if Whisper repository exists
aws ecr describe-repositories --repository-names %WHISPER_REPO_NAME% --region %AWS_REGION% >nul 2>&1
if errorlevel 1 (
    aws ecr create-repository --repository-name %WHISPER_REPO_NAME% --region %AWS_REGION%
    echo ✅ Created ECR repository %WHISPER_REPO_NAME%
) else (
    echo ✅ ECR repository %WHISPER_REPO_NAME% already exists
)

REM Build and push Docker images
echo 🐳 Building and pushing Docker images...

REM Login to ECR
for /f "tokens=*" %%i in ('aws ecr get-login-password --region %AWS_REGION%') do (
    echo %%i | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
)

REM Build images
echo Building Coqui TTS image...
docker build -t %COQUITTS_REPO_NAME% ./coquitts

echo Building Whisper image...
docker build -t %WHISPER_REPO_NAME% ./whisper

REM Tag images
docker tag %COQUITTS_REPO_NAME%:latest %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%COQUITTS_REPO_NAME%:latest
docker tag %WHISPER_REPO_NAME%:latest %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%WHISPER_REPO_NAME%:latest

REM Push images
echo Pushing Coqui TTS image...
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%COQUITTS_REPO_NAME%:latest

echo Pushing Whisper image...
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%WHISPER_REPO_NAME%:latest

echo ✅ Images pushed successfully

REM Verify IAM role exists
echo 🔐 Verifying Lambda execution role...

aws iam get-role --role-name %LAMBDA_ROLE_NAME% >nul 2>&1
if errorlevel 1 (
    echo ❌ IAM role %LAMBDA_ROLE_NAME% not found!
    echo Please ensure the LabRole exists in your AWS account with Lambda execution permissions.
    exit /b 1
) else (
    echo ✅ IAM role %LAMBDA_ROLE_NAME% exists
)

REM Create Lambda functions
echo ⚡ Creating Lambda functions...

set ROLE_ARN=arn:aws:iam::%AWS_ACCOUNT_ID%:role/%LAMBDA_ROLE_NAME%

REM Create Coqui TTS function
aws lambda get-function --function-name %COQUITTS_REPO_NAME% >nul 2>&1
if errorlevel 1 (
    aws lambda create-function --function-name %COQUITTS_REPO_NAME% --package-type Image --code ImageUri=%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%COQUITTS_REPO_NAME%:latest --role %ROLE_ARN% --timeout 300 --memory-size 2048 --description "Coqui TTS service for personality project"
    echo ✅ Created Lambda function %COQUITTS_REPO_NAME%
) else (
    echo ✅ Lambda function %COQUITTS_REPO_NAME% already exists, updating...
    aws lambda update-function-code --function-name %COQUITTS_REPO_NAME% --image-uri %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%COQUITTS_REPO_NAME%:latest
)

REM Create Whisper function
aws lambda get-function --function-name %WHISPER_REPO_NAME% >nul 2>&1
if errorlevel 1 (
    aws lambda create-function --function-name %WHISPER_REPO_NAME% --package-type Image --code ImageUri=%AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%WHISPER_REPO_NAME%:latest --role %ROLE_ARN% --timeout 300 --memory-size 2048 --description "Whisper transcription service for personality project"
    echo ✅ Created Lambda function %WHISPER_REPO_NAME%
) else (
    echo ✅ Lambda function %WHISPER_REPO_NAME% already exists, updating...
    aws lambda update-function-code --function-name %WHISPER_REPO_NAME% --image-uri %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%WHISPER_REPO_NAME%:latest
)

echo.
echo 🎉 Deployment completed successfully!
echo.
echo Lambda Functions Created:
echo - Coqui TTS: %COQUITTS_REPO_NAME%
echo - Whisper: %WHISPER_REPO_NAME%
echo.
echo You can now:
echo 1. Test the functions in the AWS Lambda console
echo 2. Create API Gateway endpoints to expose HTTP APIs
echo 3. Set up CloudWatch monitoring and logs
echo.
echo Function ARNs:
echo - Coqui TTS: arn:aws:lambda:%AWS_REGION%:%AWS_ACCOUNT_ID%:function:%COQUITTS_REPO_NAME%
echo - Whisper: arn:aws:lambda:%AWS_REGION%:%AWS_ACCOUNT_ID%:function:%WHISPER_REPO_NAME%

pause