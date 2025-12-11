#!/bin/bash
# AWS App Runner Deployment Script

set -e

echo "🚀 Deploying to AWS App Runner..."

# Configuration
SERVICE_NAME="org-management-service"
GITHUB_REPO="yourusername/org-management-service"
GITHUB_BRANCH="main"
RUNTIME="PYTHON_3"
BUILD_COMMAND="pip install -r requirements.txt"
START_COMMAND="uvicorn app.main:app --host 0.0.0.0 --port 8000"
PORT="8000"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

# Check if user is authenticated
aws sts get-caller-identity > /dev/null 2>&1 || {
    echo "❌ Not authenticated with AWS. Run 'aws configure' first."
    exit 1
}

# Prompt for environment variables
echo ""
echo "📝 Please provide the following information:"
read -p "MongoDB Atlas URL: " MONGODB_URL
read -p "Secret Key (or press Enter to generate): " SECRET_KEY

if [ -z "$SECRET_KEY" ]; then
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    echo "Generated Secret Key: $SECRET_KEY"
fi

# Create App Runner service
echo ""
echo "Creating App Runner service..."

aws apprunner create-service \
  --service-name "$SERVICE_NAME" \
  --source-configuration "{
    \"CodeRepository\": {
      \"RepositoryUrl\": \"https://github.com/$GITHUB_REPO\",
      \"SourceCodeVersion\": {
        \"Type\": \"BRANCH\",
        \"Value\": \"$GITHUB_BRANCH\"
      },
      \"CodeConfiguration\": {
        \"ConfigurationSource\": \"API\",
        \"CodeConfigurationValues\": {
          \"Runtime\": \"$RUNTIME\",
          \"BuildCommand\": \"$BUILD_COMMAND\",
          \"StartCommand\": \"$START_COMMAND\",
          \"Port\": \"$PORT\",
          \"RuntimeEnvironmentVariables\": {
            \"MONGODB_URL\": \"$MONGODB_URL\",
            \"SECRET_KEY\": \"$SECRET_KEY\",
            \"MASTER_DB_NAME\": \"master_db\"
          }
        }
      }
    },
    \"AutoDeploymentsEnabled\": true
  }" \
  --instance-configuration "{
    \"Cpu\": \"1 vCPU\",
    \"Memory\": \"2 GB\"
  }" \
  --region us-east-1

echo ""
echo "✅ Deployment initiated!"
echo "📊 Check status in AWS Console: https://console.aws.amazon.com/apprunner"
echo ""
echo "⏳ Deployment usually takes 5-10 minutes..."
echo "Run the following to get your service URL:"
echo "aws apprunner describe-service --service-arn <service-arn> --query 'Service.ServiceUrl' --output text"
