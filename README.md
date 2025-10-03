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

#### Step 4: Create API Gateway Endpoints

After deploying your Lambda functions, you can create HTTP endpoints to access them via API Gateway.

##### Option 1: Automated Script (Recommended)
```cmd
# Windows
create-api-gateway.bat

# This script will:
# - Create a REST API with /tts and /whisper endpoints
# - Configure CORS for web browser access
# - Set up proper Lambda integrations
# - Deploy to production stage
# - Display the final endpoint URLs
```

##### Option 2: AWS SAM Template
```bash
# Deploy API Gateway using Infrastructure as Code
sam deploy --template-file api-gateway-template.yaml --stack-name personality-api --capabilities CAPABILITY_IAM
```

##### Option 3: Manual AWS CLI Commands
```bash
# Create REST API
API_ID=$(aws apigateway create-rest-api --name personality-projekt-api --query 'id' --output text)

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query 'items[0].id' --output text)

# Create /tts resource
TTS_RESOURCE_ID=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part tts --query 'id' --output text)

# Create /whisper resource
WHISPER_RESOURCE_ID=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part whisper --query 'id' --output text)

# Create POST methods and integrations
aws apigateway put-method --rest-api-id $API_ID --resource-id $TTS_RESOURCE_ID --http-method POST --authorization-type NONE
aws apigateway put-integration --rest-api-id $API_ID --resource-id $TTS_RESOURCE_ID --http-method POST --type AWS_PROXY --integration-http-method POST --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:637423503101:function:personality-projekt-coquitts/invocations

# Grant API Gateway permissions
aws lambda add-permission --function-name personality-projekt-coquitts --statement-id api-gateway-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com

# Deploy API
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod
```

#### Testing API Endpoints

Once your API Gateway is deployed, you'll get endpoint URLs like:
- **TTS Service**: `https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/tts`
- **Whisper Service**: `https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/whisper`

##### Using the Test Scripts
```cmd
# Windows batch script
test-api-endpoints.bat

# Python test script (more detailed)
python test_api_endpoints.py
```

##### Manual Testing with curl
```bash
# Test TTS endpoint
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hallo, das ist ein Test der Text-zu-Sprache Funktion."}'

# Test Whisper endpoint (with base64 encoded audio)
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/whisper \
  -H "Content-Type: application/json" \
  -d '{"audio_data": "UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA"}'
```

##### API Request/Response Format

**TTS Endpoint** (`/tts`):
```json
// Request
{
  "text": "Your German text to synthesize"
}

// Response
{
  "statusCode": 200,
  "body": "base64_encoded_audio_data"
}
```

**Whisper Endpoint** (`/whisper`):
```json
// Request
{
  "audio_data": "base64_encoded_audio_file"
}

// Response
{
  "statusCode": 200,
  "body": {
    "transcription": "Recognized text from audio"
  }
}
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

## 🌐 API Gateway Integration

After deploying your Lambda functions, you can create HTTP endpoints for easy access from web applications, mobile apps, or other services.

### Available Scripts and Templates

**Automated Deployment:**
- `create-api-gateway.bat` - Windows script to create complete API Gateway setup
- `api-gateway-template.yaml` - SAM template for Infrastructure as Code deployment

**Testing Tools:**
- `test-api-endpoints.bat` - Basic Windows testing script
- `test_api_endpoints.py` - Advanced Python testing with detailed output

### API Endpoints Structure

Once deployed, your API will have these endpoints:
- **Base URL**: `https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod`
- **TTS Endpoint**: `POST /tts` - Convert text to speech
- **Whisper Endpoint**: `POST /whisper` - Transcribe audio to text

### Request/Response Examples

**Text-to-Speech (TTS):**
```bash
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hallo Welt, das ist ein Test."}'
```

**Speech-to-Text (Whisper):**
```bash
curl -X POST https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/whisper \
  -H "Content-Type: application/json" \
  -d '{"audio_data": "base64_encoded_audio_data"}'
```

### Features Included

✅ **CORS Support** - Works with web browsers
✅ **Error Handling** - Proper HTTP status codes
✅ **Lambda Proxy Integration** - Efficient request routing
✅ **Production Deployment** - Ready for live use
✅ **Automated Testing** - Scripts to verify functionality

## 📁 Complete File Structure

```
personality-projekt/
├── coquitts/
│   ├── Dockerfile
│   └── app/
│       ├── lambda_function.py
│       └── server.py
├── whisper/
│   ├── Dockerfile
│   ├── sample.m4a
│   └── app/
│       ├── lambda_function.py
│       └── server.py
├── deploy-to-lambda.bat          # Main Lambda deployment
├── create-api-gateway.bat        # API Gateway creation
├── test-api-endpoints.bat        # Basic endpoint testing
├── test_api_endpoints.py         # Advanced Python testing
├── api-gateway-template.yaml     # SAM template for API Gateway
├── template.yaml                 # SAM template for Lambda
├── docker-compose.yml            # Local development
├── test_services.py              # Local testing
└── README.md
```

## 📝 Notes

1. **Model Download**: First run will download models (can take time)
2. **Memory Usage**: Both services require significant RAM
3. **Cold Starts**: First request after idle will be slower
4. **File Cleanup**: Temporary files are automatically cleaned up
5. **API Gateway**: Use the provided scripts for easy endpoint creation
6. **Testing**: Always test locally before deploying to AWS