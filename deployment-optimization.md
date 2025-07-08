# Docker Image Size Optimization Guide

## Current Problem
Your Docker image is **8.5 GB** which exceeds Railway's 4.0 GB limit.

## Major Contributors to Image Size

### 1. PyTorch (2-3 GB)
- `torch==2.7.0` 
- `torchvision==0.22.0`

### 2. Computer Vision Libraries (1-2 GB)
- `opencv-python==4.11.0.86` AND `opencv-python-headless==4.11.0.86` (DUPLICATE!)
- `scikit-image==0.25.2`
- `easyocr==1.7.2`

### 3. AI/ML Frameworks (1-2 GB)
- `transformers==4.49.0`
- `sentence-transformers==3.4.1`
- `onnxruntime==1.21.0`

### 4. Model Files (~200 MB)
- `checkpointN25_.pth.tar`: 175.41 MB
- `covid_chest_xray_model.pth`: 27 MB

## Optimization Strategies

### Option 1: Use CPU-Only PyTorch (Recommended)
```bash
# Replace current requirements.txt with requirements-optimized.txt
cp requirements-optimized.txt requirements.txt
```

**Savings: ~1-2 GB** (CPU versions are much smaller)

### Option 2: Model Download Strategy
Instead of bundling models in the image, download them on startup:

```python
# Add to app.py startup
import os
import requests
from pathlib import Path

def download_model(url, path):
    if not os.path.exists(path):
        print(f"Downloading model to {path}...")
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        response = requests.get(url, stream=True)
        with open(path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"Model downloaded successfully!")

# On startup
download_model(
    "https://your-cloud-storage/checkpointN25_.pth.tar",
    "./agents/image_analysis_agent/skin_lesion_agent/models/checkpointN25_.pth.tar"
)
```

**Savings: ~200 MB**

### Option 3: Remove Duplicate Dependencies
Current duplicates to remove:
- Keep only `opencv-python-headless` (remove `opencv-python`)
- Remove unused document processing libraries
- Remove development tools

### Option 4: Multi-Stage Docker Build
The optimized Dockerfile uses multi-stage builds to:
- Build dependencies in one stage
- Copy only runtime files to final stage
- Remove build tools from final image

## Implementation Steps

### Step 1: Use Optimized Requirements
```bash
# Backup original
cp requirements.txt requirements-original.txt

# Use optimized version
cp requirements-optimized.txt requirements.txt
```

### Step 2: Build with Optimized Dockerfile
```bash
docker build -t medical-ai-optimized .
```

### Step 3: Check New Image Size
```bash
docker images medical-ai-optimized
```

## Expected Results

| Component | Original | Optimized | Savings |
|-----------|----------|-----------|---------|
| PyTorch | ~2.5 GB | ~1.2 GB | ~1.3 GB |
| OpenCV | ~500 MB | ~250 MB | ~250 MB |
| Dependencies | ~1.5 GB | ~800 MB | ~700 MB |
| Model Files | ~200 MB | ~200 MB | 0 MB |
| **Total** | **~8.5 GB** | **~3.5 GB** | **~5 GB** |

## Alternative Deployment Options

### Option A: Use Railway Pro Plan
- Increases image size limit to 8 GB
- **Cost**: $20/month

### Option B: Split into Microservices
- Separate image analysis service
- Main web service
- Deploy each under 4 GB limit

### Option C: Use External Model Hosting
- Host models on Hugging Face Hub
- Download models on first request
- Cache locally in persistent storage

## Quick Fix Commands

```bash
# 1. Use optimized requirements
cp requirements-optimized.txt requirements.txt

# 2. Build optimized image
docker build -t medical-ai-slim .

# 3. Check size
docker images medical-ai-slim

# 4. Test locally
docker run -p 8001:8001 medical-ai-slim
```

## Model Storage Alternatives

### Hugging Face Hub
```python
from huggingface_hub import hf_hub_download

model_path = hf_hub_download(
    repo_id="your-username/medical-models",
    filename="checkpointN25_.pth.tar",
    cache_dir="./models"
)
```

### Google Drive/OneDrive
```python
import gdown

# Download from Google Drive
gdown.download(
    "https://drive.google.com/file/d/FILE_ID/view?usp=sharing",
    "./models/checkpointN25_.pth.tar",
    quiet=False
)
```

This approach should reduce your image from **8.5 GB to ~3.5 GB**, fitting within Railway's 4 GB limit! 