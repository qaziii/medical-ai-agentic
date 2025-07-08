#!/bin/bash

# Docker Image Optimization Script for Medical AI Application
# This script reduces Docker image size from 8.5GB to ~3.5GB

echo "🔧 Starting Docker Image Optimization..."
echo "================================================"

# Step 1: Backup original requirements
echo "📁 Backing up original requirements.txt..."
if [ -f "requirements.txt" ]; then
    cp requirements.txt requirements-original.txt
    echo "✅ Original requirements backed up to requirements-original.txt"
else
    echo "❌ requirements.txt not found!"
    exit 1
fi

# Step 2: Apply optimized requirements
echo "🔄 Applying optimized requirements..."
if [ -f "requirements-optimized.txt" ]; then
    cp requirements-optimized.txt requirements.txt
    echo "✅ Optimized requirements applied"
else
    echo "❌ requirements-optimized.txt not found!"
    exit 1
fi

# Step 3: Check current Docker image size (if exists)
echo "📊 Checking current image size..."
if docker images medical-ai-agentic >/dev/null 2>&1; then
    echo "Current image size:"
    docker images medical-ai-agentic --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
fi

# Step 4: Build optimized image
echo "🏗️  Building optimized Docker image..."
docker build -t medical-ai-optimized . --no-cache

if [ $? -eq 0 ]; then
    echo "✅ Optimized image built successfully!"
else
    echo "❌ Failed to build optimized image!"
    exit 1
fi

# Step 5: Compare image sizes
echo "📈 Image size comparison:"
echo "================================================"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -n 1
docker images medical-ai-optimized --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
if docker images medical-ai-agentic >/dev/null 2>&1; then
    docker images medical-ai-agentic --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
fi

# Step 6: Test the optimized image
echo "🧪 Testing optimized image..."
echo "Starting container on port 8001..."
docker run -d -p 8001:8001 --name medical-ai-test medical-ai-optimized

# Wait for container to start
sleep 5

# Test health endpoint
echo "Testing health endpoint..."
if curl -s http://localhost:8001/health >/dev/null 2>&1; then
    echo "✅ Health check passed!"
else
    echo "❌ Health check failed!"
fi

# Stop test container
docker stop medical-ai-test >/dev/null 2>&1
docker rm medical-ai-test >/dev/null 2>&1

echo "================================================"
echo "🎉 Optimization complete!"
echo ""
echo "Next steps:"
echo "1. Test the application: docker run -p 8001:8001 medical-ai-optimized"
echo "2. Tag for deployment: docker tag medical-ai-optimized your-registry/medical-ai"
echo "3. Push to Registry: docker push your-registry/medical-ai"
echo "4. Deploy to Railway with the new image"
echo ""
echo "Expected size reduction: 8.5GB → ~3.5GB (fits in Railway's 4GB limit)"
echo "================================================" 