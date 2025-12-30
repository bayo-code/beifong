# Docker Setup Guide for Beifong

This guide explains how to run Beifong using Docker and Docker Compose.

## Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- At least 4GB of available RAM
- 10GB of free disk space

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/arun477/beifong.git
cd beifong
```

### 2. Configure Environment Variables

Create a `.env` file in the project root by copying the example:

```bash
cp .env.example .env
```

Edit the `.env` file and add your API keys:

```env
# Required
OPENAI_API_KEY=your_openai_api_key_here

# Optional
ELEVENSLAB_API_KEY=your_elevenlabs_api_key_here
SLACK_BOT_TOKEN=xoxb-your-bot-token
SLACK_APP_TOKEN=xapp-your-app-token
```

### 3. Build and Start Services

```bash
# Build all Docker images
docker-compose build

# Start all services
docker-compose up -d
```

This will start:
- Redis (database)
- Backend API (port 8000)
- Scheduler (background tasks)
- Celery Worker (AI chat processing)
- Frontend (port 3000)

### 4. Access the Application

- **Frontend UI**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

### 5. Bootstrap Demo Data (Optional)

To populate the system with sample data:

```bash
docker-compose exec backend python bootstrap_demo.py
```

## Service Management

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f scheduler
docker-compose logs -f celery-worker
docker-compose logs -f frontend
```

### Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart backend
```

### Check Service Status

```bash
docker-compose ps
```

## Data Persistence

The following data is persisted in Docker volumes:

- `databases/` - SQLite databases
- `podcasts/` - Generated podcasts and audio files
- `browsers/` - Playwright browser sessions
- `redis-data` - Redis database

To backup this data:

```bash
# Create backups directory
mkdir -p backups

# Backup databases
docker cp beifong-backend:/app/beifong/databases ./backups/

# Backup podcasts
docker cp beifong-backend:/app/beifong/podcasts ./backups/
```

## Troubleshooting

### Services Not Starting

Check logs for errors:
```bash
docker-compose logs
```

### Port Already in Use

If ports 3000 or 8000 are already in use, edit `docker-compose.yml`:

```yaml
services:
  backend:
    ports:
      - "8080:8000"  # Change 8000 to 8080

  frontend:
    ports:
      - "3001:3000"  # Change 3000 to 3001
```

### Redis Connection Issues

Ensure Redis is healthy:
```bash
docker-compose exec redis redis-cli ping
```

Should return `PONG`.

### Playwright/Browser Issues

If browser automation fails, rebuild the backend image:

```bash
docker-compose build --no-cache backend
docker-compose up -d backend
```

### Permission Issues

If you encounter permission issues with volumes:

```bash
# Linux/Mac
sudo chown -R $USER:$USER ./beifong/databases ./beifong/podcasts ./beifong/browsers
```

## Development Mode

For development with hot-reloading:

```bash
# Start only infrastructure services
docker-compose up -d redis

# Run backend locally
cd beifong
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py

# Run frontend locally (in another terminal)
cd web
npm install
npm start
```

## Production Deployment

For production deployment:

1. Use environment-specific `.env` file
2. Configure proper reverse proxy (Nginx/Traefik)
3. Enable HTTPS with SSL certificates
4. Set up proper backup strategy
5. Configure resource limits in `docker-compose.yml`:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

## Updating the Application

```bash
# Pull latest changes
git pull

# Rebuild images
docker-compose build

# Restart services
docker-compose up -d
```

## Advanced Configuration

### Custom Network Access

To access from other machines on your network:

```bash
# Edit docker-compose.yml backend ports
ports:
  - "0.0.0.0:8000:8000"
```

### Add Additional Services

You can add more services like PostgreSQL or monitoring tools by editing `docker-compose.yml`.

## Getting Help

- Check the main [README.md](readme.md) for detailed feature documentation
- Review logs: `docker-compose logs`
- GitHub Issues: https://github.com/arun477/beifong/issues

## Cleaning Up

To completely remove all Beifong containers, volumes, and images:

```bash
# Stop and remove containers and volumes
docker-compose down -v

# Remove images
docker rmi beifong-backend beifong-frontend

# Remove unused Docker resources
docker system prune -a
```
