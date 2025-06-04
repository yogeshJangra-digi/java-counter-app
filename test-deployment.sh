#!/bin/bash

# Test script for Java Counter App EC2 deployment
# This script tests the deployed Java backend and webhook services

set -e

# Configuration
EC2_HOST="ubuntu@ec2-15-206-100-79.ap-south-1.compute.amazonaws.com"
KEY_FILE="devops-poc.pem"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    print_error "Key file $KEY_FILE not found!"
    exit 1
fi

chmod 600 "$KEY_FILE"

# Get EC2 public IP
print_status "Getting EC2 public IP..."
EC2_IP="15.206.100.79"

print_status "EC2 Public IP: $EC2_IP"

print_header "Testing Java Counter App Services"

# Test frontend endpoint
print_status "Testing Java frontend endpoint..."
if curl -s "http://$EC2_IP:3000" > /dev/null; then
    print_status "✓ Java Frontend service is responding"
    echo "Frontend is accessible at: http://$EC2_IP:3000"
    echo ""
else
    print_error "✗ Java Frontend service is not responding"
fi

# Test backend health endpoint
print_status "Testing Java backend health endpoint..."
if curl -s "http://$EC2_IP:8080/health" > /dev/null; then
    print_status "✓ Java Backend service is healthy"
    echo "Backend health response:"
    curl -s "http://$EC2_IP:8080/health" | jq . 2>/dev/null || curl -s "http://$EC2_IP:8080/health"
    echo ""
else
    print_error "✗ Java Backend service is not responding"
fi

# Test webhook health endpoint
print_status "Testing Java webhook health endpoint..."
if curl -s "http://$EC2_IP:8081/health" > /dev/null; then
    print_status "✓ Java Webhook service is healthy"
    echo "Webhook health response:"
    curl -s "http://$EC2_IP:8081/health" | jq . 2>/dev/null || curl -s "http://$EC2_IP:8081/health"
    echo ""
else
    print_error "✗ Java Webhook service is not responding"
fi

# Test counter API endpoints
print_status "Testing Java Counter API endpoints..."

# Get counter
print_status "Testing GET /api/counter..."
counter_response=$(curl -s "http://$EC2_IP:8080/api/counter" || echo "Failed")
if [ "$counter_response" != "Failed" ]; then
    print_status "✓ Counter GET successful: $counter_response"
else
    print_error "✗ Counter GET failed"
fi

# Increment counter
print_status "Testing POST /api/counter/increment..."
increment_response=$(curl -s -X POST "http://$EC2_IP:8080/api/counter/increment" || echo "Failed")
if [ "$increment_response" != "Failed" ]; then
    print_status "✓ Counter increment successful: $increment_response"
else
    print_error "✗ Counter increment failed"
fi

# Test webhook endpoint with test payload
print_status "Testing Java webhook endpoint with test payload..."
webhook_response=$(curl -s -X POST "http://$EC2_IP:8081/webhook?test=true" \
    -H "Content-Type: application/json" \
    -d '{"test": true}' || echo "Failed")

if [ "$webhook_response" != "Failed" ]; then
    print_status "✓ Java Webhook test successful"
    echo "Webhook response: $webhook_response"
else
    print_error "✗ Java Webhook test failed"
fi

print_header "Java Counter App Service URLs"
echo "Frontend: http://$EC2_IP:3000"
echo "Backend API: http://$EC2_IP:8080"
echo "Backend Health: http://$EC2_IP:8080/health"
echo "Backend Info: http://$EC2_IP:8080/info"
echo "Counter API: http://$EC2_IP:8080/api/counter"
echo "Webhook Service: http://$EC2_IP:8081"
echo "Webhook Health: http://$EC2_IP:8081/health"
echo "GitHub Webhook URL: http://$EC2_IP:8081/webhook"

print_header "API Test Commands"
echo "# Get counter value"
echo "curl http://$EC2_IP:8080/api/counter"
echo ""
echo "# Increment counter"
echo "curl -X POST http://$EC2_IP:8080/api/counter/increment"
echo ""
echo "# Decrement counter"
echo "curl -X POST http://$EC2_IP:8080/api/counter/decrement"
echo ""
echo "# Reset counter"
echo "curl -X POST http://$EC2_IP:8080/api/counter/reset"
echo ""
echo "# Test webhook"
echo "curl -X POST http://$EC2_IP:8081/webhook?test=true -H 'Content-Type: application/json' -d '{\"test\": true}'"

print_header "Next Steps"
echo "1. Open the frontend in your browser: http://$EC2_IP:3000"
echo "2. Update your GitHub webhook URL to: http://$EC2_IP:8081/webhook"
echo "3. Make sure your EC2 security group allows inbound traffic on ports 3000, 8080, and 8081"
echo "4. Test by making a commit to your repository"
echo "5. Monitor logs with: ./manage-backend.sh logs"

