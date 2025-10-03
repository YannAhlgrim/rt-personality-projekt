FROM python:3.11-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libsndfile1 \
    libsndfile1-dev \
    gcc \
    g++ \
    make \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip / setuptools / wheel
RUN python -m pip install --upgrade pip setuptools wheel

# Install Python packages separately to isolate issues
RUN pip install --no-cache-dir torch==2.5.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir git+https://github.com/openai/whisper.git
RUN pip install --no-cache-dir flask mangum soundfile

# Copy app code
COPY app /app
WORKDIR /app

# Lambda entrypoint
CMD ["server.lambda_handler"]
