# Manual Lambda Deployment Script (No SAM Required)
# This script creates a deployment package and uploads directly to AWS Lambda

Write-Host "🚀 Manual Lambda Deployment (No SAM CLI needed)" -ForegroundColor Green
Write-Host ""

# Check AWS CLI
try {
    aws sts get-caller-identity | Out-Null
    Write-Host "✅ AWS CLI configured" -ForegroundColor Green
}
catch {
    Write-Host "❌ AWS CLI not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Configuration
$FUNCTION_NAME = "org-management-api"
$REGION = "us-east-1"
$RUNTIME = "python3.11"
$HANDLER = "app.lambda_handler.handler"
$ROLE_NAME = "lambda-org-management-role"

# Get inputs
$MONGODB_URL = Read-Host "Enter MongoDB Atlas URL"
$SECRET_KEY = python -c "import secrets; print(secrets.token_urlsafe(32))"
Write-Host "Generated Secret Key: $SECRET_KEY" -ForegroundColor Yellow
Write-Host ""

# Step 1: Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Cyan

# Create temp directory
if (Test-Path "lambda-package") { Remove-Item -Recurse -Force lambda-package }
New-Item -ItemType Directory -Path lambda-package | Out-Null

# Install dependencies
Write-Host "  Installing dependencies..." -ForegroundColor Gray
pip install -r requirements.txt -t lambda-package --quiet

# Copy app code
Write-Host "  Copying application code..." -ForegroundColor Gray
Copy-Item -Recurse app lambda-package/
Copy-Item .env lambda-package/ -ErrorAction SilentlyContinue

# Create ZIP
Write-Host "  Creating ZIP file..." -ForegroundColor Gray
cd lambda-package
Compress-Archive -Path * -DestinationPath ../lambda-deployment.zip -Force
cd ..

Write-Host "✅ Deployment package created: lambda-deployment.zip" -ForegroundColor Green
Write-Host "   Size: $((Get-Item lambda-deployment.zip).Length / 1MB) MB" -ForegroundColor Gray
Write-Host ""

# Step 2: Create IAM role (if doesn't exist)
Write-Host "🔐 Setting up IAM role..." -ForegroundColor Cyan

$roleExists = aws iam get-role --role-name $ROLE_NAME 2>$null
if (-not $roleExists) {
    Write-Host "  Creating Lambda execution role..." -ForegroundColor Gray
    
    # Create trust policy
    $trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@
    $trustPolicy | Out-File -FilePath trust-policy.json -Encoding utf8
    
    aws iam create-role `
        --role-name $ROLE_NAME `
        --assume-role-policy-document file://trust-policy.json | Out-Null
    
    # Attach basic execution policy
    aws iam attach-role-policy `
        --role-name $ROLE_NAME `
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole | Out-Null
    
    Write-Host "  Waiting for role to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    
    Remove-Item trust-policy.json
}

$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$ROLE_ARN = "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
Write-Host "✅ IAM role ready: $ROLE_NAME" -ForegroundColor Green
Write-Host ""

# Step 3: Create or update Lambda function
Write-Host "☁️  Deploying to Lambda..." -ForegroundColor Cyan

$functionExists = aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>$null
if ($functionExists) {
    Write-Host "  Updating existing function..." -ForegroundColor Gray
    aws lambda update-function-code `
        --function-name $FUNCTION_NAME `
        --zip-file fileb://lambda-deployment.zip `
        --region $REGION | Out-Null
    
    aws lambda update-function-configuration `
        --function-name $FUNCTION_NAME `
        --environment "Variables={MONGODB_URL=$MONGODB_URL,SECRET_KEY=$SECRET_KEY,MASTER_DB_NAME=master_db}" `
        --region $REGION | Out-Null
}
else {
    Write-Host "  Creating new Lambda function..." -ForegroundColor Gray
    aws lambda create-function `
        --function-name $FUNCTION_NAME `
        --runtime $RUNTIME `
        --role $ROLE_ARN `
        --handler $HANDLER `
        --zip-file fileb://lambda-deployment.zip `
        --timeout 30 `
        --memory-size 512 `
        --environment "Variables={MONGODB_URL=$MONGODB_URL,SECRET_KEY=$SECRET_KEY,MASTER_DB_NAME=master_db}" `
        --region $REGION | Out-Null
}

Write-Host "✅ Lambda function deployed!" -ForegroundColor Green
Write-Host ""

# Step 4: Create API Gateway (HTTP API)
Write-Host "🌐 Setting up API Gateway..." -ForegroundColor Cyan

# Get account ID for Lambda ARN
$LAMBDA_ARN = "arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${FUNCTION_NAME}"

# Check if API exists
$apiList = aws apigatewayv2 get-apis --query "Items[?Name=='org-management-api'].ApiId" --output text --region $REGION
if ($apiList) {
    $API_ID = $apiList
    Write-Host "  Using existing API Gateway: $API_ID" -ForegroundColor Gray
}
else {
    Write-Host "  Creating HTTP API..." -ForegroundColor Gray
    $apiResponse = aws apigatewayv2 create-api `
        --name org-management-api `
        --protocol-type HTTP `
        --target "$LAMBDA_ARN" `
        --region $REGION | ConvertFrom-Json
    $API_ID = $apiResponse.ApiId
}

# Add Lambda permission for API Gateway
aws lambda add-permission `
    --function-name $FUNCTION_NAME `
    --statement-id apigateway-invoke `
    --action lambda:InvokeFunction `
    --principal apigateway.amazonaws.com `
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" `
    --region $REGION 2>$null

$API_URL = "https://$API_ID.execute-api.$REGION.amazonaws.com"

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Your API is live at:" -ForegroundColor Cyan
Write-Host "   $API_URL" -ForegroundColor White
Write-Host ""
Write-Host "📋 Test it:" -ForegroundColor Yellow
Write-Host "   curl $API_URL/" -ForegroundColor White
Write-Host ""
Write-Host "📚 API Documentation:" -ForegroundColor Yellow
Write-Host "   $API_URL/docs" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Example - Create Organization:" -ForegroundColor Yellow
Write-Host @"
   curl -X POST "$API_URL/org/create" ``
     -H "Content-Type: application/json" ``
     -d '{"organization_name":"Test","email":"admin@test.com","password":"pass123"}'
"@ -ForegroundColor White
Write-Host ""
Write-Host "💰 Estimated Cost: `$0-5/month" -ForegroundColor Green
Write-Host ""

# Cleanup
Write-Host "🧹 Cleaning up temporary files..." -ForegroundColor Gray
Remove-Item -Recurse -Force lambda-package -ErrorAction SilentlyContinue
Remove-Item lambda-deployment.zip -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "All done! 🎉" -ForegroundColor Green
