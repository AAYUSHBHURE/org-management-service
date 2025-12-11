# Deployment Guide

This guide covers multiple deployment options for the Organization Management Service.

## Table of Contents
- [Quick Deploy (Railway/Render)](#quick-deploy)
- [Docker Deployment](#docker-deployment)
- [Cloud Platforms](#cloud-platforms)
- [Production Checklist](#production-checklist)

---

## Quick Deploy

### Option 1: Railway (Recommended for Quick Start)

**Steps:**
1. Create account at [Railway.app](https://railway.app)
2. Click "New Project" → "Deploy from GitHub repo"
3. Add MongoDB service: "New" → "Database" → "MongoDB"
4. Add Python service: Point to your GitHub repo
5. Set environment variables in Railway dashboard:
   ```
   MONGODB_URL=<Railway provides this automatically>
   SECRET_KEY=<generate strong random key>
   ```
6. Deploy! Railway auto-detects Python and runs the app.

**Cost:** Free tier available, then ~$5/month

### Option 2: Render

**Steps:**
1. Create account at [Render.com](https://render.com)
2. Create MongoDB instance (or use MongoDB Atlas)
3. Create new "Web Service"
4. Connect GitHub repo
5. Configure:
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
6. Add environment variables
7. Deploy

---

## Docker Deployment

### 1. Create Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app/ ./app/
COPY .env .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. Create docker-compose.yml

```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    environment:
      MONGO_INITDB_DATABASE: master_db

  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - MONGODB_URL=mongodb://mongodb:27017
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      - mongodb

volumes:
  mongodb_data:
```

### 3. Deploy with Docker

```bash
# Build and run
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

---

## Cloud Platforms

### AWS Deployment

#### Option A: AWS App Runner (Easiest)

1. **Prepare:**
   - Push code to GitHub
   - Use MongoDB Atlas for database

2. **Deploy:**
   - Go to AWS App Runner console
   - Create service from GitHub
   - Configure build settings (auto-detected)
   - Set environment variables
   - Deploy

**Cost:** ~$25/month minimum

#### Option B: AWS ECS + Fargate

1. Create ECR repository and push Docker image
2. Create ECS cluster with Fargate
3. Define task definition
4. Create service with load balancer
5. Use DocumentDB or MongoDB Atlas

**Cost:** ~$50-100/month

### Google Cloud Platform

#### Cloud Run (Serverless)

```bash
# Build and deploy
gcloud builds submit --tag gcr.io/PROJECT_ID/org-management
gcloud run deploy org-management \
  --image gcr.io/PROJECT_ID/org-management \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars MONGODB_URL=<atlas-url>,SECRET_KEY=<key>
```

**Cost:** Pay-per-use, can be very cheap

### Azure

#### Azure Container Apps

1. Create Container Registry
2. Build and push image
3. Create Container App
4. Use Azure Cosmos DB (MongoDB API) or Atlas
5. Configure environment variables

**Cost:** ~$30-50/month

### DigitalOcean

#### App Platform

1. Connect GitHub repo
2. DigitalOcean auto-detects Python
3. Add MongoDB managed database ($15/month)
4. Set environment variables
5. Deploy

**Cost:** ~$20-30/month total

---

## Production Checklist

### Security

- [ ] Change `SECRET_KEY` to strong random value
  ```bash
  python -c "import secrets; print(secrets.token_urlsafe(32))"
  ```
- [ ] Enable MongoDB authentication
- [ ] Use HTTPS/TLS (most platforms provide free SSL)
- [ ] Set CORS properly in production
- [ ] Use environment variables for all secrets
- [ ] Enable rate limiting (consider using nginx or API gateway)

### Database

- [ ] Use managed MongoDB service:
  - **MongoDB Atlas** (free tier available) - Recommended
  - Railway/Render managed MongoDB
  - AWS DocumentDB
  - Azure Cosmos DB
- [ ] Set up regular backups
- [ ] Create indexes for performance:
  ```python
  # Add to startup in main.py
  await master_db["organizations"].create_index("organization_name", unique=True)
  await master_db["organizations"].create_index("email", unique=True)
  ```

### Performance

- [ ] Add connection pooling (Motor default is good)
- [ ] Implement caching (Redis) for frequently accessed data
- [ ] Add monitoring (Sentry, New Relic, Datadog)
- [ ] Set up logging properly
- [ ] Use Gunicorn with multiple workers:
  ```bash
  gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
  ```

### Configuration Updates

Update `.env` for production:
```env
PROJECT_NAME="Organization Management Service"
MONGODB_URL="mongodb+srv://user:pass@cluster.mongodb.net/?retryWrites=true&w=majority"
MASTER_DB_NAME="master_db"
SECRET_KEY="<GENERATE-STRONG-KEY>"
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

---

## Recommended Quick Path

**For Assignment Submission:**
1. Push to GitHub
2. Deploy to **Railway** or **Render** (5 minutes setup)
3. Use **MongoDB Atlas** free tier
4. Share the live URL

**For Production:**
1. Containerize with Docker
2. Deploy to **AWS App Runner** or **GCP Cloud Run**
3. Use **MongoDB Atlas** M10+ cluster
4. Set up monitoring and backups

---

## Testing Deployment

After deployment, verify with:

```bash
# Replace with your deployed URL
export API_URL="https://your-app.railway.app"

# Test health
curl $API_URL/

# Test create org
curl -X POST $API_URL/org/create \
  -H "Content-Type: application/json" \
  -d '{"organization_name":"Test","email":"test@example.com","password":"testpass123"}'

# Test login
curl -X POST $API_URL/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass123"}'
```

---

## Need Help?

- **Railway:** [docs.railway.app](https://docs.railway.app)
- **Render:** [render.com/docs](https://render.com/docs)
- **MongoDB Atlas:** [docs.atlas.mongodb.com](https://docs.atlas.mongodb.com)
- **Docker:** [docs.docker.com](https://docs.docker.com)
