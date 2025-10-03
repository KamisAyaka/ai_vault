# AI Vault Backend Makefile

.PHONY: help build run test clean docker-build docker-run docker-stop docker-logs install deps

# Default target
help:
	@echo "AI Vault Backend - Available Commands:"
	@echo ""
	@echo "Development:"
	@echo "  install     Install dependencies"
	@echo "  build       Build the application"
	@echo "  run         Run the application locally"
	@echo "  test        Run tests"
	@echo "  clean       Clean build artifacts"
	@echo ""
	@echo "Docker:"
	@echo "  docker-build    Build Docker image"
	@echo "  docker-run      Run with Docker Compose"
	@echo "  docker-stop     Stop Docker containers"
	@echo "  docker-logs     View Docker logs"
	@echo ""
	@echo "Database:"
	@echo "  db-migrate      Run database migrations"
	@echo "  db-reset        Reset database"
	@echo ""
	@echo "Utilities:"
	@echo "  setup-env       Setup environment file"
	@echo "  check-env       Check environment configuration"

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	go mod download
	go mod tidy

# Build the application
build:
	@echo "🔨 Building application..."
	go build -o ai-vault-backend main.go
	@echo "✅ Build completed"

# Run the application
run:
	@echo "🚀 Starting application..."
	@./scripts/start.sh

# Run tests
test:
	@echo "🧪 Running tests..."
	go test -v ./...

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -f ai-vault-backend
	go clean

# Setup environment file
setup-env:
	@echo "⚙️  Setting up environment file..."
	@if [ ! -f .env ]; then \
		cp env.example .env; \
		echo "📝 Created .env file from template"; \
		echo "⚠️  Please update .env with your configuration"; \
	else \
		echo "✅ .env file already exists"; \
	fi

# Check environment configuration
check-env:
	@echo "🔍 Checking environment configuration..."
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found. Run 'make setup-env' first"; \
		exit 1; \
	fi
	@echo "✅ .env file exists"

# Docker commands
docker-build:
	@echo "🐳 Building Docker image..."
	docker build -t ai-vault-backend .

docker-run:
	@echo "🐳 Starting with Docker Compose..."
	@./scripts/docker-start.sh

docker-stop:
	@echo "🛑 Stopping Docker containers..."
	docker-compose down

docker-logs:
	@echo "📋 Viewing Docker logs..."
	docker-compose logs -f

# Database commands
db-migrate:
	@echo "🗄️  Running database migrations..."
	@echo "Note: Migrations run automatically on startup"

db-reset:
	@echo "🗄️  Resetting database..."
	docker-compose down -v
	docker-compose up -d postgres
	@echo "✅ Database reset completed"

# Development setup
dev-setup: setup-env install
	@echo "🎯 Development setup completed!"
	@echo "Next steps:"
	@echo "1. Update .env file with your configuration"
	@echo "2. Run 'make run' to start the application"

# Production build
prod-build: clean install build
	@echo "🏭 Production build completed"

# Quick start
quick-start: setup-env docker-run
	@echo "🎉 Quick start completed!"
