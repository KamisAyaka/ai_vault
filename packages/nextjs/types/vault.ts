// GraphQL types for Vault entities
export type VaultManager = {
  id: string;
  address: string;
  owner: string;
};

export type VaultUser = {
  id: string;
  address: string;
};

export type Deposit = {
  id: string;
  user: VaultUser;
  assets: string;
  userShares: string;
  blockTimestamp: string;
  transactionHash: string;
};

export type Redeem = {
  id: string;
  user: VaultUser;
  assets: string;
  shares: string;
  blockNumber: string;
  blockTimestamp: string;
  transactionHash: string;
};

export type Allocation = {
  id: string;
  adapterAddress: string;
  adapterType: string;
  allocation: string;
};

export type Asset = {
  id: string;
  address: string;
  symbol: string;
  name: string;
  decimals: number;
};

export type Vault = {
  id: string;
  address: string;
  name: string;
  isActive: boolean;
  totalAssets: string;
  totalSupply: string;
  manager: VaultManager;
  asset: Asset | null;
  createdAt: string;
  updatedAt: string;
  deposits: Deposit[];
  redeems?: Redeem[];
  allocations: Allocation[];
};

export type VaultStatsBreakdown = {
  symbol: string;
  amount: bigint;
  decimals: number;
  usdValue: number;
};

export type VaultStats = {
  totalVaults: number;
  activeVaults: number;
  totalValueLockedUsd: number;
  totalValueLockedBreakdown: VaultStatsBreakdown[];
  averageApy: number;
  totalUsers: number;
};

export type VaultSummary = {
  id: string;
  address: string;
  name: string;
  isActive: boolean;
  totalAssets: string;
  totalSupply: string;
  asset: Asset | null;
};

export type UserStatsEntity = {
  id: string;
  totalDeposited: string;
  totalShares: string;
  activeVaults: string[];
  lastUpdated: string;
};

export type UserVaultBalance = {
  id: string;
  user: VaultUser;
  vault: VaultSummary;
  totalDeposited: string;
  totalRedeemed: string;
  currentShares: string;
  currentValue: string;
  lastUpdated: string;
};
