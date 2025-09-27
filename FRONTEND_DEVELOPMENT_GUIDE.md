# AI Vault 前端开发指南

## 项目概述

这是一个基于 ERC-4626 标准的 AI 代理金库管理系统，允许用户将资金存入金库，由 AI 代理自动分配到不同的 DeFi 协议中获取收益。系统支持 Aave、Uniswap V2、Uniswap V3 等主流 DeFi 协议。

## 核心合约架构

### 1. 主要合约组件

#### AIAgentVaultManager (AI 代理金库管理器)

- **功能**: 管理多个金库，控制投资策略分配
- **权限**: 仅 AI 代理可调用
- **核心功能**:
  - 添加/管理金库
  - 更新投资分配策略
  - 管理协议适配器

#### VaultShares (ERC-4626 金库)

- **功能**: 标准 ERC-4626 金库，支持任意 ERC20 资产
- **用户功能**: 存款、取款、查看收益
- **管理功能**: 投资策略配置

#### VaultSharesETH (ETH 金库)

- **功能**: 专门处理 ETH/WETH 转换的金库
- **特殊功能**: 直接接收 ETH，自动转换为 WETH 进行投资

#### 协议适配器

- **AaveAdapter**: Aave V3 借贷协议
- **UniswapV2Adapter**: Uniswap V2 流动性提供
- **UniswapV3Adapter**: Uniswap V3 流动性提供

## 前端需要实现的功能

### 1. 用户界面功能

#### 1.1 金库管理界面

```typescript
// 需要实现的功能组件
interface VaultManagement {
  // 金库列表展示
  vaultList: {
    vaultAddress: string;
    asset: string; // USDC, WETH等
    totalAssets: bigint;
    totalSupply: bigint;
    isActive: boolean;
    apy: number; // 年化收益率
  }[];

  // 金库状态管理
  setVaultInactive: (vaultAddress: string) => Promise<void>;
}
```

#### 1.2 用户投资界面

```typescript
interface UserInvestment {
  // 存款功能
  deposit: {
    // 普通ERC20资产存款 (VaultShares)
    deposit: (assets: bigint, receiver: string) => Promise<bigint>;

    // ETH存款（仅限VaultSharesETH）
    depositETH: (receiver: string) => Promise<bigint>;

    // 按份额铸造 (VaultShares)
    mint: (shares: bigint, receiver: string) => Promise<bigint>;

    // 按份额铸造ETH（仅限VaultSharesETH）
    mintETH: (shares: bigint, receiver: string) => Promise<bigint>;
  };

  // 取款功能
  withdraw: {
    // 按资产数量取款 (VaultShares)
    withdraw: (
      assets: bigint,
      receiver: string,
      owner: string
    ) => Promise<bigint>;

    // 按份额赎回 (VaultShares)
    redeem: (
      shares: bigint,
      receiver: string,
      owner: string
    ) => Promise<bigint>;

    // ETH取款（仅限VaultSharesETH）
    withdrawETH: (
      assets: bigint,
      receiver: string,
      owner: string
    ) => Promise<bigint>;

    // ETH赎回（仅限VaultSharesETH）
    redeemETH: (
      shares: bigint,
      receiver: string,
      owner: string
    ) => Promise<bigint>;
  };
}
```

#### 1.3 投资策略管理界面（AI 代理专用）

```typescript
interface InvestmentStrategy {
  // 查看当前投资分配
  getAllocations: (vaultAddress: string) => Promise<Allocation[]>;

  // 更新投资策略
  updateAllocation: (
    vaultAddress: string,
    allocations: Allocation[]
  ) => Promise<void>;

  // 部分调整投资
  partialUpdateAllocation: (params: PartialUpdateParams) => Promise<void>;

  // 撤回所有投资
  withdrawAllInvestments: (vaultAddress: string) => Promise<void>;
}

interface Allocation {
  adapter: string; // 适配器地址
  allocation: bigint; // 分配比例（以1000为基准）
}

interface PartialUpdateParams {
  vaultAddress: string;
  divestAdapterIndices: number[];
  divestAmounts: bigint[];
  investAdapterIndices: number[];
  investAmounts: bigint[];
  investAllocations: bigint[];
}
```

### 2. 数据展示功能

#### 2.1 金库信息展示

```typescript
interface VaultInfo {
  // 基础信息
  basicInfo: {
    name: string;
    symbol: string;
    asset: string;
    totalAssets: bigint;
    totalSupply: bigint;
    isActive: boolean;
  };

  // 用户持仓信息
  userPosition: {
    shares: bigint;
    assets: bigint;
    shareValue: bigint; // 每股价值
  };

  // 投资分配信息
  allocations: {
    adapterName: string; // "Aave", "UniswapV2", "UniswapV3"
    adapterAddress: string;
    allocation: bigint; // 分配比例
    totalValue: bigint; // 在该适配器中的总价值
  }[];

  // 收益信息
  performance: {
    apy: number;
    totalFees: bigint;
    userFees: bigint;
  };
}
```

#### 2.2 协议适配器信息

```typescript
interface AdapterInfo {
  // 适配器列表
  adapters: {
    address: string;
    name: string; // "Aave", "UniswapV2", "UniswapV3"
    isApproved: boolean;
  }[];

  // 适配器配置（管理员功能）
  adapterConfig: {
    // Aave配置
    aave: {
      tokenVaults: Record<string, string>; // token => vault mapping
    };

    // UniswapV2配置
    uniswapV2: {
      tokenConfigs: {
        token: string;
        slippageTolerance: bigint;
        counterPartyToken: string;
        vaultAddress: string;
      }[];
    };

    // UniswapV3配置
    uniswapV3: {
      tokenConfigs: {
        token: string;
        counterPartyToken: string;
        slippageTolerance: bigint;
        feeTier: number;
        tickLower: number;
        tickUpper: number;
        vaultAddress: string;
      }[];
    };
  };
}
```

## 前端实现指南

### 1. 使用 GraphQL 查询合约数据

#### 1.1 现有的 GraphQL 查询

你的项目已经配置了 GraphQL 客户端，可以直接使用现有的查询文件：

```typescript
// 导入现有的 GraphQL 查询和客户端
import {
  GetVaultsDocument,
  GetVaultByIdDocument,
  GetUserVaultBalancesDocument,
  GetDepositsDocument,
  execute,
} from "~~/.graphclient";

// 查询所有金库
const fetchVaults = async (first: number = 10, skip: number = 0) => {
  try {
    const { data } = await execute(GetVaultsDocument, {
      first,
      skip,
      orderBy: "totalAssets",
      orderDirection: "desc",
    });
    return data?.vaults;
  } catch (error) {
    console.error("Error fetching vaults:", error);
    return null;
  }
};

// 查询特定金库详情
const fetchVaultById = async (vaultId: string) => {
  try {
    const { data } = await execute(GetVaultByIdDocument, { id: vaultId });
    return data?.vault;
  } catch (error) {
    console.error("Error fetching vault:", error);
    return null;
  }
};

// 查询用户金库余额
const fetchUserVaultBalances = async (
  userAddress: string,
  first: number = 10,
  skip: number = 0
) => {
  try {
    const { data } = await execute(GetUserVaultBalancesDocument, {
      userAddress,
      first,
      skip,
    });
    return data?.userVaultBalances;
  } catch (error) {
    console.error("Error fetching user balances:", error);
    return null;
  }
};

// 查询存款历史
const fetchDeposits = async (first: number = 10, skip: number = 0) => {
  try {
    const { data } = await execute(GetDepositsDocument, {
      first,
      skip,
      orderBy: "blockTimestamp",
      orderDirection: "desc",
    });
    return data?.deposits;
  } catch (error) {
    console.error("Error fetching deposits:", error);
    return null;
  }
};
```

#### 1.2 写入合约数据

**重要说明**：合约函数签名与标准 ERC-4626 略有不同：

- **存款函数**：`deposit(assets, receiver)` - 返回用户获得的份额数量
- **取款函数**：`withdraw(assets, receiver, owner)` - 需要指定接收者和所有者
- **ETH 函数**：`depositETH(receiver)` - 通过`msg.value`发送 ETH，不需要 amount 参数
- **ETH 取款**：`withdrawETH(assets, receiver, owner)` - 自动将 WETH 转换为 ETH

```typescript
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";

// 存款操作
const { writeContractAsync: depositAsync } = useScaffoldWriteContract({
  contractName: "VaultShares",
});

const handleDeposit = async (assets: bigint, receiver: string) => {
  const result = await depositAsync({
    functionName: "deposit",
    args: [assets, receiver],
    // 不需要 value，因为是 ERC20 存款
  });
  return result;
};

// ETH存款（仅限VaultSharesETH）
const { writeContractAsync: depositETHAsync } = useScaffoldWriteContract({
  contractName: "VaultSharesETH",
});

const handleDepositETH = async (receiver: string, ethAmount: bigint) => {
  const result = await depositETHAsync({
    functionName: "depositETH",
    args: [receiver],
    value: ethAmount, // ETH数量作为 value 发送
  });
  return result;
};

// 按份额铸造
const { writeContractAsync: mintAsync } = useScaffoldWriteContract({
  contractName: "VaultShares",
});

const handleMint = async (shares: bigint, receiver: string) => {
  const result = await mintAsync({
    functionName: "mint",
    args: [shares, receiver],
  });
  return result;
};

// ETH按份额铸造（仅限VaultSharesETH）
const { writeContractAsync: mintETHAsync } = useScaffoldWriteContract({
  contractName: "VaultSharesETH",
});

const handleMintETH = async (
  shares: bigint,
  receiver: string,
  ethAmount: bigint
) => {
  const result = await mintETHAsync({
    functionName: "mintETH",
    args: [shares, receiver],
    value: ethAmount, // ETH数量作为 value 发送
  });
  return result;
};

// 取款操作
const { writeContractAsync: withdrawAsync } = useScaffoldWriteContract({
  contractName: "VaultShares",
});

const handleWithdraw = async (
  assets: bigint,
  receiver: string,
  owner: string
) => {
  const result = await withdrawAsync({
    functionName: "withdraw",
    args: [assets, receiver, owner],
  });
  return result;
};

// 赎回操作
const { writeContractAsync: redeemAsync } = useScaffoldWriteContract({
  contractName: "VaultShares",
});

const handleRedeem = async (
  shares: bigint,
  receiver: string,
  owner: string
) => {
  const result = await redeemAsync({
    functionName: "redeem",
    args: [shares, receiver, owner],
  });
  return result;
};

// ETH取款（仅限VaultSharesETH）
const { writeContractAsync: withdrawETHAsync } = useScaffoldWriteContract({
  contractName: "VaultSharesETH",
});

const handleWithdrawETH = async (
  assets: bigint,
  receiver: string,
  owner: string
) => {
  const result = await withdrawETHAsync({
    functionName: "withdrawETH",
    args: [assets, receiver, owner],
  });
  return result;
};

// ETH赎回（仅限VaultSharesETH）
const { writeContractAsync: redeemETHAsync } = useScaffoldWriteContract({
  contractName: "VaultSharesETH",
});

const handleRedeemETH = async (
  shares: bigint,
  receiver: string,
  owner: string
) => {
  const result = await redeemETHAsync({
    functionName: "redeemETH",
    args: [shares, receiver, owner],
  });
  return result;
};
```

### 2. 组件实现建议

#### 2.1 金库卡片组件

```typescript
import { useVault } from "~~/hooks/useVault";
import { useUserVaultBalances } from "~~/hooks/useUserVaultBalances";
import { Address } from "~~/components/scaffold-eth";

interface VaultCardProps {
  vaultId: string;
  userAddress?: string;
}

const VaultCard: React.FC<VaultCardProps> = ({ vaultId, userAddress }) => {
  const { vault, loading: vaultLoading, error: vaultError } = useVault(vaultId);
  const { balances, loading: balancesLoading } = useUserVaultBalances(
    userAddress || ""
  );

  if (vaultLoading) {
    return <div className="vault-card loading">Loading vault info...</div>;
  }

  if (vaultError || !vault) {
    return <div className="vault-card error">Vault not found</div>;
  }

  // 计算每股价格
  const sharePrice =
    vault.totalSupply > 0 ? vault.totalAssets / vault.totalSupply : 0n;

  // 查找用户在该金库中的余额
  const userBalance = balances.find((balance) => balance.vault.id === vaultId);

  return (
    <div className="vault-card bg-base-100 p-6 rounded-xl shadow-lg">
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-xl font-bold">{vault.name}</h3>
        <span
          className={`badge ${
            vault.isActive ? "badge-success" : "badge-error"
          }`}
        >
          {vault.isActive ? "Active" : "Inactive"}
        </span>
      </div>

      <div className="space-y-2 mb-4">
        <p>
          <strong>Address:</strong> <Address address={vault.address} />
        </p>
        <p>
          <strong>Manager:</strong> <Address address={vault.manager?.address} />
        </p>
        <p>
          <strong>Total Assets:</strong> {vault.totalAssets?.toString()}
        </p>
        <p>
          <strong>Total Supply:</strong> {vault.totalSupply?.toString()}
        </p>
        <p>
          <strong>Share Price:</strong> {sharePrice.toString()}
        </p>
      </div>

      {userAddress && userBalance && (
        <div className="user-position bg-base-200 p-4 rounded-lg">
          <h4 className="font-semibold mb-2">Your Position</h4>
          <p>
            <strong>Shares:</strong> {userBalance.currentShares?.toString()}
          </p>
          <p>
            <strong>Current Value:</strong>{" "}
            {userBalance.currentValue?.toString()}
          </p>
          <p>
            <strong>Total Deposited:</strong>{" "}
            {userBalance.totalDeposited?.toString()}
          </p>
          <p>
            <strong>Total Redeemed:</strong>{" "}
            {userBalance.totalRedeemed?.toString()}
          </p>
        </div>
      )}

      {vault.allocations && vault.allocations.length > 0 && (
        <div className="allocations mt-4">
          <h4 className="font-semibold mb-2">Investment Allocations</h4>
          <div className="space-y-1">
            {vault.allocations.map((allocation: any, index: number) => (
              <div key={index} className="flex justify-between text-sm">
                <span>{allocation.adapterType}</span>
                <span>
                  {((Number(allocation.allocation) / 1000) * 100).toFixed(1)}%
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
```

#### 2.2 投资操作组件

```typescript
import { useState } from "react";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useAccount } from "wagmi";
import { parseUnits, parseEther } from "viem";

const InvestmentActions: React.FC<{
  vaultAddress: string;
  asset: string;
  isETHVault?: boolean;
}> = ({ vaultAddress, asset, isETHVault = false }) => {
  const [amount, setAmount] = useState("");
  const [isDepositing, setIsDepositing] = useState(false);
  const [isWithdrawing, setIsWithdrawing] = useState(false);
  const { address: userAddress } = useAccount();

  const { writeContractAsync: depositAsync } = useScaffoldWriteContract({
    contractName: isETHVault ? "VaultSharesETH" : "VaultShares",
  });

  const { writeContractAsync: withdrawAsync } = useScaffoldWriteContract({
    contractName: isETHVault ? "VaultSharesETH" : "VaultShares",
  });

  const handleDeposit = async () => {
    if (!userAddress || !amount) return;

    setIsDepositing(true);
    try {
      if (isETHVault) {
        // ETH存款
        await depositAsync({
          functionName: "depositETH",
          args: [userAddress],
          value: parseEther(amount),
        });
      } else {
        // ERC20存款
        await depositAsync({
          functionName: "deposit",
          args: [parseUnits(amount, 6), userAddress], // 假设6位小数
        });
      }
      setAmount(""); // 清空输入
    } catch (error) {
      console.error("Deposit failed:", error);
    } finally {
      setIsDepositing(false);
    }
  };

  const handleWithdraw = async () => {
    if (!userAddress || !amount) return;

    setIsWithdrawing(true);
    try {
      if (isETHVault) {
        // ETH取款
        await withdrawAsync({
          functionName: "withdrawETH",
          args: [parseEther(amount), userAddress, userAddress],
        });
      } else {
        // ERC20取款
        await withdrawAsync({
          functionName: "withdraw",
          args: [parseUnits(amount, 6), userAddress, userAddress], // 假设6位小数
        });
      }
      setAmount(""); // 清空输入
    } catch (error) {
      console.error("Withdraw failed:", error);
    } finally {
      setIsWithdrawing(false);
    }
  };

  return (
    <div className="investment-actions bg-base-100 p-6 rounded-xl shadow-lg">
      <h3 className="text-lg font-semibold mb-4">Investment Actions</h3>

      <div className="space-y-4">
        <div>
          <label className="label">
            <span className="label-text">Amount ({asset})</span>
          </label>
          <input
            type="number"
            step="0.000001"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder={`Enter ${asset} amount`}
            className="input input-bordered w-full"
          />
        </div>

        <div className="flex gap-2">
          <button
            onClick={handleDeposit}
            disabled={isDepositing || !amount}
            className="btn btn-primary flex-1"
          >
            {isDepositing ? "Depositing..." : "Deposit"}
          </button>

          <button
            onClick={handleWithdraw}
            disabled={isWithdrawing || !amount}
            className="btn btn-secondary flex-1"
          >
            {isWithdrawing ? "Withdrawing..." : "Withdraw"}
          </button>
        </div>
      </div>
    </div>
  );
};
```

#### 2.3 投资分配展示组件

```typescript
import { useVault } from "~~/hooks/useVault";

const AllocationDisplay: React.FC<{ vaultId: string }> = ({ vaultId }) => {
  const { vault, loading, error } = useVault(vaultId);

  if (loading) {
    return (
      <div className="allocation-display loading">Loading allocations...</div>
    );
  }

  if (error) {
    return (
      <div className="allocation-display error">Error loading allocations</div>
    );
  }

  if (!vault || !vault.allocations || vault.allocations.length === 0) {
    return (
      <div className="allocation-display">
        <h3>Current Investment Allocation</h3>
        <p>No allocations configured</p>
      </div>
    );
  }

  return (
    <div className="allocation-display bg-base-100 p-6 rounded-xl shadow-lg">
      <h3 className="text-xl font-bold mb-4">Current Investment Allocation</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {vault.allocations.map((allocation: any, index: number) => (
          <div
            key={index}
            className="allocation-item bg-base-200 p-4 rounded-lg"
          >
            <div className="flex justify-between items-center mb-2">
              <h4 className="font-semibold">{allocation.adapterType}</h4>
              <span className="badge badge-primary">
                {((Number(allocation.allocation) / 1000) * 100).toFixed(1)}%
              </span>
            </div>
            <div className="text-sm text-base-content/70">
              <p>
                <strong>Adapter:</strong>{" "}
                <Address address={allocation.adapterAddress} />
              </p>
              <p>
                <strong>Allocation:</strong> {allocation.allocation}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
```

### 3. 完整的页面示例

#### 3.1 金库列表页面

```typescript
import { useVaults } from "~~/hooks/useVaults";
import VaultCard from "~~/components/VaultCard";

const VaultsPage: React.FC = () => {
  const { vaults, loading, error } = useVaults(20, 0);

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <span className="loading loading-spinner loading-lg"></span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="alert alert-error">
        <span>Error loading vaults: {error.message}</span>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">AI Vault Protocol</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {vaults.map((vault: any) => (
          <VaultCard
            key={vault.id}
            vaultId={vault.id}
            userAddress={userAddress} // 从钱包连接获取
          />
        ))}
      </div>
    </div>
  );
};
```

#### 3.2 金库详情页面

```typescript
import { useVault } from "~~/hooks/useVault";
import AllocationDisplay from "~~/components/AllocationDisplay";
import InvestmentActions from "~~/components/InvestmentActions";

const VaultDetailPage: React.FC<{ vaultId: string }> = ({ vaultId }) => {
  const { vault, loading, error } = useVault(vaultId);

  if (loading) {
    return <div className="loading">Loading vault details...</div>;
  }

  if (error || !vault) {
    return <div className="error">Vault not found</div>;
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* 金库基本信息 */}
        <div className="space-y-6">
          <VaultCard vaultId={vaultId} userAddress={userAddress} />
          <InvestmentActions
            vaultAddress={vault.address}
            asset={vault.asset}
            isETHVault={vault.asset === "WETH"}
          />
        </div>

        {/* 投资分配信息 */}
        <div>
          <AllocationDisplay vaultId={vaultId} />
        </div>
      </div>
    </div>
  );
};
```

### 4. 管理员界面（AI 代理专用）

#### 4.1 投资策略管理

```typescript
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

const StrategyManagement: React.FC = () => {
  const { writeContractAsync: updateAllocationAsync } =
    useScaffoldWriteContract({
      contractName: "AIAgentVaultManager",
    });

  const handleUpdateAllocation = async (
    vaultAddress: string,
    allocations: Allocation[]
  ) => {
    await updateAllocationAsync({
      functionName: "updateHoldingAllocation",
      args: [vaultAddress, allocations],
    });
  };

  return (
    <div className="strategy-management">
      <h2>Investment Strategy Management</h2>
      {/* 投资分配配置界面 */}
    </div>
  );
};
```

## 部署和配置

### 1. GraphQL 配置

你的项目已经配置了 GraphQL 客户端，配置文件位于 `.graphclientrc.yml`：

```yaml
# .graphclientrc.yml
sources:
  - name: AIVault
    handler:
      graphql:
        endpoint: http://localhost:8000/subgraphs/name/scaffold-eth/ai-vault
documents:
  - ./graphql/*.gql
```

#### 1.1 启动 Subgraph 服务

```bash
# 启动 graph-node
yarn subgraph:run-node

# 创建本地 subgraph
yarn subgraph:create-local

# 部署 subgraph
yarn subgraph:local-ship

# 构建 GraphQL 客户端
yarn graphclient:build
```

#### 1.2 使用现有的 GraphQL 查询

你的项目已经包含了以下查询文件，如需更多查询请自行编写 graphql 语句：

- `GetVaults.gql` - 查询所有金库
- `GetVaultById.gql` - 查询特定金库详情
- `GetUserVaultBalances.gql` - 查询用户金库余额
- `GetDeposits.gql` - 查询存款历史

### 2. 合约部署顺序

1. 部署协议适配器（AaveAdapter, UniswapV2Adapter, UniswapV3Adapter）
2. 部署 AIAgentVaultManager
3. 部署 VaultShares 和 VaultSharesETH 金库
4. 配置适配器参数
5. 将金库添加到管理器
6. 启动 Subgraph 服务并部署

### 3. 前端配置

```typescript
// scaffold.config.ts 配置
export const scaffoldConfig = {
  targetNetworks: [hardhat, sepolia, mainnet],
  contracts: {
    AIAgentVaultManager: {
      address: "0x...",
      abi: AIAgentVaultManagerABI,
    },
    VaultShares: {
      address: "0x...",
      abi: VaultSharesABI,
    },
    VaultSharesETH: {
      address: "0x...",
      abi: VaultSharesETHABI,
    },
    // 适配器合约
    AaveAdapter: {
      address: "0x...",
      abi: AaveAdapterABI,
    },
    UniswapV2Adapter: {
      address: "0x...",
      abi: UniswapV2AdapterABI,
    },
    UniswapV3Adapter: {
      address: "0x...",
      abi: UniswapV3AdapterABI,
    },
  },
};
```

## 安全注意事项

1. **权限控制**: 确保只有 AI 代理地址可以调用管理函数
2. **滑点保护**: 在 Uniswap 操作中设置合理的滑点容忍度
3. **重入攻击防护**: 合约已实现 ReentrancyGuard
4. **输入验证**: 前端需要验证用户输入的有效性
5. **错误处理**: 实现完善的错误处理和用户提示
