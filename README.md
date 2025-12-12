# Organization Management Service

A scalable, multi-tenant **FastAPI** service for managing organizations with MongoDB Atlas integration. Designed for cost-effective deployment on AWS Elastic Beanstalk with JWT-based authentication.

## 🚀 Live Demo

**Production API:** [http://org-management-service-env-2.eba-fkzsvws8.ap-south-1.elasticbeanstalk.com](http://org-management-service-env-2.eba-fkzsvws8.ap-south-1.elasticbeanstalk.com)

**API Documentation:** [http://org-management-service-env-2.eba-fkzsvws8.ap-south-1.elasticbeanstalk.com/docs](http://org-management-service-env-2.eba-fkzsvws8.ap-south-1.elasticbeanstalk.com/docs)

---

## 📋 Features

- ✅ **Multi-tenant architecture** with isolated organization databases
- ✅ **JWT authentication** for secure API access
- ✅ **RESTful API** with FastAPI
- ✅ **MongoDB Atlas** integration (free tier compatible)
- ✅ **AWS Elastic Beanstalk** deployment
- ✅ **Auto-scaling** capable infrastructure
- ✅ **Interactive API docs** with Swagger UI
- ✅ **Production-ready** with Gunicorn + Uvicorn

---

## 🏗️ Architecture

```
┌─────────────────┐
│   API Gateway   │ ← AWS Elastic Load Balancer
└────────┬────────┘
         │
    ┌────▼─────┐
    │  NGINX   │ ← Reverse Proxy
    └────┬─────┘
         │
┌────────▼─────────┐
│     FastAPI      │ ← Application Layer
│  (Gunicorn +     │
│   Uvicorn)       │
└────────┬─────────┘
         │
┌────────▼─────────┐
│  MongoDB Atlas   │ ← Database Layer
│  (Multi-tenant)  │
└──────────────────┘
```

**Key Components:**
- **FastAPI**: Modern, high-performance web framework
- **Motor**: Async MongoDB driver for Python
- **Gunicorn**: WSGI server with Uvicorn workers
- **JWT**: Secure token-based authentication
- **MongoDB Atlas**: Cloud-hosted NoSQL database

---

## 🛠️ Tech Stack

**Backend:**
- Python 3.11+
- FastAPI
- Motor (async MongoDB driver)
- Pydantic (data validation)
- PyJWT (authentication)
- Passlib (password hashing)

**Deployment:**
- AWS Elastic Beanstalk
- Gunicorn + Uvicorn
- NGINX
- MongoDB Atlas (M0 Free Tier)

---

## 📦 Installation & Setup

### Prerequisites
- Python 3.11 or higher
- MongoDB Atlas account (free tier)
- AWS account (for deployment)

### Local Development

**1. Clone the repository:**
```bash
git clone https://github.com/AAYUSHBHURE/org-management-service.git
cd org-management-service
```

**2. Create virtual environment:**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

**3. Install dependencies:**
```bash
pip install -r requirements.txt
```

**4. Set up environment variables:**
Create a `.env` file in the root directory:
```env
PROJECT_NAME=Organization Management Service
MONGODB_URL=mongodb+srv://username:password@cluster.mongodb.net/
MASTER_DB_NAME=master_db
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

**5. Run the application:**
```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`

---

## 🔌 API Endpoints

### Root
- **GET** `/` - Health check

### Organization Management
- **POST** `/org/create` - Create new organization
- **GET** `/org/get` - Get organization details
- **PUT** `/org/update` - Update organization
- **DELETE** `/org/delete` - Delete organization

### Authentication
- **POST** `/admin/login` - Admin login (returns JWT token)

### Documentation
- **GET** `/docs` - Interactive API documentation (Swagger UI)
- **GET** `/redoc` - Alternative API documentation

---

## 📝 API Usage Examples

### Create Organization
```bash
curl -X POST "http://org-management-service-env-2.eba-fkzsvws8.ap-south-1.elasticbeanstalk.com/org/create" \
  -H "Content-Type: application/json" \
  -d '{
    "organization_name": "MyOrg",
    "email": "admin@myorg.com",
    "password": "securepassword"
  }'
```

### Login
```bash
curl -X POST "http://org-management-service-env-2.eba-fkzsvws8.ap-south-1.elasticbeanstalk.com/admin/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@myorg.com",
    "password": "securepassword"
  }'
```

### Get Organization (with JWT token)
```bash
curl -X GET "http://org-management-service-env-2.eba-fkzsvws8.ap-south-1.elasticbeanstalk.com/org/get?organization_name=MyOrg" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🚀 Deployment

### AWS Elastic Beanstalk

The application is configured for seamless deployment to AWS Elastic Beanstalk.

**1. Create deployment package:**
```bash
python create_eb_zip.py
```

**2. Deploy via AWS Console:**
- Go to [AWS Elastic Beanstalk Console](https://console.aws.amazon.com/elasticbeanstalk)
- Create new application or update existing
- Upload `eb-deployment-v3.zip`
- Configure environment variables (MONGODB_URL, SECRET_KEY, etc.)
- Deploy!

**Detailed deployment guide:** See [AWS_ELASTIC_BEANSTALK.md](./AWS_ELASTIC_BEANSTALK.md)

### Docker (Alternative)

```bash
docker-compose up -d
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for more deployment options.

---


## 🔐 Security Features

- ✅ **Password hashing** with PBKDF2-SHA256
- ✅ **JWT tokens** for stateless authentication
- ✅ **Environment-based configuration** (no hardcoded secrets)
- ✅ **Input validation** with Pydantic
- ✅ **CORS configuration** for API security

---

## 📁 Project Structure

```
OrgManagementService/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application entry point
│   ├── core/
│   │   ├── config.py           # Configuration management
│   │   ├── database.py         # MongoDB connection logic
│   │   └── security.py         # Authentication & password hashing
│   ├── models/
│   │   ├── admin.py            # Admin/Auth data models
│   │   └── organization.py     # Organization data models
│   └── routers/
│       ├── admin.py            # Authentication endpoints
│       └── organization.py     # Organization CRUD endpoints
├── .platform/                  # AWS Elastic Beanstalk platform configs
│   └── nginx/conf.d/
│       └── app.conf
├── Procfile                    # EB process configuration
├── requirements.txt            # Python dependencies
├── docker-compose.yml          # Docker setup
├── Dockerfile                  # Container configuration
├── .gitignore
├── README.md
├── ARCHITECTURE.md
├── DEPLOYMENT.md
└── AWS_ELASTIC_BEANSTALK.md
```

---

## 🧪 Testing

### Manual Testing
Use the interactive API docs at `/docs` endpoint for testing all endpoints with built-in Swagger UI.

### Automated Testing (Future)
```bash
pytest tests/
```

---

## 📚 Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture and design decisions
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Comprehensive deployment guide (AWS, Docker, etc.)
- **[AWS_ELASTIC_BEANSTALK.md](./AWS_ELASTIC_BEANSTALK.md)** - Detailed AWS EB deployment walkthrough

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---
