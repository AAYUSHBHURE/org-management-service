# AWS Deployment Guide - Organization Management Service

Complete step-by-step guide for deploying to AWS with three options: App Runner (easiest), ECS Fargate (scalable), and EC2 (manual).

---

## Prerequisites

1. **AWS Account** with billing enabled
2. **AWS CLI** installed and configured:
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Key, and region (e.g., us-east-1)
   ```
3. **Docker** installed (for App Runner and ECS)
4. **MongoDB Database** - Use MongoDB Atlas (recommended) or AWS DocumentDB

---

## Option 1: AWS App Runner (RECOMMENDED - Easiest)

**Best for:** Quick deployment, auto-scaling, managed infrastructure  
**Cost:** ~$25-40/month  
**Time to deploy:** 15-20 minutes

### Step-by-Step Instructions

#### 1. Set up MongoDB Atlas (Free Tier)

```bash
# Go to https://www.mongodb.com/cloud/atlas/register
# 1. Create free account
# 2. Create cluster (M0 Free tier)
# 3. Create database user
# 4. Whitelist IP: 0.0.0.0/0 (allow from anywhere)
# 5. Get connection string - looks like:
#    mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

#### 2. Prepare Your Application

Update `.env` for production:
```env
PROJECT_NAME="Organization Management Service"
MONGODB_URL="mongodb+srv://user:password@cluster.mongodb.net/?retryWrites=true&w=majority"
MASTER_DB_NAME="master_db"
SECRET_KEY="<USE-COMMAND-BELOW-TO-GENERATE>"
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

Generate secret key:
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

#### 3. Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/org-management-service.git
git push -u origin main
```

#### 4. Deploy to App Runner

**Via AWS Console:**

1. Go to [AWS App Runner Console](https://console.aws.amazon.com/apprunner)
2. Click **"Create service"**
3. **Source:**
   - Repository: Connect to GitHub
   - Select your repository
   - Branch: `main`
   - Deployment trigger: Automatic
4. **Build settings:**
   - Runtime: Python 3
   - Build command: `pip install -r requirements.txt`
   - Start command: `uvicorn app.main:app --host 0.0.0.0 --port 8000`
   - Port: `8000`
5. **Service settings:**
   - Service name: `org-management-service`
   - vCPU: 1 vCPU
   - Memory: 2 GB
6. **Environment variables:** Add these:
   ```
   MONGODB_URL=<your-atlas-connection-string>
   SECRET_KEY=<generated-secret>
   MASTER_DB_NAME=master_db
   ```
7. Click **"Create & Deploy"**
8. Wait ~5-10 minutes for deployment
9. Your app URL will be: `https://xxxxxxxxx.us-east-1.awsapprunner.com`

**Via AWS CLI:**

```bash
# Create apprunner.yaml configuration
cat > apprunner.yaml << 'EOF'
version: 1.0
runtime: python3
build:
  commands:
    build:
      - pip install -r requirements.txt
run:
  command: uvicorn app.main:app --host 0.0.0.0 --port 8000
  network:
    port: 8000
    env: APP_PORT
  env:
    - name: MONGODB_URL
      value: "mongodb+srv://..."
    - name: SECRET_KEY
      value: "your-secret-key"
EOF

# Deploy
aws apprunner create-service \
  --service-name org-management-service \
  --source-configuration file://apprunner-source.json \
  --instance-configuration file://apprunner-instance.json
```

#### 5. Test Your Deployment

```bash
# Set your App Runner URL
export API_URL="https://your-app-id.us-east-1.awsapprunner.com"

# Test health
curl $API_URL/

# Test create org
curl -X POST $API_URL/org/create \
  -H "Content-Type: application/json" \
  -d '{"organization_name":"TestOrg","email":"admin@test.com","password":"secure123"}'
```

---

## Option 2: AWS ECS with Fargate (Production-Ready)

**Best for:** Production workloads, fine-grained control, scalability  
**Cost:** ~$50-100/month  
**Time to deploy:** 30-45 minutes

### Architecture
- ECS Fargate for containerized app
- Application Load Balancer for traffic distribution
- MongoDB Atlas or AWS DocumentDB
- ECR for Docker image storage

### Step-by-Step Instructions

#### 1. Build and Push Docker Image to ECR

```bash
# Set variables
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REPO_NAME=org-management-service

# Create ECR repository
aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build Docker image
docker build -t $ECR_REPO_NAME .

# Tag image
docker tag $ECR_REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest
```

#### 2. Create ECS Cluster

```bash
# Create cluster
aws ecs create-cluster --cluster-name org-management-cluster --region $AWS_REGION
```

#### 3. Create Task Definition

Create `ecs-task-definition.json`:
```json
{
  "family": "org-management-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "org-management-api",
      "image": "ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/org-management-service:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "MONGODB_URL",
          "value": "mongodb+srv://user:pass@cluster.mongodb.net"
        },
        {
          "name": "SECRET_KEY",
          "value": "your-secret-key-here"
        },
        {
          "name": "MASTER_DB_NAME",
          "value": "master_db"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/org-management",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

Replace `ACCOUNT_ID` and register:
```bash
# Update the JSON with your account ID
sed -i "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" ecs-task-definition.json

# Register task definition
aws ecs register-task-definition --cli-input-json file://ecs-task-definition.json
```

#### 4. Create Application Load Balancer (ALB)

```bash
# Create security group for ALB
aws ec2 create-security-group \
  --group-name org-management-alb-sg \
  --description "Security group for org management ALB" \
  --vpc-id <your-vpc-id>

# Allow HTTP traffic
aws ec2 authorize-security-group-ingress \
  --group-id <sg-id> \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Create ALB (use AWS Console or CLI)
# Console: EC2 > Load Balancers > Create Load Balancer > Application Load Balancer
```

#### 5. Create ECS Service

```bash
aws ecs create-service \
  --cluster org-management-cluster \
  --service-name org-management-service \
  --task-definition org-management-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=org-management-api,containerPort=8000"
```

#### 6. Access Your Application

Your app will be available at the ALB DNS name:
`http://org-management-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com`

---

## Option 3: AWS EC2 (Manual Setup)

**Best for:** Full control, learning purposes  
**Cost:** ~$20-30/month (t3.small instance)  
**Time to deploy:** 30-40 minutes

### Step-by-Step Instructions

#### 1. Launch EC2 Instance

```bash
# Launch Ubuntu instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.small \
  --key-name your-key-pair \
  --security-group-ids sg-xxx \
  --subnet-id subnet-xxx \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=org-management}]'
```

#### 2. Connect to EC2

```bash
ssh -i your-key.pem ubuntu@<ec2-public-ip>
```

#### 3. Install Dependencies on EC2

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python and pip
sudo apt install python3 python3-pip -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 4. Deploy Application

```bash
# Clone your repository
git clone https://github.com/yourusername/org-management-service.git
cd org-management-service

# Update .env with MongoDB Atlas URL
nano .env

# Run with Docker Compose
docker-compose up -d

# Or run directly
pip3 install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

#### 5. Set up Nginx (Optional - for production)

```bash
sudo apt install nginx -y

# Create nginx config
sudo nano /etc/nginx/sites-available/org-management
```

Add:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/org-management /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Cost Comparison

| Option | Monthly Cost | Scalability | Management | Best For |
|--------|-------------|-------------|------------|----------|
| **App Runner** | $25-40 | Auto | Fully Managed | Quick deploy, minimal ops |
| **ECS Fargate** | $50-100 | Manual/Auto | Semi-Managed | Production, control |
| **EC2** | $20-30 | Manual | Self-Managed | Learning, full control |

Plus MongoDB Atlas: $0 (free tier) or $57+ (production)

---

## Security Best Practices

1. **Use AWS Secrets Manager** for sensitive data:
   ```bash
   aws secretsmanager create-secret \
     --name org-management/mongodb-url \
     --secret-string "mongodb+srv://..."
   ```

2. **Enable VPC** for ECS/EC2 deployments

3. **Use IAM roles** instead of access keys

4. **Enable CloudWatch Logs** for monitoring

5. **Set up SSL/TLS** with AWS Certificate Manager

---

## Monitoring & Logging

### CloudWatch Setup

```bash
# Create log group
aws logs create-log-group --log-group-name /aws/org-management

# View logs
aws logs tail /aws/org-management --follow
```

### Enable CloudWatch Metrics

Add to your application (optional):
```python
# app/main.py
import boto3

cloudwatch = boto3.client('cloudwatch')

@app.middleware("http")
async def log_requests(request, call_next):
    response = await call_next(request)
    cloudwatch.put_metric_data(
        Namespace='OrgManagement',
        MetricData=[{
            'MetricName': 'RequestCount',
            'Value': 1,
            'Unit': 'Count'
        }]
    )
    return response
```

---

## Troubleshooting

### App Runner Issues
- Check logs: AWS Console > App Runner > Service > Logs
- Verify environment variables are set correctly
- Ensure GitHub repo is connected properly

### ECS Issues
```bash
# Check task status
aws ecs describe-tasks --cluster org-management-cluster --tasks <task-id>

# Check logs
aws logs tail /ecs/org-management --follow
```

### EC2 Issues
```bash
# Check app logs
docker-compose logs -f

# Restart service
docker-compose restart
```

---

## Next Steps

After deployment:
1. Set up custom domain with Route 53
2. Enable HTTPS with AWS Certificate Manager
3. Set up CI/CD with AWS CodePipeline
4. Configure auto-scaling (for ECS)
5. Set up monitoring with CloudWatch

## Recommended Choice

**For your internship submission: Use AWS App Runner**
- Fastest to deploy
- Fully managed
- Auto-scaling
- Professional production grade
- Easy to demonstrate

Good luck with your deployment! 🚀
