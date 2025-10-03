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

## ☁️ AWS Lambda Deployment

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed and running
- AWS account with Lambda and ECR access

### Deploy to AWS Lambda (Container Images)

#### Step 1: Create ECR Repositories
```bash
# Create repositories for both services
aws ecr create-repository --repository-name personality-projekt-coquitts --region us-east-1
aws ecr create-repository --repository-name personality-projekt-whisper --region us-east-1
```

#### Step 2: Build and Push Docker Images
```bash
# Get ECR login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 637423503101.dkr.ecr.us-east-1.amazonaws.com

# Build and tag images
docker build -t personality-projekt-coquitts ./coquitts
docker build -t personality-projekt-whisper ./whisper

docker tag personality-projekt-coquitts:latest 637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-coquitts:latest
docker tag personality-projekt-whisper:latest 637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-whisper:latest

# Push images
docker push 637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-coquitts:latest
docker push 637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-whisper:latest
```

#### Step 3: Create Lambda Functions
```bash
# Create Coqui TTS Lambda function
aws lambda create-function \
    --function-name personality-projekt-coquitts \
    --package-type Image \
    --code ImageUri=637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-coquitts:latest \
    --role arn:aws:iam::637423503101:role/LabRole \
    --timeout 300 \
    --memory-size 2048

# Create Whisper Lambda function
aws lambda create-function \
    --function-name personality-projekt-whisper \
    --package-type Image \
    --code ImageUri=637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-whisper:latest \
    --role arn:aws:iam::637423503101:role/LabRole \
    --timeout 300 \
    --memory-size 2048
```

#### Step 4: Create API Gateway (Optional)
```bash
# Create REST API
aws apigateway create-rest-api --name personality-projekt-api

# Configure resources and methods for /synthesize and /transcribe endpoints
# (Detailed API Gateway configuration would require additional steps)
```

### Alternative: Deploy with AWS SAM

#### Step 1: Update template.yaml
Make sure your `template.yaml` has the correct image URIs:
```yaml
Resources:
  CoquiTTSFunction:
    Type: AWS::Serverless::Function
    Properties:
      PackageType: Image
      ImageUri: 637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-coquitts:latest
      # ... rest of configuration

  WhisperFunction:
    Type: AWS::Serverless::Function
    Properties:
      PackageType: Image
      ImageUri: 637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-whisper:latest
      # ... rest of configuration
```

#### Step 2: Deploy with SAM
```bash
# Build and deploy
sam build
sam deploy --guided

# For subsequent deployments
sam deploy
```

### Update Existing Functions
```bash
# Update function code when you make changes
aws lambda update-function-code \
    --function-name personality-projekt-coquitts \
    --image-uri 637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-coquitts:latest

aws lambda update-function-code \
    --function-name personality-projekt-whisper \
    --image-uri 637423503101.dkr.ecr.us-east-1.amazonaws.com/personality-projekt-whisper:latest
```

### Required IAM Role
This deployment uses the existing `LabRole` which should already have the necessary permissions:
- Lambda execution permissions
- CloudWatch Logs access
- ECR access for pulling container images

Role ARN: `arn:aws:iam::637423503101:role/LabRole`

**Note**: Make sure the `LabRole` exists in your AWS account and has the required Lambda execution permissions.

### � Quick Deployment Scripts

For easier deployment, use the provided scripts:

**Linux/macOS:**
```bash
# Make script executable and run
chmod +x deploy-to-lambda.sh
./deploy-to-lambda.sh
```

**Windows:**
```cmd
# Run the batch script
deploy-to-lambda.bat
```

These scripts will automatically:
- Create ECR repositories
- Build and push Docker images
- Create IAM roles
- Deploy Lambda functions
- Run basic health checks

### �💡 Deployment Tips
- **Image Size**: Lambda container images have a 10GB limit
- **Cold Starts**: First invocation after idle will download models
- **Memory**: Use at least 2GB RAM for both functions
- **Timeout**: Set to 5+ minutes for model loading
- **Environment Variables**: Configure model settings via Lambda environment variables

## 📝 Notes

1. **Model Download**: First run will download models (can take time)
2. **Memory Usage**: Both services require significant RAM
3. **Cold Starts**: First request after idle will be slower
4. **File Cleanup**: Temporary files are automatically cleaned up