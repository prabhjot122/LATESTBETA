# LawVriksh Production Deployment Guide

This guide provides comprehensive instructions for deploying the LawVriksh full-stack application on a Kali Linux VPS using Docker.

## 🚀 Quick Start

```bash
# Make deployment script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

## 📋 Prerequisites

### System Requirements
- **OS**: Kali Linux VPS (or any Linux distribution)
- **RAM**: Minimum 4GB (8GB recommended)
- **Storage**: Minimum 20GB free space
- **Network**: Public IP with ports 80, 443, 3307 accessible

### Software Requirements
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- OpenSSL (for SSL certificates)

### Installation Commands
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again for group changes to take effect
```

## 🏗️ Architecture Overview

### Services
1. **Frontend** (React/Vite + Nginx)
   - Domain: `https://lawvriksh.com`
   - Port: 80 (HTTP), 443 (HTTPS)
   - Features: SPA routing, static file serving, SSL termination

2. **Backend** (FastAPI + Gunicorn)
   - API: `https://lawvriksh.com/api`
   - Port: 8000 (internal)
   - Features: REST API, authentication, business logic

3. **Database** (MySQL 8.0)
   - Port: 3307 (custom for security)
   - Features: Data persistence, optimized configuration

4. **Cache** (Redis)
   - Port: 6379
   - Features: Session storage, caching, rate limiting

5. **Background Tasks** (Celery)
   - Worker: Background job processing
   - Beat: Scheduled task execution

### Network Architecture
```
Internet → Nginx (Frontend) → FastAPI (Backend) → MySQL/Redis
                ↓
            Static Files
```

## 🔧 Configuration Files

### 1. Frontend Dockerfile (`Dockerfile.frontend`)
- Multi-stage build for optimization
- Nginx-based serving with security headers
- Production-optimized React build

### 2. Backend Dockerfile (`Dockerfile.backend`)
- Python 3.11 with optimized dependencies
- Non-root user for security
- Health checks and logging

### 3. Docker Compose (`docker-compose.yml`)
- Orchestrates all services
- Health checks and dependencies
- Resource limits and restart policies
- Custom MySQL port (3307)

### 4. Environment Configuration (`.env.production`)
- Database credentials
- Security keys and secrets
- Email configuration
- Domain settings

### 5. Nginx Configuration (`nginx-ssl.conf`)
- SSL termination
- Reverse proxy to backend
- Security headers
- Rate limiting

## 🔐 Security Features

### Database Security
- Custom port (3307) instead of default 3306
- Strong passwords with special characters
- Connection only from application containers
- Regular backup schedule

### Application Security
- Non-root containers
- Security headers (HSTS, CSP, etc.)
- Rate limiting on API endpoints
- CORS configuration
- JWT token authentication

### SSL/TLS Security
- TLS 1.2+ only
- Strong cipher suites
- OCSP stapling
- HTTP to HTTPS redirect

## 📁 Directory Structure

```
lawvriksh-deployment/
├── Dockerfile.frontend          # Frontend container
├── Dockerfile.backend           # Backend container
├── docker-compose.yml           # Service orchestration
├── .env.production             # Environment variables
├── nginx.conf                  # Nginx main config
├── default.conf               # Nginx server config
├── nginx-ssl.conf             # SSL-enabled Nginx config
├── deploy.sh                  # Deployment script
├── logs/                      # Application logs
│   ├── mysql/
│   ├── redis/
│   ├── backend/
│   ├── frontend/
│   ├── celery/
│   └── celery-beat/
├── cache/                     # Application cache
├── uploads/                   # File uploads
└── ssl/                       # SSL certificates
    ├── certs/
    └── private/
```

## 🚀 Deployment Steps

### 1. Prepare Environment
```bash
# Clone repository
git clone <your-repo-url>
cd lawvriksh-deployment

# Copy environment file
cp .env.production .env

# Edit environment variables
nano .env
```

### 2. SSL Certificates

#### Option A: Let's Encrypt (Recommended)
```bash
# Install Certbot
sudo apt install certbot

# Generate certificates
sudo certbot certonly --standalone -d lawvriksh.com -d www.lawvriksh.com

# Copy certificates
sudo cp /etc/letsencrypt/live/lawvriksh.com/fullchain.pem ssl/certs/lawvriksh.crt
sudo cp /etc/letsencrypt/live/lawvriksh.com/privkey.pem ssl/private/lawvriksh.key
sudo chown $USER:$USER ssl/certs/lawvriksh.crt ssl/private/lawvriksh.key
```

#### Option B: Self-Signed (Development)
```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/private/lawvriksh.key \
  -out ssl/certs/lawvriksh.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=lawvriksh.com"
```

### 3. Deploy Application
```bash
# Make deployment script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

### 4. Verify Deployment
```bash
# Check service status
docker-compose ps

# Check logs
docker-compose logs -f

# Test endpoints
curl -k https://lawvriksh.com/health
curl -k https://lawvriksh.com/api/health
```

## 🔍 Monitoring and Maintenance

### Health Checks
```bash
# Check all services
docker-compose ps

# Check specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mysql
```

### Database Maintenance
```bash
# Backup database
docker-compose exec mysql mysqldump -u root -p lawvriksh_prod > backup.sql

# Restore database
docker-compose exec -T mysql mysql -u root -p lawvriksh_prod < backup.sql

# Access MySQL shell
docker-compose exec mysql mysql -u root -p
```

### Updates and Scaling
```bash
# Update application
git pull
docker-compose build --no-cache
docker-compose up -d

# Scale services
docker-compose up -d --scale backend=3 --scale celery-worker=2
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Stop conflicting services
sudo systemctl stop apache2
sudo systemctl stop nginx
```

#### 2. Permission Denied
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
chmod +x deploy.sh
```

#### 3. Database Connection Failed
```bash
# Check MySQL logs
docker-compose logs mysql

# Verify environment variables
docker-compose exec backend env | grep DB_
```

#### 4. SSL Certificate Issues
```bash
# Verify certificate files
ls -la ssl/certs/
ls -la ssl/private/

# Test certificate
openssl x509 -in ssl/certs/lawvriksh.crt -text -noout
```

### Log Locations
- **Application Logs**: `./logs/`
- **Docker Logs**: `docker-compose logs [service]`
- **System Logs**: `/var/log/`

## 📊 Performance Optimization

### Resource Limits
The docker-compose.yml includes resource limits:
- **MySQL**: 1GB RAM, 0.5 CPU
- **Backend**: 1GB RAM, 0.5 CPU
- **Frontend**: 256MB RAM, 0.25 CPU
- **Redis**: 256MB RAM, 0.25 CPU

### Scaling Recommendations
- **Small Traffic** (< 1000 users): Default configuration
- **Medium Traffic** (1000-10000 users): Scale backend to 3 instances
- **High Traffic** (> 10000 users): Add load balancer, scale all services

## 🔒 Security Checklist

- [ ] Strong passwords in .env file
- [ ] SSL certificates properly configured
- [ ] Firewall configured (only ports 80, 443, 22 open)
- [ ] Regular security updates
- [ ] Database backups scheduled
- [ ] Log monitoring enabled
- [ ] Rate limiting configured
- [ ] CORS properly set up

## 📞 Support

For deployment issues or questions:
1. Check the troubleshooting section
2. Review Docker logs
3. Verify environment configuration
4. Contact the development team

---

**Last Updated**: January 2025
**Version**: 1.0.0
