# AI 保险库后端

这是一个 Go 后端服务，使 AI 代理能够与以太坊上的 AI Vault 智能合约进行交互。该后端提供用于执行链上操作的 REST API。

## 功能特性

- **交易执行**:执行策略分配、创建金库、存取款等链上操作
- **区块链集成**:直接与 AI Vault Manager 和 Vault 合约交互
- **REST API**:为 AI 代理提供简洁的 HTTP API

> **注意**: 所有数据查询(金库信息、策略分配、用户余额等)应直接使用 `packages/subgraph` 提供的 GraphQL API，无需在后端维护数据库。

## 架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI 代理       │───▶│   Go 后端       │───▶│   智能合约      │
│                 │    │                 │    │                 │
│ • 策略生成      │    │ • REST API      │    │ • Vault Manager │
│ • 决策          │    │ • 交易执行      │    │ • Vaults        │
│ • 执行          │    │ • 签名发送      │    │ • Adapters      │
│                 │    │                 │    │                 │
│                 │◀───┤                 │◀───┤                 │
│                 │    │                 │    │                 │
│ • 数据查询      │    │   Subgraph      │◀───│   事件日志      │
│                 │    │   GraphQL API   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 快速开始

### 前置要求

- Go 1.21+
- 以太坊节点(本地或远程)
- 已部署的 AI Vault 合约

### 安装

1. 克隆仓库并导航到后端目录:
```bash
cd packages/go-backend
```

2. 安装依赖:
```bash
go mod tidy
```

3. 复制环境配置:
```bash
cp env.example .env
```

4. 更新 `.env` 配置:
```bash
# 区块链
ETH_RPC_URL=http://localhost:8545
PRIVATE_KEY=your_private_key_here
VAULT_MANAGER_ADDRESS=0x...

# 服务器
SERVER_PORT=8080
LOG_LEVEL=info
```

5. 运行应用:
```bash
go run main.go
```

服务器将在 `http://localhost:8080` 启动

## API 文档

### 健康检查
```
GET /health
```

### 执行策略分配

**重要**: 后端通过 `AIAgentVaultManager` 合约执行所有操作。必须使用合约 owner 的私钥。

#### 更新金库策略分配
```bash
POST /api/v1/allocations
Content-Type: application/json

{
  "token_address": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  # WETH 地址
  "allocations": [
    {
      "adapter_index": 0,      # 全局适配器列表中的索引 (不是地址!)
      "percentage": 600       # 60% (0-1000 表示 0-100%)
    },
    {
      "adapter_index": 1,      # 第二个适配器的索引
      "percentage": 400       # 40%
    }
  ]
}
```

**响应**:
```json
{
  "message": "Allocations updated successfully",
  "result": {
    "tx_hash": "0x...",
    "status": "pending"
  }
}
```

**说明**:
- `token_address`: 金库资产的代币地址 (如 WETH)
- `adapter_index`: 适配器在 VaultManager 全局列表中的索引
  - 0 = Aave 适配器
  - 1 = UniswapV2 适配器
  - 2 = UniswapV3 适配器
- `percentage`: 分配比例,使用基点 (1000 = 100%)

### 提取投资

#### 提取金库所有投资
```bash
POST /api/v1/withdraw
Content-Type: application/json

{
  "token_address": "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"  # WETH 地址
}
```

**响应**:
```json
{
  "message": "All investments withdrawn successfully",
  "result": {
    "tx_hash": "0x...",
    "status": "pending"
  }
}
```

### 适配器配置

后端提供了针对每个 DeFi 协议适配器的配置功能。所有配置通过 `VaultManager.execute(adapterIndex, value, data)` 执行。

#### Aave 适配器配置

设置代币与金库的映射关系:

```go
// 通过 Go 代码调用
txHash, err := contractService.Aave.SetTokenVault(
    ctx,
    0,  // adapterIndex: Aave 适配器索引
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  // tokenAddress: WETH
    "0x123..."  // vaultAddress: 金库地址
)
```

**合约调用**: `VaultManager.execute(0, 0, abi.encode("setTokenVault", token, vault))`

#### UniswapV2 适配器配置

设置代币配置(交易对、滑点容差):

```go
// 设置完整配置
txHash, err := contractService.UniswapV2.SetTokenConfig(
    ctx,
    1,  // adapterIndex: UniswapV2 适配器索引
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  // tokenAddress: WETH
    50,  // slippageTolerance: 0.5% (50 基点)
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",  // counterPartyToken: USDC
    "0x123..."  // vaultAddress: 金库地址
)

// 仅更新滑点容差
txHash, err := contractService.UniswapV2.UpdateTokenConfig(
    ctx,
    1,  // adapterIndex
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  // tokenAddress
    100  // slippageTolerance: 1%
)
```

**合约调用**: `VaultManager.execute(1, 0, abi.encode("setTokenConfig", ...))`

#### UniswapV3 适配器配置

设置代币配置(包括费率档、价格区间):

```go
// 设置 UniswapV3 配置
txHash, err := contractService.UniswapV3.SetTokenConfig(
    ctx,
    2,  // adapterIndex: UniswapV3 适配器索引
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  // tokenAddress: WETH
    50,  // slippageTolerance: 0.5%
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",  // counterPartyToken: USDC
    3000,  // feeTier: 0.3% (3000 = 0.3%)
    -887220,  // tickLower: 价格下限
    887220,   // tickUpper: 价格上限
    "0x123..."  // vaultAddress: 金库地址
)

// 仅更新滑点容差
txHash, err := contractService.UniswapV3.UpdateTokenConfig(
    ctx,
    2,  // adapterIndex
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",  // tokenAddress
    100  // slippageTolerance: 1%
)
```

**合约调用**: `VaultManager.execute(2, 0, abi.encode("setTokenConfig", ...))`

**参数说明**:
- `adapterIndex`: 适配器在全局列表中的索引 (0=Aave, 1=UniswapV2, 2=UniswapV3)
- `slippageTolerance`: 滑点容差(基点, 100 = 1%)
- `feeTier`: UniswapV3 费率档 (500=0.05%, 3000=0.3%, 10000=1%)
- `tickLower/tickUpper`: UniswapV3 价格区间的 tick 值

### 数据查询

所有数据查询请使用 Subgraph GraphQL API:

#### 查询金库信息
```graphql
query {
  vaults {
    id
    address
    name
    symbol
    totalAssets
    totalSupply
    isActive
    asset {
      symbol
      name
    }
    allocations {
      adapterAddress
      adapterType
      allocation
    }
  }
}
```

#### 查询用户余额
```graphql
query {
  userVaultBalances(where: { user: "0x..." }) {
    vault {
      name
      symbol
    }
    currentShares
    currentValue
    totalDeposited
    totalRedeemed
  }
}
```

#### 查询适配器头寸
```graphql
query {
  aaveTokenPositions {
    token
    vault
    investedAmount
    aTokenBalance
  }

  uniswapV2TokenPositions {
    token
    counterPartyToken
    liquidity
    tokenAmount
    counterPartyTokenAmount
  }

  uniswapV3TokenPositions {
    token
    counterPartyToken
    feeTier
    liquidity
    tokenAmount
    counterPartyTokenAmount
  }
}
```

## AI 集成示例

以下是 AI 代理如何使用此后端和子图的示例:

```python
import requests
from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport

# 设置后端 API 和 Subgraph GraphQL 端点
BACKEND_API = "http://localhost:8080"
SUBGRAPH_URL = "http://localhost:8000/subgraphs/name/ai-vault"
WETH_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

# 初始化 GraphQL 客户端
transport = RequestsHTTPTransport(url=SUBGRAPH_URL)
graphql_client = Client(transport=transport, fetch_schema_from_transport=True)

# 1. 从子图查询当前适配器列表和金库信息
query = gql("""
  query {
    vaults(where: { asset: "${WETH_ADDRESS}" }) {
      address
      name
      totalAssets
      allocations {
        adapterAddress
        adapterType
        allocation
      }
    }
  }
""")

result = graphql_client.execute(query)
vault_info = result['vaults'][0]

# 2. AI 生成新的策略分配
# 注意: 使用适配器索引而非地址
allocations = [
    {"adapter_index": 0, "percentage": 7000},  # 70% -> Aave (索引 0)
    {"adapter_index": 1, "percentage": 3000}   # 30% -> UniswapV2 (索引 1)
]

# 3. 通过后端执行策略 (调用 VaultManager 合约)
response = requests.post(
    f"{BACKEND_API}/api/v1/allocations",
    json={
        "token_address": WETH_ADDRESS,
        "allocations": allocations
    }
)
tx_hash = response.json()["result"]["tx_hash"]
print(f"Transaction sent: {tx_hash}")

# 4. 等待交易确认后,从子图查询更新后的分配
import time
time.sleep(15)  # 等待区块确认

query = gql(f"""
  query {{
    vaults(where: {{ asset: "{WETH_ADDRESS}" }}) {{
      allocations {{
        adapterAddress
        adapterType
        allocation
      }}
    }}
  }}
""")

updated_allocations = graphql_client.execute(query)
print("Updated allocations:", updated_allocations)
```

## 合约架构说明

### 权限模型
- **AIAgentVaultManager**: 管理员合约,`onlyOwner` 可调用
- 后端必须使用 VaultManager 的 owner 私钥
- VaultManager 通过索引管理全局适配器列表

### 调用流程
1. AI Agent -> Go Backend
2. Go Backend -> `VaultManager.updateHoldingAllocation(token, adapterIndices[], allocationData[])`
3. VaultManager -> `Vault.updateHoldingAllocation(Allocation[])`
4. Vault -> 各个 Adapter (Aave, UniswapV2, UniswapV3)

### 关键合约函数

**VaultManager.updateHoldingAllocation**:
```solidity
function updateHoldingAllocation(
    IERC20 token,              // 金库资产代币 (如 WETH)
    uint256[] adapterIndices,  // 适配器索引数组 [0, 1]
    uint256[] allocationData   // 分配比例数组 [7000, 3000]
) external onlyOwner
```

**VaultManager.withdrawAllInvestments**:
```solidity
function withdrawAllInvestments(
    IERC20 token  // 金库资产代币
) external onlyOwner
```

**VaultManager.execute** (适配器配置):
```solidity
function execute(
    uint256 adapterIndex,  // 适配器索引
    uint256 value,         // 发送的 ETH 值(通常为 0)
    bytes calldata data    // ABI 编码的函数调用数据
) external onlyOwner returns (bytes memory)
```

### 适配器架构

后端使用适配器模式来配置不同的 DeFi 协议:

```
ContractService
├── Aave Adapter (index 0)
│   └── SetTokenVault(token, vault)
├── UniswapV2 Adapter (index 1)
│   ├── SetTokenConfig(token, slippage, counterParty, vault)
│   └── UpdateTokenConfig(token, slippage)
└── UniswapV3 Adapter (index 2)
    ├── SetTokenConfig(token, slippage, counterParty, fee, tickLower, tickUpper, vault)
    └── UpdateTokenConfig(token, slippage)

所有适配器调用都通过: VaultManager.execute(adapterIndex, 0, abiEncodedData)
```

**适配器文件位置**:
- [internal/blockchain/adapters/aave.go](internal/blockchain/adapters/aave.go)
- [internal/blockchain/adapters/uniswapv2.go](internal/blockchain/adapters/uniswapv2.go)
- [internal/blockchain/adapters/uniswapv3.go](internal/blockchain/adapters/uniswapv3.go)

## 开发

### 项目结构
```
internal/
├── config/          # 配置管理
├── blockchain/      # 以太坊客户端和合约交互
│   ├── adapters/    # DeFi 协议适配器
│   │   ├── aave.go        # Aave 适配器配置
│   │   ├── uniswapv2.go   # UniswapV2 适配器配置
│   │   └── uniswapv3.go   # UniswapV3 适配器配置
│   ├── abi/         # 合约 ABI 文件
│   ├── client.go    # 以太坊客户端封装
│   ├── contracts.go # 合约服务层
│   └── vault_manager.go  # VaultManager 合约绑定(自动生成)
├── handlers/        # HTTP 请求处理器
├── services/        # 业务逻辑层
├── logger/          # 日志配置
└── server/          # HTTP 服务器设置
```

### 添加新功能

1. **新 API 端点**: 在 `handlers/` 中添加处理器
2. **新合约交互**: 在 `blockchain/contracts.go` 中添加方法
3. **新适配器配置**: 在 `blockchain/adapters/` 中创建新适配器文件

#### 添加新适配器示例

```go
// internal/blockchain/adapters/compound.go
package adapters

import (
    "context"
    "strings"
    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/common"
)

type CompoundAdapter struct {
    executeFunc func(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error)
}

func NewCompoundAdapter(executeFunc func(ctx context.Context, adapterIndex uint64, value uint64, data []byte) (string, error)) *CompoundAdapter {
    return &CompoundAdapter{executeFunc: executeFunc}
}

func (c *CompoundAdapter) SetMarket(ctx context.Context, adapterIndex uint64, tokenAddress, cTokenAddress string) (string, error) {
    abiJSON := `[{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"address","name":"cToken","type":"address"}],"name":"setMarket","outputs":[],"stateMutability":"nonpayable","type":"function"}]`
    parsedABI, err := abi.JSON(strings.NewReader(abiJSON))
    if err != nil {
        return "", err
    }

    token := common.HexToAddress(tokenAddress)
    cToken := common.HexToAddress(cTokenAddress)

    data, err := parsedABI.Pack("setMarket", token, cToken)
    if err != nil {
        return "", err
    }

    return c.executeFunc(ctx, adapterIndex, 0, data)
}
```

然后在 `contracts.go` 中注册:

```go
cs.Compound = adapters.NewCompoundAdapter(cs.executeAdapterCall)
```

### 测试

运行测试:
```bash
go test ./...
```

### 构建

生产环境构建:
```bash
go build -o ai-vault-backend main.go
```

## 配置

### 环境变量

| 变量 | 描述 | 默认值 |
|----------|-------------|---------|
| `ETH_RPC_URL` | 以太坊 RPC URL | http://localhost:8545 |
| `PRIVATE_KEY` | 交易私钥 | - |
| `VAULT_MANAGER_ADDRESS` | Vault manager 合约地址 | - |
| `SERVER_PORT` | 服务器端口 | 8080 |
| `LOG_LEVEL` | 日志级别(debug/info/warn/error) | info |

## 安全注意事项

- 安全存储私钥(考虑使用环境变量或密钥管理服务)
- 为生产环境实现适当的身份验证和授权
- 验证所有输入数据
- 生产环境使用 HTTPS
- 监控可疑活动

## 贡献

1. Fork 仓库
2. 创建功能分支
3. 进行更改
4. 添加测试
5. 提交 pull request

## 许可证

MIT 许可证 - 详见 LICENSE 文件
