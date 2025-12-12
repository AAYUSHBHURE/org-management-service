# AWS Elastic Beanstalk Deployment Guide

Deploy your Organization Management Service to **AWS Elastic Beanstalk** using only the web console - No CLI required! 🚀

## Why Elastic Beanstalk?

✅ **No AWS CLI needed** - Deploy via web console  
✅ **Perfect for APIs** - Designed for backend applications  
✅ **Auto-scaling** - Automatically handles traffic spikes  
✅ **AWS native** - Integrated with RDS, CloudWatch, etc.  
✅ **Easy monitoring** - Built-in health dashboard  

**Cost**: ~$10-20/month (t2.micro instance)

---

## Prerequisites

1. ✅ AWS account with billing enabled
2. ✅ Code on GitHub (done!)
3. MongoDB Atlas account (free tier)

---

## Step 1: Set up MongoDB Atlas (5 minutes)

If you haven't already:

1. Go to [cloud.mongodb.com](https://cloud.mongodb.com)
2. Sign up / Login
3. **Create Database** → **M0 Free** tier
4. Choose **AWS** as provider, region **us-east-1**
5. **Create Database User**: username `admin`, auto-generate password (save it!)
6. **Network Access** → Add IP: `0.0.0.0/0`
7. Click **Connect** → **Connect your application**
8. **Copy connection string**: `mongodb+srv://admin:PASSWORD@cluster0.xxxxx.mongodb.net/`

---

## Step 2: Generate Secret Key

Run locally:
```powershell
python -c "import secrets; print(secrets.token_urlsafe(32))"
```
**Save the output!**

---

## Step 3: Create Application ZIP

Package your code for upload:

```powershell
cd C:\Users\bhure\.gemini\antigravity\scratch\OrgManagementService

# Create deployment ZIP (exclude unnecessary files)
Compress-Archive -Path app,requirements.txt,Procfile,.dockerignore -DestinationPath eb-deployment.zip -Force
```

---

## Step 4: Deploy to Elastic Beanstalk (Web Console)

### A. Open Elastic Beanstalk Console

1. Go to [AWS Console](https://console.aws.amazon.com)
2. Search for **"Elastic Beanstalk"** in the top search bar
3. Click **"AWS Elastic Beanstalk"**

### B. Create New Application

1. Click **"Create application"**

2. **Configure environment**:
   - **Application name**: `org-management-service`
   - **Environment name**: `org-management-env`
   - **Platform**: Select **"Python"**
   - **Platform branch**: **"Python 3.11"** (or latest)
   - **Platform version**: Use recommended

3. **Application code**:
   - Select **"Upload your code"**
   - **Version label**: `v1.0`
   - Click **"Choose file"** → Upload `eb-deployment.zip`

### C. Configure Service Access

1. **Service role**: 
   - If you have one, select it
   - Otherwise, select **"Create and use new service role"**

2. **EC2 key pair**: Select **"Proceed without key pair"** (unless you need SSH access)

3. **EC2 instance profile**:
   - Select **"Create new instance profile"** if none exists
   - Name it: `aws-elasticbeanstalk-ec2-role`

4. Click **"Next"**

### D. Configure Networking, Database, and Tags (Optional)

1. **VPC**: Use default
2. **Public IP**: ✅ Enable
3. Click **"Next"**

### E. Configure Instance Traffic and Scaling

1. **Root volume type**: General Purpose (SSD)
2. **Size**: 10 GB
3. **Environment type**: **Single instance** (for cost savings) or **Load balanced** (for production)
4. **Instance types**: **t2.micro** (free tier) or **t3.micro**
5. Click **"Next"**

### F. Configure Updates, Monitoring, and Logging

1. **Health reporting**: Enhanced
2. **Managed updates**: Enable
3. Click **"Next"**

### G. **IMPORTANT: Add Environment Variables**

1. Scroll down to **"Environment properties"**
2. Click **"Add environment property"** for each:

| Name | Value |
|------|-------|
| `MONGODB_URL` | Your MongoDB Atlas connection string |
| `SECRET_KEY` | Your generated secret key |
| `MASTER_DB_NAME` | `master_db` |
| `ALGORITHM` | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `30` |

3. Click **"Next"**

### H. Review and Submit

1. Review all settings
2. Click **"Submit"**
3. **Wait 5-10 minutes** for environment creation

---

## Step 5: Access Your API

After deployment completes:

1. You'll see **"Environment health: Ok"** in green
2. Your API URL will be shown at the top:
   ```
   http://org-management-env.eba-xxxxxxxx.us-east-1.elasticbeanstalk.com
   ```

### Test Your API

```powershell
# Set your URL
$API_URL = "http://org-management-env.eba-xxxxxxxx.us-east-1.elasticbeanstalk.com"

# Test root
curl $API_URL/

# Create organization
curl -X POST "$API_URL/org/create" `
  -H "Content-Type: application/json" `
  -d '{"organization_name":"TestOrg","email":"admin@test.com","password":"secure123"}'

# API docs
# Open in browser: $API_URL/docs
```

---

## Updating Your Application

When you make code changes:

1. **Update code locally**
2. **Create new ZIP**:
   ```powershell
   Compress-Archive -Path app,requirements.txt,Procfile -DestinationPath eb-deployment-v2.zip -Force
   ```
3. **In Elastic Beanstalk Console**:
   - Go to your environment
   - Click **"Upload and deploy"**
   - Upload new ZIP
   - Version label: `v2.0`
   - Click **"Deploy"**

---

## Monitoring & Logs

### View Application Logs

1. **Elastic Beanstalk Console** → Your environment
2. Click **"Logs"** in left sidebar
3. Click **"Request Logs"** → **"Last 100 Lines"** or **"Full Logs"**

### Health Monitoring

1. Click **"Monitoring"** in left sidebar
2. View metrics: CPU, Network, Requests, Latency
3. Set up CloudWatch alarms for errors

---

## Cost Breakdown

### Elastic Beanstalk (Free - just pay for EC2)

### EC2 Instance
- **t2.micro**: $0.0116/hour = ~$8.50/month (free tier: 750 hours/month for 12 months)
- **t3.micro**: $0.0104/hour = ~$7.60/month

### Data Transfer
- First 1 GB out/month: Free
- Next 10 TB: $0.09/GB

### MongoDB Atlas
- **M0 Free**: $0/month

### **Total Cost**
- **First year** (free tier): ~$0/month
- **After free tier**: ~$8-12/month

---

## Troubleshooting

### Deployment Failed

1. Check logs: **Logs → Request Logs → Last 100 Lines**
2. Common issues:
   - Missing dependencies in `requirements.txt`
   - Incorrect Python version
   - Missing environment variables

### 502 Bad Gateway

1. Check application is running on port 8000
2. Verify `Procfile` is correct
3. Check environment variables are set

### MongoDB Connection Error

1. Verify MongoDB Atlas connection string
2. Check Network Access allows `0.0.0.0/0`
3. Verify database user credentials

### Application Not Starting

1. Check `requirements.txt` has all dependencies
2. Verify Python version compatibility
3. Check logs for startup errors

---

## Advanced: Custom Domain (Optional)

1. **Route 53** → Create hosted zone for your domain
2. **Elastic Beanstalk** → Environment → Configuration
3. **Load balancer** → Add listener on port 443 (HTTPS)
4. **Certificate Manager** → Request SSL certificate
5. Update Route 53 to point to EB environment

---

## Security Best Practices

### 1. Enable HTTPS

1. **AWS Certificate Manager** → Request certificate
2. **Elastic Beanstalk** → Load balancer configuration
3. Add HTTPS listener

### 2. Restrict Database Access

Instead of `0.0.0.0/0`, get your EB environment IP:
```powershell
nslookup org-management-env.eba-xxxxxxxx.us-east-1.elasticbeanstalk.com
```
Add this specific IP to MongoDB Atlas Network Access

### 3. Use Secrets Manager (Optional)

Store sensitive data in **AWS Secrets Manager** instead of environment variables

---

## Scaling Your Application

### Auto Scaling

1. **Configuration** → **Capacity**
2. **Environment type**: Change to **Load balanced**
3. Set:
   - **Min instances**: 1
   - **Max instances**: 4
4. **Scaling triggers**: CPU > 70%

---

## Alternative: If Elastic Beanstalk is Too Complex

Use **Render** instead:
- ✅ **100% Free**
- ✅ **5 clicks to deploy**
- ✅ **Auto-deploys from GitHub**
- ✅ **No configuration needed**

Just go to [render.com](https://render.com), connect GitHub, and click deploy!

---

## Next Steps

After successful deployment:

1. ✅ Test all API endpoints
2. ✅ Set up CloudWatch alarms
3. ✅ Configure auto-scaling (if needed)
4. ✅ Add custom domain
5. ✅ Enable HTTPS
6. ✅ Set up CI/CD with GitHub Actions

---

## Support

- **Elastic Beanstalk Docs**: https://docs.aws.amazon.com/elasticbeanstalk
- **MongoDB Atlas**: https://docs.atlas.mongodb.com
- **FastAPI**: https://fastapi.tiangolo.com

Good luck with your AWS deployment! 🚀
