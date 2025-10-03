FROM python:3.11-slim

# System dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libsndfile1 \
    libsndfile1-dev \
    espeak-ng \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
RUN pip install --no-cache-dir \
    torch==2.5.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir TTS flask mangum soundfile

# Copy app
COPY app /app
WORKDIR /app

# Lambda entrypoint
CMD ["server.lambda_handler"]
