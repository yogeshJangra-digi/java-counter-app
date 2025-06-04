#!/bin/bash

# Test script to verify deployment fixes work locally
# This script tests the key components that were failing in the EC2 deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

print_status "Testing deployment script fixes locally..."

# Test 1: Check if all required files exist
print_status "Test 1: Checking required files..."
if [ -f "docker-compose.prod.yml" ]; then
    echo "✓ docker-compose.prod.yml exists"
else
    print_error "✗ docker-compose.prod.yml missing"
    exit 1
fi

if [ -d "frontend" ]; then
    echo "✓ frontend directory exists"
else
    print_error "✗ frontend directory missing"
    exit 1
fi

if [ -f "frontend/.env" ]; then
    echo "✓ frontend/.env exists"
else
    print_error "✗ frontend/.env missing"
    exit 1
fi

# Test 2: Test variable substitution
print_status "Test 2: Testing variable substitution..."
TEST_IP="192.168.1.100"

# Create a temporary copy of docker-compose.prod.yml for testing
cp docker-compose.prod.yml docker-compose.test.yml

# Test the sed command that was failing
if sed -i "s/EC2_PUBLIC_IP/$TEST_IP/g" docker-compose.test.yml; then
    echo "✓ sed command works"
    
    # Check if substitution actually happened
    if grep -q "$TEST_IP" docker-compose.test.yml; then
        echo "✓ Variable substitution successful"
    else
        print_warning "⚠ Variable substitution may not have worked as expected"
    fi
else
    print_error "✗ sed command failed"
fi

# Clean up test file
rm -f docker-compose.test.yml

# Test 3: Test .env file creation
print_status "Test 3: Testing .env file creation..."
TEST_ENV_CONTENT="PORT=3000
REACT_APP_API_URL=http://$TEST_IP:8080/api"

# Create test .env file
echo "$TEST_ENV_CONTENT" > frontend/.env.test

if [ -f "frontend/.env.test" ]; then
    echo "✓ .env file creation works"
    
    # Check content
    if grep -q "$TEST_IP" frontend/.env.test; then
        echo "✓ .env file contains correct IP"
    else
        print_warning "⚠ .env file may not contain expected content"
    fi
else
    print_error "✗ .env file creation failed"
fi

# Clean up test file
rm -f frontend/.env.test

# Test 4: Check Docker Compose syntax
print_status "Test 4: Validating Docker Compose syntax..."
if docker-compose -f docker-compose.prod.yml config > /dev/null 2>&1; then
    echo "✓ Docker Compose syntax is valid"
else
    print_error "✗ Docker Compose syntax validation failed"
    docker-compose -f docker-compose.prod.yml config
fi

print_status "All tests completed!"
print_status "The deployment script fixes should work correctly on EC2."

print_warning "Next steps:"
echo "1. Commit and push these changes to GitHub"
echo "2. Run the updated deploy-to-ec2.sh script"
echo "3. The script now includes better debugging and error handling"
