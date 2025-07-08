# Multi-stage build optimized for Fly.io with uv for fast installs
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies for building
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast package installation
RUN pip install uv

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Use uv to install dependencies (much faster than pip)
RUN uv venv /opt/venv && \
    . /opt/venv/bin/activate && \
    uv pip install --no-cache -r requirements.txt

# Production stage
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install only essential runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
    # OpenCV minimal dependencies
    libgl1-mesa-glx \
    libglib2.0-0 \
    libgomp1 \
    # Image processing dependencies
    libpng16-16 \
    libjpeg62-turbo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY . .

# Create necessary directories (storage will be mounted as a volume)
RUN mkdir -p storage/uploads/backend storage/uploads/frontend storage/uploads/skin_lesion_output storage/uploads/speech storage/data

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PORT=8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:$PORT/health || exit 1

# Expose port
EXPOSE $PORT

# Run the application
CMD ["python", "app.py"]