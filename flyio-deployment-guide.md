# Fly.io Deployment Guide for Medical AI Application

## 🚀 Deploy Your Medical AI App to Fly.io

This guide helps you deploy your optimized medical AI application to Fly.io with a Docker image under 4GB.

## Prerequisites

### 1. Install Fly.io CLI
```bash
# macOS
brew install flyctl

# Linux
curl -L https://fly.io/install.sh | sh

# Windows
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

### 2. Sign Up and Login
```bash
flyctl auth signup  # Create account
flyctl auth login   # Login to existing account
```

## 📦 Image Size Optimization

Your original Docker image was **8.5 GB** - too large for most platforms. Here's how we optimized it:

### Optimizations Applied:
- ✅ **CPU-only PyTorch**: Reduced from 2.5GB to 1.2GB
- ✅ **Removed duplicate OpenCV**: Saved 250MB
- ✅ **Multi-stage Docker build**: Removed build tools
- ✅ **Optimized dependencies**: Kept only essential packages
- ✅ **Better .dockerignore**: Excluded unnecessary files

**Result**: ~8.5GB → ~3.5GB (fits everywhere!)

## 🔧 Quick Deployment

### Option 1: Automated Script
```bash
# Make script executable
chmod +x deploy-flyio.sh

# Run automated deployment
./deploy-flyio.sh
```

### Option 2: Manual Steps

#### Step 1: Optimize Dependencies
```bash
# Backup original requirements
cp requirements.txt requirements-original.txt

# Use optimized requirements
cp requirements-optimized.txt requirements.txt
```

#### Step 2: Initialize Fly.io App
```bash
# Create and configure app
flyctl launch --no-deploy
```

#### Step 3: Set Environment Variables
```bash
# Required API keys
flyctl secrets set OPENROUTER_API_KEY=your_openrouter_key
flyctl secrets set QDRANT_URL=your_qdrant_url
flyctl secrets set QDRANT_API_KEY=your_qdrant_key
flyctl secrets set ELEVEN_LABS_API_KEY=your_elevenlabs_key
flyctl secrets set ELEVEN_LABS_VOICE_ID=your_voice_id
flyctl secrets set TAVILY_API_KEY=your_tavily_key
flyctl secrets set HUGGINGFACE_TOKEN=your_hf_token
```

#### Step 4: Create Persistent Storage
```bash
# Create volumes for data persistence
flyctl volumes create medical_ai_data --region ord --size 1
flyctl volumes create medical_ai_uploads --region ord --size 2
```

#### Step 5: Deploy Application
```bash
# Deploy with remote build (recommended for large images)
flyctl deploy --remote-only
```

## 📋 Fly.io Configuration (fly.toml)

```toml
app = "medical-ai-agentic"
primary_region = "ord"

[build]

[env]
  PORT = "8001"
  PYTHONUNBUFFERED = "1"

[http_service]
  internal_port = 8001
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0

[[http_service.checks]]
  interval = "15s"
  timeout = "2s"
  grace_period = "5s"
  method = "get"
  path = "/health"
  protocol = "http"

[http_service.concurrency]
  type = "connections"
  hard_limit = 50
  soft_limit = 25

[[vm]]
  memory = '2gb'
  cpu_kind = 'shared'
  cpus = 2

[[mounts]]
  source = "medical_ai_data"
  destination = "/app/data"
  initial_size = "1gb"

[[mounts]]
  source = "medical_ai_uploads"
  destination = "/app/uploads"
  initial_size = "2gb"
```

## 🔍 Monitoring and Management

### Check Application Status
```bash
flyctl status
flyctl logs
flyctl info
```

### Scale Application
```bash
# Scale to 2 instances
flyctl scale count 2

# Scale memory
flyctl scale memory 4gb
```

### Access Application
```bash
# SSH into running instance
flyctl ssh console

# Open in browser
flyctl open

# View dashboard
flyctl dashboard
```

## 💰 Cost Optimization

### Fly.io Pricing (as of 2024):
- **Shared CPU**: $0.0000022/second (~$5.7/month for 1GB RAM)
- **Persistent Storage**: $0.15/GB/month
- **Outbound Transfer**: $0.02/GB

### Money-Saving Tips:
1. **Auto-stop machines**: Enabled in config (saves money when idle)
2. **Shared CPU**: Cheaper than dedicated
3. **Right-size resources**: Start with 2GB RAM, scale if needed
4. **Use regions wisely**: Choose closest to users

## 🔒 Security Best Practices

### 1. Environment Variables
- Never commit API keys to git
- Use `flyctl secrets` for sensitive data
- Rotate keys regularly

### 2. Docker Security
- Non-root user in container
- Health checks enabled
- Minimal base image (python:3.11-slim)

### 3. Network Security
- HTTPS enforced
- Rate limiting configured
- Health check endpoints

## 🚨 Troubleshooting

### Common Issues:

#### 1. Image Too Large
```bash
# Check image size
docker images medical-ai-optimized

# If still too large, try:
# - Remove more dependencies
# - Use alpine base image
# - Exclude model files, download at runtime
```

#### 2. Out of Memory
```bash
# Increase memory allocation
flyctl scale memory 4gb
```

#### 3. Application Won't Start
```bash
# Check logs
flyctl logs

# Check health endpoint
curl https://your-app.fly.dev/health
```

#### 4. Environment Variables Missing
```bash
# List current secrets
flyctl secrets list

# Set missing variables
flyctl secrets set KEY=value
```

## 🎯 Performance Optimization

### 1. CPU vs GPU
- **Current**: CPU-only PyTorch (smaller, cheaper)
- **Upgrade**: GPU machines for faster inference (more expensive)

### 2. Memory Usage
- **Monitor**: `flyctl metrics`
- **Optimize**: Use memory profiling tools
- **Scale**: Increase RAM if needed

### 3. Database Performance
- **Qdrant**: Use cloud-hosted version
- **Caching**: Implement Redis if needed
- **Connection pooling**: For database connections

## 📊 Expected Performance

### Image Analysis:
- **Brain Tumor**: ~2-3 seconds
- **Chest X-ray**: ~1-2 seconds  
- **Skin Lesion**: ~3-5 seconds

### Text Processing:
- **Chat responses**: ~1-2 seconds
- **RAG queries**: ~2-4 seconds
- **Web search**: ~3-5 seconds

## 🔄 CI/CD Pipeline

### GitHub Actions Example:
```yaml
name: Deploy to Fly.io

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## 🌐 Custom Domain

### Add Custom Domain:
```bash
# Add domain
flyctl certs create yourdomain.com

# Add DNS record
# A record: yourdomain.com -> your-app.fly.dev
```

## 📈 Scaling Strategies

### 1. Horizontal Scaling
```bash
# Add more instances
flyctl scale count 3

# Different regions
flyctl regions add iad lhr
```

### 2. Vertical Scaling
```bash
# More CPU/memory
flyctl scale memory 4gb
flyctl scale count 2
```

### 3. Auto-scaling
```bash
# Set in fly.toml
[http_service.concurrency]
  type = "requests"
  hard_limit = 100
  soft_limit = 50
```

## 🎉 Success Checklist

After deployment, verify:

- [ ] Application loads at https://your-app.fly.dev
- [ ] Health check returns 200: `/health`
- [ ] Chat interface works
- [ ] Image upload works
- [ ] Speech features work
- [ ] All environment variables set
- [ ] Persistent storage mounted
- [ ] Logs show no errors
- [ ] Performance is acceptable

## 📞 Support

### Fly.io Community:
- **Discord**: https://fly.io/discord
- **Forum**: https://community.fly.io
- **Docs**: https://fly.io/docs

### Application Support:
- **GitHub Issues**: Create issues for bugs
- **Logs**: `flyctl logs` for debugging
- **SSH Access**: `flyctl ssh console`

---

🚀 **Your medical AI application is now flying on Fly.io!** 

Monitor usage, optimize performance, and scale as needed. The optimized Docker image ensures fast deployments and cost-effective hosting. 