#!/bin/bash

# EC2 Java Backend Management Script
# This script provides easy management commands for the Java backend deployment

set -e

# Configuration
EC2_HOST="ubuntu@ec2-15-206-100-79.ap-south-1.compute.amazonaws.com"
KEY_FILE="devops-poc.pem"
REMOTE_DIR="/home/ubuntu/java-counter-app/java-counter-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if key file exists
check_key_file() {
    if [ ! -f "$KEY_FILE" ]; then
        print_error "Key file $KEY_FILE not found!"
        exit 1
    fi
    chmod 600 "$KEY_FILE"
}

# Execute command on EC2
exec_remote() {
    ssh -i "$KEY_FILE" "$EC2_HOST" "cd $REMOTE_DIR && $1"
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      - Show container status"
    echo "  logs        - Show application logs"
    echo "  restart     - Restart all containers"
    echo "  stop        - Stop all containers"
    echo "  start       - Start all containers"
    echo "  rebuild     - Rebuild and restart containers"
    echo "  shell       - Connect to EC2 instance"
    echo "  webhook     - Show webhook logs"
    echo "  backend     - Show backend logs"
    echo "  frontend    - Show frontend logs"
    echo "  health      - Check application health"
    echo "  update      - Update code and restart"
    echo "  cleanup     - Clean up unused Docker resources"
    echo "  test        - Test webhook endpoint"
}

# Show container status
show_status() {
    print_header "Java Container Status"
    exec_remote "docker-compose -f docker-compose.prod.yml ps"
}

# Show logs
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        print_header "All Java Application Logs"
        exec_remote "docker-compose -f docker-compose.prod.yml logs --tail=50"
    else
        print_header "$service Logs"
        exec_remote "docker-compose -f docker-compose.prod.yml logs --tail=50 $service"
    fi
}

# Restart containers
restart_containers() {
    print_header "Restarting Java Containers"
    exec_remote "docker-compose -f docker-compose.prod.yml restart"
    print_status "Java containers restarted"
}

# Stop containers
stop_containers() {
    print_header "Stopping Java Containers"
    exec_remote "docker-compose -f docker-compose.prod.yml down"
    print_status "Java containers stopped"
}

# Start containers
start_containers() {
    print_header "Starting Java Containers"
    exec_remote "docker-compose -f docker-compose.prod.yml up -d"
    print_status "Java containers started"
}

# Rebuild containers
rebuild_containers() {
    print_header "Rebuilding Java Containers"
    exec_remote "docker-compose -f docker-compose.prod.yml down"
    exec_remote "docker-compose -f docker-compose.prod.yml up -d --build"
    print_status "Java containers rebuilt and started"
}

# Connect to EC2 shell
connect_shell() {
    print_status "Connecting to EC2 instance..."
    ssh -i "$KEY_FILE" "$EC2_HOST"
}

# Check application health
check_health() {
    print_header "Java Application Health Check"

    # Get EC2 public IP
    EC2_IP=$(exec_remote "curl -s http://169.254.169.254/latest/meta-data/public-ipv4")

    echo "Testing Java endpoints:"
    echo "  Frontend: http://$EC2_IP:3000"
    echo "  Backend Health: http://$EC2_IP:8080/health"
    echo "  Webhook Health: http://$EC2_IP:8081/health"

    # Test webhook health endpoint
    if curl -s "http://$EC2_IP:8081/health" > /dev/null; then
        print_status "✓ Java Webhook service is healthy"
    else
        print_error "✗ Java Webhook service is not responding"
    fi

    # Test backend endpoint
    if curl -s "http://$EC2_IP:8080/health" > /dev/null; then
        print_status "✓ Java Backend service is healthy"
    else
        print_error "✗ Java Backend service is not responding"
    fi

    # Test frontend endpoint
    if curl -s "http://$EC2_IP:3000" > /dev/null; then
        print_status "✓ Java Frontend service is responding"
    else
        print_error "✗ Java Frontend service is not responding"
    fi
}

# Update code and restart
update_code() {
    print_header "Updating Java Code"

    # Pull latest code from GitHub
    print_status "Pulling latest code from GitHub..."
    exec_remote "git fetch origin main && git reset --hard origin/main"

    # Restart containers
    restart_containers
    print_status "Java code updated and containers restarted"
}

# Cleanup Docker resources
cleanup_docker() {
    print_header "Cleaning Up Docker Resources"
    exec_remote "docker system prune -f"
    exec_remote "docker volume prune -f"
    print_status "Docker cleanup completed"
}

# Test webhook endpoint
test_webhook() {
    print_header "Testing Java Webhook Endpoint"

    # Get EC2 public IP
    EC2_IP=$(exec_remote "curl -s http://169.254.169.254/latest/meta-data/public-ipv4")

    print_status "Testing Java webhook endpoint: http://$EC2_IP:8081/webhook?test=true"

    if curl -X POST "http://$EC2_IP:8081/webhook?test=true" \
        -H "Content-Type: application/json" \
        -d '{"test": true}'; then
        print_status "✓ Java Webhook test successful"
    else
        print_error "✗ Java Webhook test failed"
    fi
}

# Main script logic
check_key_file

case "${1:-}" in
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "webhook")
        show_logs "webhook"
        ;;
    "backend")
        show_logs "backend"
        ;;
    "frontend")
        show_logs "frontend"
        ;;
    "restart")
        restart_containers
        ;;
    "stop")
        stop_containers
        ;;
    "start")
        start_containers
        ;;
    "rebuild")
        rebuild_containers
        ;;
    "shell")
        connect_shell
        ;;
    "health")
        check_health
        ;;
    "update")
        update_code
        ;;
    "cleanup")
        cleanup_docker
        ;;
    "test")
        test_webhook
        ;;
    *)
        show_usage
        ;;
esac
