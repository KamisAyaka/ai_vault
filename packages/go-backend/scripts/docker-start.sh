#!/bin/bash

# AI Vault Backend Docker Startup Script

set -e

echo "🐳 Starting AI Vault Backend with Docker..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp env.example .env
    echo "📝 Please update .env file with your configuration before running again."
    echo "   Especially update the blockchain configuration:"
    echo "   - PRIVATE_KEY"
    echo "   - VAULT_MANAGER_ADDRESS"
    echo "   - WETH_ADDRESS"
    echo "   - USDC_ADDRESS"
    echo "   - DAI_ADDRESS"
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

# Check if required environment variables are set
if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
    echo "❌ Please set PRIVATE_KEY in .env file"
    exit 1
fi

if [ -z "$VAULT_MANAGER_ADDRESS" ] || [ "$VAULT_MANAGER_ADDRESS" = "0x..." ]; then
    echo "❌ Please set VAULT_MANAGER_ADDRESS in .env file"
    exit 1
fi

if [ -z "$WETH_ADDRESS" ] || [ "$WETH_ADDRESS" = "0x..." ]; then
    echo "❌ Please set WETH_ADDRESS in .env file"
    exit 1
fi

echo "✅ Environment variables validated"

# Stop existing containers if running
echo "🛑 Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Build and start services
echo "🔨 Building and starting services..."
docker-compose up --build -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Check API health
echo "🏥 Checking API health..."
sleep 5
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ API is healthy and running on http://localhost:8080"
    echo "📚 API Documentation:"
    echo "   - Health Check: GET http://localhost:8080/health"
    echo "   - Strategies: GET http://localhost:8080/api/v1/strategies"
    echo "   - Vaults: GET http://localhost:8080/api/v1/vaults"
    echo "   - Executions: GET http://localhost:8080/api/v1/executions"
else
    echo "❌ API health check failed. Check logs with: docker-compose logs api"
fi

echo "🎉 AI Vault Backend is running!"
echo "📋 Useful commands:"
echo "   - View logs: docker-compose logs -f"
echo "   - Stop services: docker-compose down"
echo "   - Restart API: docker-compose restart api"
echo "   - View database: docker-compose exec postgres psql -U ai_vault -d ai_vault"
