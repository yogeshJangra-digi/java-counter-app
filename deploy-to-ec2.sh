#!/bin/bash

# EC2 Deployment Script for Java Counter Application
# This script deploys the Java webhook service and backend to Ubuntu EC2 instance

set -e  # Exit on any error

# Configuration
EC2_HOST="ubuntu@ec2-15-206-100-79.ap-south-1.compute.amazonaws.com"
KEY_FILE="devops-poc.pem"
REMOTE_DIR="/home/ubuntu/java-counter-app"
GITHUB_REPO="https://github.com/yogeshJangra-digi/java-counter-app.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    print_error "Key file $KEY_FILE not found!"
    print_error "Please ensure the key file is in the parent directory."
    exit 1
fi

# Set correct permissions for key file
chmod 600 "$KEY_FILE"

print_status "Starting Java Counter App deployment to EC2 instance..."

# Test SSH connection
print_status "Testing SSH connection..."
if ! ssh -i "$KEY_FILE" -o ConnectTimeout=10 "$EC2_HOST" "echo 'SSH connection successful'"; then
    print_error "Failed to connect to EC2 instance"
    exit 1
fi

# Clone repository from GitHub
print_status "Cloning Java Counter App repository from GitHub..."
ssh -i "$KEY_FILE" "$EC2_HOST" << EOF
    # Remove existing directory if it exists
    if [ -d "$REMOTE_DIR" ]; then
        echo "Removing existing java-counter-app directory..."
        rm -rf $REMOTE_DIR
    fi

    # Clone the repository
    echo "Cloning repository from GitHub..."
    cd /home/ubuntu
    git clone $GITHUB_REPO java-counter-app

    # Navigate to the java-counter-app subdirectory
    cd java-counter-app/java-counter-app

    # Configure git for webhook operations
    git config pull.rebase false
    git config user.name "yogesh"
    git config user.email "yogeshjangra@digitalmettle.com"

    echo "Java Counter App repository cloned and configured successfully"
EOF

# Install Docker, Docker Compose, and Java on EC2 if not already installed
print_status "Setting up Docker, Java, and Maven on EC2..."
ssh -i "$KEY_FILE" "$EC2_HOST" << 'EOF'
    # Update package index
    sudo apt-get update

    # Install Docker if not already installed
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        echo "Docker installed successfully"
    else
        echo "Docker is already installed"
    fi

    # Install Docker Compose if not already installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully"
    else
        echo "Docker Compose is already installed"
    fi

    # Install Git if not already installed
    if ! command -v git &> /dev/null; then
        echo "Installing Git..."
        sudo apt-get install -y git
    else
        echo "Git is already installed"
    fi

    
EOF

print_status "Setup completed"

# Get the public IP of the EC2 instance first
print_status "Getting EC2 public IP for configuration..."
EC2_IP=$(ssh -i "$KEY_FILE" "$EC2_HOST" "curl -s http://169.254.169.254/latest/meta-data/public-ipv4")

# Deploy the application
print_status "Deploying Java Counter App..."
ssh -i "$KEY_FILE" "$EC2_HOST" << EOF
    cd $REMOTE_DIR/java-counter-app

    # Stop existing containers if running
    if [ -f docker-compose.prod.yml ]; then
        echo "Stopping existing containers..."
        docker-compose -f docker-compose.prod.yml down || true
    fi

    # Update frontend .env with actual EC2 IP
    echo "Configuring frontend API URL..."
    cat > frontend/.env << 'FRONTENDEOF'
PORT=3000
REACT_APP_API_URL=http://$EC2_IP:8080/api
FRONTENDEOF

    # Update docker-compose.prod.yml with actual EC2 IP
    sed -i 's/EC2_PUBLIC_IP/$EC2_IP/g' docker-compose.prod.yml

    # Create .env file for production
    cat > .env << 'ENVEOF'
WEBHOOK_SECRET=your-java-production-webhook-secret
GIT_BRANCH=main
DEBUG=false
SPRING_PROFILES_ACTIVE=production
ENVEOF

    # Build and start containers
    echo "Building and starting Java containers (backend + frontend + webhook)..."
    docker-compose -f docker-compose.prod.yml up -d --build

    # Wait for services to start
    echo "Waiting for services to start..."
    sleep 90

    # Check container status
    echo "Container status:"
    docker-compose -f docker-compose.prod.yml ps

    # Show logs
    echo "Recent logs:"
    docker-compose -f docker-compose.prod.yml logs --tail=20
EOF

print_status "Deployment completed!"

print_status "Java Counter App URLs:"
echo "  Frontend: http://$EC2_IP:3000"
echo "  Backend API: http://$EC2_IP:8080"
echo "  Backend Health: http://$EC2_IP:8080/health"
echo "  Webhook Service: http://$EC2_IP:8081"
echo "  Webhook Health: http://$EC2_IP:8081/health"

print_status "Webhook URL for GitHub:"
echo "  http://$EC2_IP:8081/webhook"

print_warning "Make sure to:"
print_warning "1. Update your GitHub webhook URL to: http://$EC2_IP:8081/webhook"
print_warning "2. Configure your EC2 security group to allow inbound traffic on ports 3000, 8080, and 8081"
print_warning "3. Update the WEBHOOK_SECRET in the .env file on the server"

print_status "Java Counter App deployment script completed successfully!"
