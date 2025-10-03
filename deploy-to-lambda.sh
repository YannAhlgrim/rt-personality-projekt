#!/bin/bash

# AWS Lambda Deployment Script for RT Personality Project
# This script automates the deployment of both Coqui TTS and Whisper services to AWS Lambda

set -e

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="637423503101"  # Default account ID, will be verified
COQUITTS_REPO_NAME="personality-projekt-coquitts"
WHISPER_REPO_NAME="personality-projekt-whisper"
LAMBDA_ROLE_NAME="LabRole"

echo "🚀 Starting AWS Lambda deployment for RT Personality Project"

# Verify the account ID matches
CURRENT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ "$CURRENT_ACCOUNT_ID" != "$AWS_ACCOUNT_ID" ]; then
    echo "⚠️  Warning: Current AWS account ($CURRENT_ACCOUNT_ID) doesn't match expected account ($AWS_ACCOUNT_ID)"
    echo "Proceeding with current account ID..."
    AWS_ACCOUNT_ID=$CURRENT_ACCOUNT_ID
fi

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    echo "✅ AWS CLI is configured"
}

# Function to create ECR repositories
create_ecr_repos() {
    echo "📦 Creating ECR repositories..."

    # Create Coqui TTS repository
    if aws ecr describe-repositories --repository-names $COQUITTS_REPO_NAME --region $AWS_REGION > /dev/null 2>&1; then
        echo "✅ ECR repository $COQUITTS_REPO_NAME already exists"
    else
        aws ecr create-repository --repository-name $COQUITTS_REPO_NAME --region $AWS_REGION
        echo "✅ Created ECR repository $COQUITTS_REPO_NAME"
    fi

    # Create Whisper repository
    if aws ecr describe-repositories --repository-names $WHISPER_REPO_NAME --region $AWS_REGION > /dev/null 2>&1; then
        echo "✅ ECR repository $WHISPER_REPO_NAME already exists"
    else
        aws ecr create-repository --repository-name $WHISPER_REPO_NAME --region $AWS_REGION
        echo "✅ Created ECR repository $WHISPER_REPO_NAME"
    fi
}

# Function to build and push Docker images
build_and_push_images() {
    echo "🐳 Building and pushing Docker images..."

    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

    # Build images
    echo "Building Coqui TTS image..."
    docker build -t $COQUITTS_REPO_NAME ./coquitts

    echo "Building Whisper image..."
    docker build -t $WHISPER_REPO_NAME ./whisper

    # Tag images
    docker tag $COQUITTS_REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$COQUITTS_REPO_NAME:latest
    docker tag $WHISPER_REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$WHISPER_REPO_NAME:latest

    # Push images
    echo "Pushing Coqui TTS image..."
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$COQUITTS_REPO_NAME:latest

    echo "Pushing Whisper image..."
    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$WHISPER_REPO_NAME:latest

    echo "✅ Images pushed successfully"
}

# Function to verify IAM role exists
verify_lambda_role() {
    echo "🔐 Verifying Lambda execution role..."

    if aws iam get-role --role-name $LAMBDA_ROLE_NAME > /dev/null 2>&1; then
        echo "✅ IAM role $LAMBDA_ROLE_NAME exists"
    else
        echo "❌ IAM role $LAMBDA_ROLE_NAME not found!"
        echo "Please ensure the LabRole exists in your AWS account with Lambda execution permissions."
        exit 1
    fi
}

# Function to create Lambda functions
create_lambda_functions() {
    echo "⚡ Creating Lambda functions..."

    ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/$LAMBDA_ROLE_NAME"

    # Create Coqui TTS function
    if aws lambda get-function --function-name $COQUITTS_REPO_NAME > /dev/null 2>&1; then
        echo "✅ Lambda function $COQUITTS_REPO_NAME already exists, updating..."
        aws lambda update-function-code \
            --function-name $COQUITTS_REPO_NAME \
            --image-uri $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$COQUITTS_REPO_NAME:latest
    else
        aws lambda create-function \
            --function-name $COQUITTS_REPO_NAME \
            --package-type Image \
            --code ImageUri=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$COQUITTS_REPO_NAME:latest \
            --role $ROLE_ARN \
            --timeout 300 \
            --memory-size 2048 \
            --description "Coqui TTS service for personality project"
        echo "✅ Created Lambda function $COQUITTS_REPO_NAME"
    fi

    # Create Whisper function
    if aws lambda get-function --function-name $WHISPER_REPO_NAME > /dev/null 2>&1; then
        echo "✅ Lambda function $WHISPER_REPO_NAME already exists, updating..."
        aws lambda update-function-code \
            --function-name $WHISPER_REPO_NAME \
            --image-uri $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$WHISPER_REPO_NAME:latest
    else
        aws lambda create-function \
            --function-name $WHISPER_REPO_NAME \
            --package-type Image \
            --code ImageUri=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$WHISPER_REPO_NAME:latest \
            --role $ROLE_ARN \
            --timeout 300 \
            --memory-size 2048 \
            --description "Whisper transcription service for personality project"
        echo "✅ Created Lambda function $WHISPER_REPO_NAME"
    fi
}

# Function to test Lambda functions
test_lambda_functions() {
    echo "🧪 Testing Lambda functions..."

    # Test Coqui TTS health endpoint
    echo "Testing Coqui TTS health check..."
    aws lambda invoke \
        --function-name $COQUITTS_REPO_NAME \
        --payload '{"httpMethod":"GET","path":"/health","headers":{},"body":""}' \
        --cli-binary-format raw-in-base64-out \
        response-coquitts.json

    if grep -q "healthy" response-coquitts.json; then
        echo "✅ Coqui TTS health check passed"
    else
        echo "❌ Coqui TTS health check failed"
        cat response-coquitts.json
    fi

    # Test Whisper health endpoint
    echo "Testing Whisper health check..."
    aws lambda invoke \
        --function-name $WHISPER_REPO_NAME \
        --payload '{"httpMethod":"GET","path":"/health","headers":{},"body":""}' \
        --cli-binary-format raw-in-base64-out \
        response-whisper.json

    if grep -q "healthy" response-whisper.json; then
        echo "✅ Whisper health check passed"
    else
        echo "❌ Whisper health check failed"
        cat response-whisper.json
    fi

    # Clean up test files
    rm -f response-coquitts.json response-whisper.json
}

# Main execution
main() {
    check_aws_cli
    create_ecr_repos
    build_and_push_images
    verify_lambda_role
    create_lambda_functions
    test_lambda_functions

    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "Lambda Functions Created:"
    echo "- Coqui TTS: $COQUITTS_REPO_NAME"
    echo "- Whisper: $WHISPER_REPO_NAME"
    echo ""
    echo "You can now:"
    echo "1. Test the functions in the AWS Lambda console"
    echo "2. Create API Gateway endpoints to expose HTTP APIs"
    echo "3. Set up CloudWatch monitoring and logs"
    echo ""
    echo "Function ARNs:"
    echo "- Coqui TTS: arn:aws:lambda:$AWS_REGION:$AWS_ACCOUNT_ID:function:$COQUITTS_REPO_NAME"
    echo "- Whisper: arn:aws:lambda:$AWS_REGION:$AWS_ACCOUNT_ID:function:$WHISPER_REPO_NAME"
}

# Run main function
main "$@"