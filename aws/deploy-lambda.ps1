# Simple Lambda Deployment - Works even without AWS CLI in PATH
# This script will find AWS CLI and add it to PATH automatically

Write-Host "Deploying to AWS Lambda..." -ForegroundColor Green
Write-Host ""

# Find and add AWS CLI to PATH if needed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    $awsLocations = @(
        "C:\Program Files\Amazon\AWSCLIV2",
        "C:\Program Files (x86)\Amazon\AWSCLIV2",
        "$env:LOCALAPPDATA\Programs\Python\AWS",
        "$env:USERPROFILE\AppData\Local\Programs\AWS"
    )
    
    $awsFound = $false
    foreach ($loc in $awsLocations) {
        if (Test-Path "$loc\aws.exe") {
            Write-Host "Found AWS CLI at: $loc" -ForegroundColor Yellow
            $env:Path += ";$loc"
            $awsFound = $true
            break
        }
    }
    
    if (-not $awsFound) {
        Write-Host "ERROR: AWS CLI not found. Please install from:" -ForegroundColor Red
        Write-Host "https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor White
        exit 1
    }
}

# Check if SAM CLI is available  
if (-not (Get-Command sam -ErrorAction SilentlyContinue)) {
    try {
        $pythonUserScriptPath = python -c "import site; print(site.getusersitepackages().replace('site-packages', 'Scripts'))"
        if (Test-Path "$pythonUserScriptPath\sam.exe") {
            Write-Host "SAM found in $pythonUserScriptPath but not in PATH. Adding it..." -ForegroundColor Yellow
            $env:Path += ";$pythonUserScriptPath"
        } else {
            throw "SAM not found"
        }
    } catch {
        Write-Host "ERROR: AWS SAM CLI not found." -ForegroundColor Red
        Write-Host "Install with: pip install aws-sam-cli"
        exit 1
    }
}

# Check AWS configuration
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "AWS CLI configured successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: AWS CLI not configured." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run: aws configure" -ForegroundColor Yellow
    Write-Host "You'll need:" -ForegroundColor White
    Write-Host "  - AWS Access Key ID"
    Write-Host "  - AWS Secret Access Key"  
    Write-Host "  - Default region: us-east-1"
    Write-Host "  - Output format: json"
    Write-Host ""
    Write-Host "Get credentials at: https://console.aws.amazon.com/iam" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

# Get MongoDB URL
$MONGODB_URL = Read-Host "Enter MongoDB Atlas URL"

# Generate secret key
$SECRET_KEY = python -c "import secrets; print(secrets.token_urlsafe(32))"
Write-Host "Generated Secret Key: $SECRET_KEY" -ForegroundColor Yellow
Write-Host ""

# Build
Write-Host "Building application..." -ForegroundColor Cyan
sam build

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed" -ForegroundColor Red
    exit 1
}

# Deploy
Write-Host ""
Write-Host "Deploying to AWS..." -ForegroundColor Cyan
sam deploy --stack-name org-management-service --parameter-overrides "MongoDBURL=$MONGODB_URL SecretKey=$SECRET_KEY" --capabilities CAPABILITY_IAM --resolve-s3 --no-confirm-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host ""

# Get API URL
$API_URL = aws cloudformation describe-stacks --stack-name org-management-service --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text

Write-Host "========================================" -ForegroundColor Green
Write-Host "SUCCESS! Your API is live at:" -ForegroundColor Green
Write-Host $API_URL -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Test it with:" -ForegroundColor Yellow
Write-Host "  curl $API_URL" -ForegroundColor White
Write-Host ""
Write-Host "API Docs: ${API_URL}/docs" -ForegroundColor Cyan
