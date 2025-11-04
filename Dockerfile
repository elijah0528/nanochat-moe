FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

# Install Python 3.10
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install uv package manager
RUN pip3 install --no-cache-dir uv

# Set working directory
WORKDIR /app

# Copy dependency files first for better Docker layer caching
COPY pyproject.toml uv.lock ./

# Install dependencies with GPU PyTorch for CUDA 12.8
RUN uv sync --extra gpu --no-dev

# Copy application code
COPY nanochat/ nanochat/
COPY scripts/ scripts/
COPY tasks/ tasks/
COPY rustbpe/ rustbpe/

EXPOSE 8000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Run the web chat server with 8 GPUs
# Binds to 0.0.0.0 to accept external connections
CMD ["uv", "run", "python", "-m", "scripts.chat_web", "--num-gpus", "8", "--host", "0.0.0.0", "--port", "8000"]