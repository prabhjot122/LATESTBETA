#!/bin/bash

# LawVriksh Production Deployment Script
# For Kali Linux VPS with Docker
# Domain: https://lawvriksh.com

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for security reasons"
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose is not installed. Please install Docker Compose first."
fi

log "Starting LawVriksh production deployment..."

# Create necessary directories
log "Creating necessary directories..."
mkdir -p logs/{mysql,redis,backend,frontend,celery,celery-beat}
mkdir -p cache
mkdir -p uploads
mkdir -p ssl/{certs,private}

# Set proper permissions
chmod 755 logs cache uploads
chmod 700 ssl/private
chmod 755 ssl/certs

# Check environment files
log "Checking environment files..."
if [ ! -f .env.production ]; then
    error "Frontend .env.production file not found!"
fi

if [ ! -f ../.env.production ]; then
    error "Backend .env.production file not found!"
fi

# Validate backend environment file
log "Validating backend environment configuration..."
if ! grep -q "MYSQL_ROOT_PASSWORD=" ../.env.production; then
    error "MYSQL_ROOT_PASSWORD not found in backend .env.production file"
fi

if ! grep -q "JWT_SECRET_KEY=" ../.env.production; then
    error "JWT_SECRET_KEY not found in backend .env.production file"
fi

# Validate frontend environment file
log "Validating frontend environment configuration..."
if ! grep -q "VITE_API_URL=" .env.production; then
    error "VITE_API_URL not found in frontend .env.production file"
fi

# Check SSL certificates
log "Checking SSL certificates..."
if [ ! -f ssl/certs/lawvriksh.crt ] || [ ! -f ssl/private/lawvriksh.key ]; then
    warn "SSL certificates not found!"
    warn "Please place your SSL certificates in:"
    warn "  - ssl/certs/lawvriksh.crt"
    warn "  - ssl/private/lawvriksh.key"
    warn "Or use Let's Encrypt to generate them."
    read -p "Press Enter after placing SSL certificates..."
fi

# Stop existing containers
log "Stopping existing containers..."
docker-compose down --remove-orphans || true

# Remove old images (optional)
read -p "Do you want to remove old Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Removing old Docker images..."
    docker system prune -f
fi

# Build and start services
log "Building and starting services..."
docker-compose up -d --build

# Wait for services to be healthy
log "Waiting for services to be healthy..."
sleep 30

# Check service health
log "Checking service health..."
services=("mysql" "redis" "backend" "frontend")
for service in "${services[@]}"; do
    if docker-compose ps | grep -q "${service}.*Up.*healthy"; then
        log "✓ $service is healthy"
    else
        warn "✗ $service is not healthy"
        docker-compose logs $service
    fi
done

# Run database migrations
log "Running database migrations..."
docker-compose exec -T backend alembic upgrade head || warn "Migration failed - check if database is properly initialized"

# Display deployment information
log "Deployment completed successfully!"
echo
echo -e "${BLUE}=== DEPLOYMENT INFORMATION ===${NC}"
echo -e "${BLUE}Frontend URL:${NC} https://lawvriksh.com"
echo -e "${BLUE}API URL:${NC} https://lawvriksh.com/api"
echo -e "${BLUE}MySQL Port:${NC} 3307 (custom port for security)"
echo -e "${BLUE}Redis Port:${NC} 6379"
echo
echo -e "${BLUE}=== USEFUL COMMANDS ===${NC}"
echo -e "${BLUE}View logs:${NC} docker-compose logs -f [service_name]"
echo -e "${BLUE}Restart service:${NC} docker-compose restart [service_name]"
echo -e "${BLUE}Stop all:${NC} docker-compose down"
echo -e "${BLUE}Update:${NC} docker-compose pull && docker-compose up -d"
echo
echo -e "${GREEN}Deployment completed! Your application should be available at https://lawvriksh.com${NC}"
