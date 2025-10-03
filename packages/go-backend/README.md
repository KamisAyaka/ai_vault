# AI Vault Backend

This is a Go backend service that enables AI agents to interact with the AI Vault smart contracts on Ethereum. The backend provides REST APIs for creating, managing, and executing investment strategies.

## Features

- **Strategy Management**: Create and manage AI-generated investment strategies
- **Blockchain Integration**: Direct interaction with AI Vault Manager and Vault contracts
- **Execution Tracking**: Monitor strategy executions and transactions
- **Database Persistence**: Store strategies, executions, and vault information
- **REST API**: Clean HTTP API for AI agents to consume

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Agents     │───▶│   Go Backend    │───▶│  Smart Contracts│
│                 │    │                 │    │                 │
│ • Strategy Gen  │    │ • REST API      │    │ • Vault Manager │
│ • Decision      │    │ • Blockchain    │    │ • Vaults        │
│ • Execution     │    │ • Database      │    │ • Adapters      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Quick Start

### Prerequisites

- Go 1.21+
- PostgreSQL
- Ethereum node (local or remote)
- Deployed AI Vault contracts

### Installation

1. Clone the repository and navigate to the backend:
```bash
cd packages/go-backend
```

2. Install dependencies:
```bash
go mod tidy
```

3. Copy environment configuration:
```bash
cp env.example .env
```

4. Update `.env` with your configuration:
```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=ai_vault
DB_PASSWORD=your_password
DB_NAME=ai_vault

# Blockchain
ETH_RPC_URL=http://localhost:8545
PRIVATE_KEY=your_private_key_here
VAULT_MANAGER_ADDRESS=0x...
WETH_ADDRESS=0x...

# Server
SERVER_PORT=8080
LOG_LEVEL=info
```

5. Run the application:
```bash
go run main.go
```

The server will start on `http://localhost:8080`

## API Documentation

### Health Check
```
GET /health
```

### Strategies

#### Create Strategy
```bash
POST /api/v1/strategies
Content-Type: application/json

{
  "name": "AI Strategy 1",
  "description": "Conservative allocation strategy",
  "allocations": [
    {
      "adapter_index": 0,
      "percentage": 600,
      "protocol": "Aave"
    },
    {
      "adapter_index": 1,
      "percentage": 400,
      "protocol": "UniswapV2"
    }
  ]
}
```

#### List Strategies
```bash
GET /api/v1/strategies?limit=10&offset=0
```

#### Get Strategy
```bash
GET /api/v1/strategies/{id}
```

#### Execute Strategy
```bash
POST /api/v1/strategies/execute
Content-Type: application/json

{
  "strategy_id": "uuid",
  "vault_id": "uuid"
}
```

### Vaults

#### List Vaults
```bash
GET /api/v1/vaults
```

#### Get Vault
```bash
GET /api/v1/vaults/{id}
```

#### Withdraw All Investments
```bash
POST /api/v1/vaults/{id}/withdraw-all
```

### Executions

#### List Executions
```bash
GET /api/v1/executions
```

#### Get Execution
```bash
GET /api/v1/executions/{id}
```

## Database Schema

### Strategies
- `id`: UUID primary key
- `name`: Strategy name
- `description`: Strategy description
- `status`: pending/executing/completed/failed
- `created_at`, `updated_at`, `executed_at`: Timestamps

### Allocations
- `id`: UUID primary key
- `strategy_id`: Foreign key to strategies
- `adapter_index`: Index in vault manager's adapter list
- `percentage`: Allocation percentage (0-1000 for precision)
- `protocol`: Protocol name (Aave, UniswapV2, UniswapV3)

### Vaults
- `id`: UUID primary key
- `address`: Vault contract address
- `token_address`: Underlying token address
- `token_symbol`, `token_name`: Token metadata
- `is_active`: Vault status
- `total_assets`: Total assets in vault

### Executions
- `id`: UUID primary key
- `strategy_id`, `vault_id`: Foreign keys
- `status`: Execution status
- `tx_hash`: Blockchain transaction hash
- `gas_used`, `gas_price`: Transaction details
- `error`: Error message if failed

### Transactions
- `id`: UUID primary key
- `execution_id`: Foreign key to executions
- `tx_hash`: Blockchain transaction hash
- `from`, `to`: Transaction addresses
- `value`: Transaction value
- `status`: Transaction status

## AI Integration Example

Here's how an AI agent would use this backend:

```python
import requests

# 1. Create a strategy
strategy_data = {
    "name": "AI Generated Strategy",
    "description": "Based on market analysis",
    "allocations": [
        {"adapter_index": 0, "percentage": 700, "protocol": "Aave"},
        {"adapter_index": 1, "percentage": 300, "protocol": "UniswapV2"}
    ]
}

response = requests.post("http://localhost:8080/api/v1/strategies", json=strategy_data)
strategy = response.json()["strategy"]

# 2. Execute the strategy
execution_data = {
    "strategy_id": strategy["id"],
    "vault_id": "your-vault-id"
}

response = requests.post("http://localhost:8080/api/v1/strategies/execute", json=execution_data)
execution = response.json()["execution"]

# 3. Monitor execution
execution_id = execution["id"]
response = requests.get(f"http://localhost:8080/api/v1/executions/{execution_id}")
execution_status = response.json()["execution"]
```

## Development

### Project Structure
```
internal/
├── config/          # Configuration management
├── database/        # Database models and connection
├── blockchain/      # Ethereum client and contract interactions
├── services/        # Business logic
├── handlers/        # HTTP request handlers
├── logger/          # Logging configuration
└── server/          # HTTP server setup
```

### Adding New Features

1. **New API Endpoint**: Add handler in `handlers/`
2. **New Service Logic**: Add service in `services/`
3. **New Database Model**: Add model in `database/models.go`
4. **New Contract Interaction**: Add method in `blockchain/contracts.go`

### Testing

Run tests:
```bash
go test ./...
```

### Building

Build for production:
```bash
go build -o ai-vault-backend main.go
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | Database host | localhost |
| `DB_PORT` | Database port | 5432 |
| `DB_USER` | Database user | ai_vault |
| `DB_PASSWORD` | Database password | - |
| `DB_NAME` | Database name | ai_vault |
| `ETH_RPC_URL` | Ethereum RPC URL | http://localhost:8545 |
| `PRIVATE_KEY` | Private key for transactions | - |
| `VAULT_MANAGER_ADDRESS` | Vault manager contract address | - |
| `WETH_ADDRESS` | WETH token address | - |
| `SERVER_PORT` | Server port | 8080 |
| `LOG_LEVEL` | Log level (debug/info/warn/error) | info |

## Security Considerations

- Store private keys securely (consider using environment variables or key management services)
- Implement proper authentication and authorization for production use
- Validate all input data
- Use HTTPS in production
- Monitor for suspicious activity

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details
