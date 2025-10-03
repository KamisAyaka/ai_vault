#!/bin/bash

# AI Vault Backend Startup Script

set -e

echo "🚀 Starting AI Vault Backend..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp env.example .env
    echo "📝 Please update .env file with your configuration before running again."
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

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21 or later."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
REQUIRED_VERSION="1.21"
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Go version $GO_VERSION is not supported. Please install Go 1.21 or later."
    exit 1
fi

echo "✅ Go version $GO_VERSION is supported"

# Install dependencies
echo "📦 Installing dependencies..."
go mod tidy

# Build the application
echo "🔨 Building application..."
go build -o ai-vault-backend main.go

echo "✅ Build completed successfully"

# Start the application
echo "🎯 Starting AI Vault Backend on port ${SERVER_PORT:-8080}..."
./ai-vault-backend
