# PowerShell script for Fly.io deployment on Windows
# Deploy Medical AI Application to Fly.io

Write-Host "🚀 Starting Fly.io Deployment Process..." -ForegroundColor Green
Write-Host "================================================"

# Check if flyctl is installed
if (!(Get-Command flyctl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ flyctl is not installed!" -ForegroundColor Red
    Write-Host "Please install it from: https://fly.io/docs/hands-on/install-flyctl/" -ForegroundColor Yellow
    Write-Host "Or run: powershell -Command 'iwr https://fly.io/install.ps1 -useb | iex'" -ForegroundColor Yellow
    exit 1
}

# Check if user is logged in
try {
    flyctl auth whoami | Out-Null
    Write-Host "✅ Fly.io CLI is ready" -ForegroundColor Green
}
catch {
    Write-Host "❌ You are not logged in to Fly.io!" -ForegroundColor Red
    Write-Host "Please run: flyctl auth login" -ForegroundColor Yellow
    exit 1
}

# Step 1: Backup and optimize requirements
Write-Host "📁 Backing up original requirements.txt..." -ForegroundColor Blue
if (Test-Path "requirements.txt") {
    Copy-Item "requirements.txt" "requirements-original.txt"
    Write-Host "✅ Original requirements backed up" -ForegroundColor Green
}
else {
    Write-Host "❌ requirements.txt not found!" -ForegroundColor Red
    exit 1
}

Write-Host "🔄 Applying optimized requirements..." -ForegroundColor Blue
if (Test-Path "requirements-optimized.txt") {
    Copy-Item "requirements-optimized.txt" "requirements.txt"
    Write-Host "✅ Optimized requirements applied" -ForegroundColor Green
}
else {
    Write-Host "❌ requirements-optimized.txt not found!" -ForegroundColor Red
    exit 1
}

# Step 2: Set up environment variables
Write-Host "🔧 Setting up environment variables..." -ForegroundColor Blue
Write-Host ""
Write-Host "Required variables:" -ForegroundColor Yellow
Write-Host "flyctl secrets set OPENROUTER_API_KEY=your_openrouter_key"
Write-Host "flyctl secrets set QDRANT_URL=your_qdrant_url"
Write-Host "flyctl secrets set QDRANT_API_KEY=your_qdrant_key"
Write-Host "flyctl secrets set ELEVEN_LABS_API_KEY=your_elevenlabs_key"
Write-Host "flyctl secrets set ELEVEN_LABS_VOICE_ID=your_voice_id"
Write-Host "flyctl secrets set TAVILY_API_KEY=your_tavily_key"
Write-Host "flyctl secrets set HUGGINGFACE_TOKEN=your_hf_token"
Write-Host ""
$envVarsSet = Read-Host "Have you set all environment variables? (y/n)"
if ($envVarsSet -ne "y" -and $envVarsSet -ne "Y") {
    Write-Host "Please set the environment variables first, then run this script again." -ForegroundColor Yellow
    exit 1
}

# Step 3: Create volumes for persistent storage
Write-Host "💾 Creating persistent volumes..." -ForegroundColor Blue
try {
    flyctl volumes create medical_ai_data --region ord --size 1 --yes
    Write-Host "✅ Volume medical_ai_data created" -ForegroundColor Green
}
catch {
    Write-Host "Volume medical_ai_data might already exist" -ForegroundColor Yellow
}

try {
    flyctl volumes create medical_ai_uploads --region ord --size 2 --yes
    Write-Host "✅ Volume medical_ai_uploads created" -ForegroundColor Green
}
catch {
    Write-Host "Volume medical_ai_uploads might already exist" -ForegroundColor Yellow
}

# Step 4: Deploy the application
Write-Host "🚀 Deploying to Fly.io..." -ForegroundColor Blue
try {
    flyctl deploy --remote-only --no-cache
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Deployment failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Show application info
Write-Host "📊 Application status:" -ForegroundColor Blue
flyctl status

Write-Host "🌐 Getting application URL..." -ForegroundColor Blue
try {
    $appInfo = flyctl info --json | ConvertFrom-Json
    $appUrl = $appInfo.hostname
    if ($appUrl) {
        Write-Host "✅ Application deployed at: https://$appUrl" -ForegroundColor Green
        Write-Host "🔗 Health check: https://$appUrl/health" -ForegroundColor Cyan
    }
    else {
        Write-Host "❌ Could not retrieve application URL" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Could not retrieve application URL" -ForegroundColor Red
}

# Step 6: Show logs
Write-Host "📝 Recent logs:" -ForegroundColor Blue
flyctl logs --lines 20

Write-Host "================================================"
Write-Host "🎉 Fly.io deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "• View logs: flyctl logs"
Write-Host "• Check status: flyctl status"
Write-Host "• Scale app: flyctl scale count 2"
Write-Host "• Open dashboard: flyctl dashboard"
Write-Host "• SSH into app: flyctl ssh console"
Write-Host ""
Write-Host "Monitor your app at: https://fly.io/dashboard" -ForegroundColor Cyan
Write-Host "================================================" 