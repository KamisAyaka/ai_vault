#!/bin/bash

# AI Vault Backend - cURL Examples
# This script demonstrates how to interact with the API using cURL

set -e

API_BASE="http://localhost:8080"

echo "🚀 AI Vault Backend - cURL Examples"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if API is running
check_api() {
    print_info "Checking API health..."
    if curl -s -f "$API_BASE/health" > /dev/null; then
        print_status "API is running"
    else
        print_error "API is not running. Please start the backend first."
        exit 1
    fi
}

# Health check
health_check() {
    print_info "Health Check"
    echo "GET $API_BASE/health"
    curl -s "$API_BASE/health" | jq '.' || echo "Response: $(curl -s "$API_BASE/health")"
    echo ""
}

# Create a strategy
create_strategy() {
    print_info "Creating AI Strategy"
    echo "POST $API_BASE/api/v1/strategies"
    
    STRATEGY_RESPONSE=$(curl -s -X POST "$API_BASE/api/v1/strategies" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "AI Conservative Strategy",
            "description": "Conservative allocation for stable returns",
            "allocations": [
                {
                    "adapter_index": 0,
                    "percentage": 700,
                    "protocol": "Aave"
                },
                {
                    "adapter_index": 1,
                    "percentage": 300,
                    "protocol": "UniswapV2"
                }
            ]
        }')
    
    echo "$STRATEGY_RESPONSE" | jq '.' || echo "$STRATEGY_RESPONSE"
    
    # Extract strategy ID for later use
    STRATEGY_ID=$(echo "$STRATEGY_RESPONSE" | jq -r '.strategy.id' 2>/dev/null || echo "")
    if [ "$STRATEGY_ID" != "null" ] && [ -n "$STRATEGY_ID" ]; then
        print_status "Strategy created with ID: $STRATEGY_ID"
        echo "STRATEGY_ID=$STRATEGY_ID" > /tmp/strategy_id
    else
        print_warning "Could not extract strategy ID"
    fi
    echo ""
}

# List strategies
list_strategies() {
    print_info "Listing Strategies"
    echo "GET $API_BASE/api/v1/strategies"
    curl -s "$API_BASE/api/v1/strategies" | jq '.' || echo "Response: $(curl -s "$API_BASE/api/v1/strategies")"
    echo ""
}

# Get specific strategy
get_strategy() {
    if [ -f /tmp/strategy_id ]; then
        source /tmp/strategy_id
        if [ -n "$STRATEGY_ID" ]; then
            print_info "Getting Strategy Details"
            echo "GET $API_BASE/api/v1/strategies/$STRATEGY_ID"
            curl -s "$API_BASE/api/v1/strategies/$STRATEGY_ID" | jq '.' || echo "Response: $(curl -s "$API_BASE/api/v1/strategies/$STRATEGY_ID")"
            echo ""
        else
            print_warning "No strategy ID available"
        fi
    else
        print_warning "No strategy ID file found"
    fi
}

# List vaults
list_vaults() {
    print_info "Listing Vaults"
    echo "GET $API_BASE/api/v1/vaults"
    curl -s "$API_BASE/api/v1/vaults" | jq '.' || echo "Response: $(curl -s "$API_BASE/api/v1/vaults")"
    echo ""
}

# List executions
list_executions() {
    print_info "Listing Executions"
    echo "GET $API_BASE/api/v1/executions"
    curl -s "$API_BASE/api/v1/executions" | jq '.' || echo "Response: $(curl -s "$API_BASE/api/v1/executions")"
    echo ""
}

# Execute strategy (if vault exists)
execute_strategy() {
    if [ -f /tmp/strategy_id ]; then
        source /tmp/strategy_id
        if [ -n "$STRATEGY_ID" ]; then
            print_info "Executing Strategy (requires vault ID)"
            echo "POST $API_BASE/api/v1/strategies/execute"
            echo "Note: This requires a valid vault ID. Update the VaultID in the request."
            
            # This would need a real vault ID
            curl -s -X POST "$API_BASE/api/v1/strategies/execute" \
                -H "Content-Type: application/json" \
                -d "{
                    \"strategy_id\": \"$STRATEGY_ID\",
                    \"vault_id\": \"00000000-0000-0000-0000-000000000000\"
                }" | jq '.' || echo "Response: $(curl -s -X POST "$API_BASE/api/v1/strategies/execute" -H "Content-Type: application/json" -d "{\"strategy_id\": \"$STRATEGY_ID\", \"vault_id\": \"00000000-0000-0000-0000-000000000000\"}")"
            echo ""
        else
            print_warning "No strategy ID available"
        fi
    else
        print_warning "No strategy ID file found"
    fi
}

# Main execution
main() {
    check_api
    
    health_check
    create_strategy
    list_strategies
    get_strategy
    list_vaults
    list_executions
    execute_strategy
    
    print_status "All examples completed!"
    print_info "Clean up: rm -f /tmp/strategy_id"
}

# Run main function
main
