# Environment Files Separation Guide

This document explains the separated environment configuration for the LawVriksh application.

## 📁 File Structure

```
lawvriksh-deployment/
├── .env.production                    # Frontend environment variables
├── BetajoiningBackend/
│   └── .env.production               # Backend environment variables
├── docker-compose.yml               # Uses both env files
└── deploy.sh                        # Updated deployment script
```

## 🎯 Frontend Environment (`.env.production`)

**Location**: Root directory  
**Purpose**: Contains only frontend-specific environment variables  
**Used by**: React/Vite build process and Nginx container

### Variables:
```bash
# API Configuration
VITE_API_URL=https://lawvriksh.com/api

# Domain Configuration  
VITE_FRONTEND_URL=https://lawvriksh.com

# Build Configuration
NODE_ENV=production
```

### Key Points:
- **VITE_** prefix is required for Vite to include variables in the build
- Only contains variables needed by the frontend application
- No sensitive backend credentials
- Used during Docker build process for frontend

## 🔧 Backend Environment (`BetajoiningBackend/.env.production`)

**Location**: BetajoiningBackend directory  
**Purpose**: Contains all backend-specific environment variables  
**Used by**: FastAPI application, Celery workers, and Celery beat scheduler

### Key Sections:

#### Database Configuration:
```bash
DB_HOST=mysql
DB_PORT=3306
DB_NAME=lawvriksh_referral
DB_USER=root
DB_PASSWORD=Sahil@123
MYSQL_ROOT_PASSWORD=Sahil@123
DATABASE_URL=mysql+pymysql://root:Sahil@123@mysql:3306/lawvriksh_referral
```

#### Redis Configuration:
```bash
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=Sahil@123
REDIS_URL=redis://:Sahil@123@redis:6379/0
```

#### Email Configuration (Hostinger SMTP):
```bash
EMAIL_FROM=info@lawvriksh.com
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_USER=info@lawvriksh.com
SMTP_PASSWORD=Lawvriksh@123
```

#### Security Configuration:
```bash
JWT_SECRET_KEY=a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
SECRET_KEY=9876543210fedcba0987654321fedcba0987654321fedcba0987654321fedcba
```

## 🐳 Docker Compose Integration

The `docker-compose.yml` file has been updated to use separate environment files:

### Frontend Service:
```yaml
frontend:
  build:
    context: .
    dockerfile: Dockerfile.frontend
    args:
      - BUILD_ENV=production
      - VITE_API_URL=https://lawvriksh.com/api
  env_file:
    - ./.env.production  # Frontend env file
```

### Backend Services:
```yaml
backend:
  env_file:
    - ./BetajoiningBackend/.env.production  # Backend env file

celery-worker:
  env_file:
    - ./BetajoiningBackend/.env.production  # Backend env file

celery-beat:
  env_file:
    - ./BetajoiningBackend/.env.production  # Backend env file
```

### Database & Redis Services:
```yaml
mysql:
  environment:
    MYSQL_ROOT_PASSWORD: Sahil@123
    MYSQL_DATABASE: lawvriksh_referral
    MYSQL_USER: root
    MYSQL_PASSWORD: Sahil@123

redis:
  command: redis-server --appendonly yes --requirepass "Sahil@123"
```

## 🔒 Security Benefits

### 1. **Separation of Concerns**
- Frontend only has access to public configuration
- Backend credentials are isolated from frontend build

### 2. **Reduced Attack Surface**
- Frontend bundle doesn't contain sensitive backend credentials
- Database passwords not exposed in client-side code

### 3. **Environment Isolation**
- Different teams can manage different environment files
- Frontend developers don't need backend credentials

## 🚀 Deployment Process

### 1. **Validation**
The deployment script now validates both environment files:

```bash
# Frontend validation
if ! grep -q "VITE_API_URL=" .env.production; then
    error "VITE_API_URL not found in frontend .env.production file"
fi

# Backend validation  
if ! grep -q "JWT_SECRET_KEY=" BetajoiningBackend/.env.production; then
    error "JWT_SECRET_KEY not found in backend .env.production file"
fi
```

### 2. **Build Process**
- Frontend: Uses `.env.production` during Vite build
- Backend: Uses `BetajoiningBackend/.env.production` at runtime

### 3. **Runtime**
- Each service loads its respective environment file
- No cross-contamination of environment variables

## 📋 Migration Checklist

- [x] Created separate frontend `.env.production` file
- [x] Created separate backend `BetajoiningBackend/.env.production` file
- [x] Updated `docker-compose.yml` to use `env_file` directives
- [x] Removed hardcoded environment variables from docker-compose
- [x] Updated deployment script validation
- [x] Used actual production values (no dummy data)
- [x] Configured Hostinger SMTP settings
- [x] Set correct database credentials
- [x] Configured Redis with actual password

## 🔧 Maintenance

### Updating Frontend Environment:
```bash
# Edit frontend environment
nano .env.production

# Rebuild frontend only
docker-compose build frontend
docker-compose up -d frontend
```

### Updating Backend Environment:
```bash
# Edit backend environment
nano BetajoiningBackend/.env.production

# Restart backend services
docker-compose restart backend celery-worker celery-beat
```

## 🌐 URLs and Ports

### Production URLs:
- **Frontend**: https://lawvriksh.com
- **API**: https://lawvriksh.com/api

### Internal Ports:
- **MySQL**: 3307 (external), 3306 (internal)
- **Redis**: 6379
- **Backend**: 8000
- **Frontend**: 80 (HTTP), 443 (HTTPS)

## ⚠️ Important Notes

1. **Never commit actual passwords** to version control
2. **Use environment-specific files** for different deployments
3. **Validate environment files** before deployment
4. **Keep frontend env minimal** - only public configuration
5. **Secure backend env file** with proper file permissions

---

This separation ensures better security, maintainability, and follows Docker best practices for environment management.
