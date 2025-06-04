# Java Counter App

A Java-based counter application with Spring Boot backend, React frontend, and webhook service for automatic deployments.

## Project Structure

```
java-counter-app/
├── backend/                    # Spring Boot backend
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── frontend/                   # React frontend
│   ├── src/
│   ├── package.json
│   └── Dockerfile
├── webhook-service/            # Java webhook service
│   ├── src/
│   ├── pom.xml
│   └── Dockerfile
├── docker-compose.yml          # Local development
├── docker-compose.prod.yml     # Production deployment
├── deploy-to-ec2.sh           # Deployment script
├── manage-backend.sh          # Management script
└── DEPLOYMENT_GUIDE.md        # Deployment instructions
```

## Quick Start

### Local Development
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### Production Deployment
```bash
# Deploy to EC2
./deploy-to-ec2.sh

# Manage services
./manage-backend.sh status
./manage-backend.sh logs
```

## Services

- **Backend**: Spring Boot REST API (Port 8080)
- **Frontend**: React application (Port 3000)
- **Webhook**: Java webhook service (Port 8081)

## Features

- ✅ Docker volume mounting for hot reloading
- ✅ Automatic deployment via GitHub webhooks
- ✅ Production-ready configuration
- ✅ Health check endpoints
- ✅ CORS configuration
- ✅ Environment-based configuration
