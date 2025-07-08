#!/bin/bash

# Fly.io Deployment Script for Medical AI Application
# This script optimizes and deploys to Fly.io with proper configuration

echo "🚀 Starting Fly.io Deployment Process..."
echo "================================================"

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo "❌ flyctl is not installed!"
    echo "Please install it from: https://fly.io/docs/hands-on/install-flyctl/"
    exit 1
fi

# Check if user is logged in
if ! flyctl auth whoami &> /dev/null; then
    echo "❌ You are not logged in to Fly.io!"
    echo "Please run: flyctl auth login"
    exit 1
fi

echo "✅ Fly.io CLI is ready"

# Step 1: Backup and optimize requirements
echo "📁 Backing up original requirements.txt..."
if [ -f "requirements.txt" ]; then
    cp requirements.txt requirements-original.txt
    echo "✅ Original requirements backed up"
else
    echo "❌ requirements.txt not found!"
    exit 1
fi

echo "🔄 Applying optimized requirements..."
if [ -f "requirements-optimized.txt" ]; then
    cp requirements-optimized.txt requirements.txt
    echo "✅ Optimized requirements applied"
else
    echo "❌ requirements-optimized.txt not found!"
    exit 1
fi

# Step 2: Set up environment variables
echo "🔧 Setting up environment variables..."
echo "Please set your environment variables using flyctl:"
echo ""
echo "Required variables:"
echo "flyctl secrets set OPENROUTER_API_KEY=your_openrouter_key"
echo "flyctl secrets set QDRANT_URL=your_qdrant_url"
echo "flyctl secrets set QDRANT_API_KEY=your_qdrant_key"
echo "flyctl secrets set ELEVEN_LABS_API_KEY=your_elevenlabs_key"
echo "flyctl secrets set ELEVEN_LABS_VOICE_ID=your_voice_id"
echo "flyctl secrets set TAVILY_API_KEY=your_tavily_key"
echo "flyctl secrets set HUGGINGFACE_TOKEN=your_hf_token"
echo ""
read -p "Have you set all environment variables? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please set the environment variables first, then run this script again."
    exit 1
fi

# Step 3: Create volumes for persistent storage
echo "💾 Creating persistent volumes..."
flyctl volumes create medical_ai_data --region ord --size 1 --yes || echo "Volume medical_ai_data might already exist"
flyctl volumes create medical_ai_uploads --region ord --size 2 --yes || echo "Volume medical_ai_uploads might already exist"

# Step 4: Deploy the application
echo "🚀 Deploying to Fly.io..."
flyctl deploy --remote-only --no-cache

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
else
    echo "❌ Deployment failed!"
    exit 1
fi

# Step 5: Show application info
echo "📊 Application status:"
flyctl status

echo "🌐 Getting application URL..."
APP_URL=$(flyctl info --json | jq -r '.hostname')
if [ "$APP_URL" != "null" ]; then
    echo "✅ Application deployed at: https://$APP_URL"
    echo "🔗 Health check: https://$APP_URL/health"
else
    echo "❌ Could not retrieve application URL"
fi

# Step 6: Show logs
echo "📝 Recent logs:"
flyctl logs --lines 20

echo "================================================"
echo "🎉 Fly.io deployment complete!"
echo ""
echo "Useful commands:"
echo "• View logs: flyctl logs"
echo "• Check status: flyctl status"
echo "• Scale app: flyctl scale count 2"
echo "• Open dashboard: flyctl dashboard"
echo "• SSH into app: flyctl ssh console"
echo ""
echo "Monitor your app at: https://fly.io/dashboard"
echo "================================================" 