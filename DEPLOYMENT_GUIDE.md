# Java Counter App Deployment Guide

This guide will help you deploy the Java-based counter application with Spring Boot backend and webhook service to your Ubuntu EC2 instance.

## Project Overview

- **Backend**: Spring Boot (Java 17) on port 8080
- **Frontend**: React 18 on port 3000 (production deployment included)
- **Webhook**: Java Spring Boot service on port 8081
- **Database**: In-memory (counter state)
- **Deployment**: Docker + EC2

## Prerequisites

1. **EC2 Instance**: Ubuntu EC2 instance running at `ec2-90-671-267-15.ap-south-1.compute.amazonaws.com`
2. **SSH Key**: `devops-poc.pem` file in the parent directory
3. **Security Group**: EC2 security group configured to allow inbound traffic on ports 3000, 8080, and 8081

## Quick Deployment

### 1. Make scripts executable
```bash
chmod +x deploy-to-ec2.sh
chmod +x manage-backend.sh
```

### 2. Deploy to EC2
```bash
./deploy-to-ec2.sh
```

This script will:
- Install Docker, Docker Compose, Java 17, and Maven on EC2
- Clone your code directly from GitHub to the EC2 instance
- Configure git for webhook operations
- Configure frontend to connect to the production backend
- Build and start the frontend, backend, and webhook containers
- Display the application URLs

### 3. Verify deployment
```bash
./manage-backend.sh status
./manage-backend.sh health
```

## Application URLs

After successful deployment, your services will be available at:

- **Frontend**: `http://EC2_PUBLIC_IP:3000`
- **Backend API**: `http://EC2_PUBLIC_IP:8080`
- **Backend Health**: `http://EC2_PUBLIC_IP:8080/health`
- **Webhook Service**: `http://EC2_PUBLIC_IP:8081`
- **Webhook Health**: `http://EC2_PUBLIC_IP:8081/health`

## API Endpoints

### Backend API (Port 8080)
- `GET /health` - Health check
- `GET /info` - Application info
- `GET /api/counter` - Get current counter value
- `POST /api/counter/increment` - Increment counter
- `POST /api/counter/decrement` - Decrement counter
- `POST /api/counter/reset` - Reset counter to 0

### Webhook API (Port 8081)
- `GET /health` - Webhook health check
- `POST /webhook` - GitHub webhook endpoint

## GitHub Webhook Configuration

1. Go to your GitHub repository settings
2. Navigate to "Webhooks"
3. Add a new webhook with:
   - **Payload URL**: `http://EC2_PUBLIC_IP:8081/webhook`
   - **Content type**: `application/json`
   - **Secret**: Update the `WEBHOOK_SECRET` in the `.env` file on the server
   - **Events**: Select "Just the push event"

## Management Commands

Use the `manage-backend.sh` script for easy management:

```bash
# Show container status
./manage-backend.sh status

# View logs
./manage-backend.sh logs
./manage-backend.sh backend    # Backend logs only
./manage-backend.sh frontend   # Frontend logs only
./manage-backend.sh webhook    # Webhook logs only

# Restart services
./manage-backend.sh restart

# Update code and restart
./manage-backend.sh update

# Test webhook
./manage-backend.sh test

# Connect to EC2 shell
./manage-backend.sh shell

# Check health
./manage-backend.sh health

# Clean up Docker resources
./manage-backend.sh cleanup
```

## Local Development

### Start all services locally
```bash
docker-compose up -d
```

### View logs
```bash
docker-compose logs -f
```

### Access services
- Frontend: http://localhost:3000
- Backend: http://localhost:8080
- Webhook: http://localhost:8081

## How It Works

### Volume Mounting & Hot Reloading
- **Backend**: Spring Boot DevTools enables hot reloading when Java files change
- **Frontend**: React development server with hot reloading
- **Webhook**: Maven Spring Boot plugin with hot reloading

### Webhook Integration
- When GitHub sends a webhook, the webhook service pulls the latest code
- Uses `git fetch` + `git reset --hard` for robust git operations
- Touches Java files to trigger Spring Boot DevTools restart
- Ensures your deployed application stays in sync with your GitHub repository

### Docker Volumes
- **Backend**: `./backend:/app` + Maven cache volume
- **Frontend**: `./frontend:/app` + Node modules volume
- **Webhook**: `.:/workspace` + Maven cache volume

## Environment Configuration

The deployment creates a `.env` file on the server with:

```env
WEBHOOK_SECRET=your-java-production-webhook-secret
GIT_BRANCH=main
DEBUG=false
SPRING_PROFILES_ACTIVE=production
```

## Security Group Configuration

Ensure your EC2 security group allows:

- **Port 22**: SSH access (for deployment)
- **Port 3000**: Frontend access
- **Port 8080**: Backend API access
- **Port 8081**: Webhook service access

## Testing

### Test Backend API
```bash
# Health check
curl http://EC2_PUBLIC_IP:8080/health

# Get counter
curl http://EC2_PUBLIC_IP:8080/api/counter

# Increment counter
curl -X POST http://EC2_PUBLIC_IP:8080/api/counter/increment
```

### Test Webhook
```bash
# Health check
curl http://EC2_PUBLIC_IP:8081/health

# Test webhook
curl -X POST http://EC2_PUBLIC_IP:8081/webhook?test=true \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

## Troubleshooting

### Check container status
```bash
./manage-backend.sh status
```

### View logs
```bash
./manage-backend.sh logs
```

### Test webhook manually
```bash
./manage-backend.sh test
```

### Connect to server
```bash
./manage-backend.sh shell
```

### Rebuild containers
```bash
./manage-backend.sh rebuild
```

## Technology Stack

- **Backend**: Spring Boot 3.2.0, Java 17, Maven
- **Frontend**: React 18, Node.js 18
- **Webhook**: Spring Boot 3.2.0, Java 17
- **Deployment**: Docker, Docker Compose, Ubuntu EC2
- **CI/CD**: GitHub Webhooks, Git automation

## File Structure on EC2

After deployment, your files will be organized as:

```
/home/ubuntu/java-counter-app/java-counter-app/
├── backend/
│   ├── src/main/java/com/example/counter/
│   ├── pom.xml
│   └── Dockerfile
├── frontend/
│   ├── src/
│   ├── package.json
│   └── Dockerfile
├── webhook-service/
│   ├── src/main/java/com/example/webhook/
│   ├── pom.xml
│   └── Dockerfile
├── docker-compose.prod.yml
└── .env
```

## Next Steps

1. Update your GitHub webhook URL to point to your EC2 instance
2. Test the webhook by making a commit to your repository
3. Monitor the logs to ensure everything is working correctly
4. Consider setting up SSL/TLS for production use
5. Set up proper logging and monitoring
