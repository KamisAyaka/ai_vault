import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  Deposit,
  Redeem,
  NoLongerActive,
  HoldingAllocationUpdated,
} from "../../generated/VaultShares/VaultShares";
import { IProtocolAdapter } from "../../generated/VaultShares/IProtocolAdapter";
import {
  Vault,
  User,
  Deposit as DepositEntity,
  Redeem as RedeemEntity,
  Allocation,
  UserVaultBalance,
} from "../../generated/schema";

// 辅助函数：更新用户金库余额
function updateUserVaultBalance(
  userId: string,
  vaultId: string,
  depositAmount: BigInt,
  sharesAmount: BigInt,
  isDeposit: boolean,
  blockTimestamp: BigInt
): void {
  let balanceId = userId.concat("-").concat(vaultId);
  let userVaultBalance = UserVaultBalance.load(balanceId);

  if (!userVaultBalance) {
    userVaultBalance = new UserVaultBalance(balanceId);
    userVaultBalance.user = userId;
    userVaultBalance.vault = vaultId;
    userVaultBalance.totalDeposited = BigInt.fromI32(0);
    userVaultBalance.totalRedeemed = BigInt.fromI32(0);
    userVaultBalance.currentShares = BigInt.fromI32(0);
    userVaultBalance.currentValue = BigInt.fromI32(0);
  }

  if (isDeposit) {
    userVaultBalance.totalDeposited =
      userVaultBalance.totalDeposited.plus(depositAmount);
    userVaultBalance.currentShares =
      userVaultBalance.currentShares.plus(sharesAmount);
  } else {
    userVaultBalance.totalRedeemed =
      userVaultBalance.totalRedeemed.plus(depositAmount);
    userVaultBalance.currentShares =
      userVaultBalance.currentShares.minus(sharesAmount);
  }

  // 计算当前价值（基于份额和当前金库价格）
  let vault = Vault.load(vaultId);
  if (vault && vault.totalSupply.gt(BigInt.fromI32(0))) {
    userVaultBalance.currentValue = userVaultBalance.currentShares
      .times(vault.totalAssets)
      .div(vault.totalSupply);
  } else {
    userVaultBalance.currentValue = BigInt.fromI32(0);
  }

  userVaultBalance.lastUpdated = blockTimestamp;
  userVaultBalance.save();
}

// 辅助函数：更新用户统计信息
function updateUserStatistics(userId: string, blockTimestamp: BigInt): void {
  let user = User.load(userId);
  if (!user) return;

  // 重新计算用户统计信息
  let totalDeposited = BigInt.fromI32(0);
  let totalShares = BigInt.fromI32(0);
  let activeVaults: Bytes[] = [];

  // 这里需要查询所有相关的 UserVaultBalance 实体
  // 由于 Graph Protocol 的限制，我们使用一个简化的方法
  // 在实际部署时，可能需要通过事件日志来维护这些统计

  user.totalDeposited = totalDeposited;
  user.totalShares = totalShares;
  user.activeVaults = activeVaults;
  user.save();
}

export function handleDeposit(event: Deposit): void {
  // 获取或创建用户实体
  let userId = event.params.receiver.toHexString();
  let user = User.load(userId);
  if (!user) {
    user = new User(userId);
    user.address = event.params.receiver;
    user.totalDeposited = BigInt.fromI32(0);
    user.totalShares = BigInt.fromI32(0);
    user.activeVaults = [];
    user.save();
  }

  // 获取金库实体
  let vaultId = event.address.toHexString();
  let vault = Vault.load(vaultId);
  if (!vault) {
    vault = new Vault(vaultId);
    vault.address = event.address;
    vault.name = "";
    vault.isActive = true;
    vault.totalAssets = BigInt.fromI32(0);
    vault.totalSupply = BigInt.fromI32(0);
    vault.manager = "";
    vault.createdAt = event.block.timestamp;
    vault.updatedAt = event.block.timestamp;
    vault.save();
  }

  // 更新金库总资产和总供应量
  vault.totalAssets = vault.totalAssets.plus(event.params.assets);
  vault.totalSupply = vault.totalSupply.plus(event.params.userShares);
  vault.updatedAt = event.block.timestamp;
  vault.save();

  // 创建存款实体
  let depositId = event.transaction.hash
    .concatI32(event.logIndex.toI32())
    .toHexString();
  let deposit = new DepositEntity(depositId);
  deposit.vault = vaultId;
  deposit.user = userId;
  deposit.assets = event.params.assets;
  deposit.userShares = event.params.userShares;
  deposit.blockNumber = event.block.number;
  deposit.blockTimestamp = event.block.timestamp;
  deposit.transactionHash = event.transaction.hash;
  deposit.save();

  // 更新用户金库余额
  updateUserVaultBalance(
    userId,
    vaultId,
    event.params.assets,
    event.params.userShares,
    true, // isDeposit
    event.block.timestamp
  );

  // 更新用户统计信息
  user.totalDeposited = user.totalDeposited.plus(event.params.assets);
  user.totalShares = user.totalShares.plus(event.params.userShares);

  // 更新活跃金库列表
  let activeVaults = user.activeVaults;
  let vaultIdBytes = event.address; // 使用 Bytes 类型
  if (activeVaults.indexOf(vaultIdBytes) == -1) {
    activeVaults.push(vaultIdBytes);
    user.activeVaults = activeVaults;
  }

  user.save();
}

export function handleRedeem(event: Redeem): void {
  // 获取或创建用户实体
  let userId = event.params.receiver.toHexString();
  let user = User.load(userId);
  if (!user) {
    user = new User(userId);
    user.address = event.params.receiver;
    user.totalDeposited = BigInt.fromI32(0);
    user.totalShares = BigInt.fromI32(0);
    user.activeVaults = [];
    user.save();
  }

  // 获取金库实体
  let vaultId = event.address.toHexString();
  let vault = Vault.load(vaultId);
  if (vault) {
    // 更新金库总资产和总供应量
    vault.totalAssets = vault.totalAssets.minus(event.params.assets);
    vault.totalSupply = vault.totalSupply.minus(event.params.shares);
    vault.updatedAt = event.block.timestamp;
    vault.save();
  }

  // 创建赎回实体
  let redeemId = event.transaction.hash
    .concatI32(event.logIndex.toI32())
    .toHexString();
  let redeem = new RedeemEntity(redeemId);
  redeem.vault = vaultId;
  redeem.user = userId;
  redeem.shares = event.params.shares;
  redeem.assets = event.params.assets;
  redeem.blockNumber = event.block.number;
  redeem.blockTimestamp = event.block.timestamp;
  redeem.transactionHash = event.transaction.hash;
  redeem.save();

  // 更新用户金库余额
  updateUserVaultBalance(
    userId,
    vaultId,
    event.params.assets,
    event.params.shares,
    false, // isDeposit = false (isRedeem)
    event.block.timestamp
  );

  // 更新用户统计信息
  user.totalShares = user.totalShares.minus(event.params.shares);

  // 检查是否还有剩余份额，如果没有则从活跃金库列表中移除
  let userVaultBalanceId = userId.concat("-").concat(vaultId);
  let userVaultBalance = UserVaultBalance.load(userVaultBalanceId);
  if (
    userVaultBalance &&
    userVaultBalance.currentShares.equals(BigInt.fromI32(0))
  ) {
    let activeVaults = user.activeVaults;
    let vaultIdBytes = event.address; // 使用 Bytes 类型
    let index = activeVaults.indexOf(vaultIdBytes);
    if (index != -1) {
      activeVaults.splice(index, 1);
      user.activeVaults = activeVaults;
    }
  }

  user.save();
}

export function handleNoLongerActive(event: NoLongerActive): void {
  // 获取金库实体
  let vaultId = event.address.toHexString();
  let vault = Vault.load(vaultId);
  if (vault) {
    vault.isActive = false;
    vault.updatedAt = event.block.timestamp;
    vault.save();
  }
}

export function handleHoldingAllocationUpdated(
  event: HoldingAllocationUpdated
): void {
  // 获取金库实体
  let vaultId = event.address.toHexString();
  let vault = Vault.load(vaultId);
  if (!vault) {
    vault = new Vault(vaultId);
    vault.address = event.address;
    vault.name = "";
    vault.isActive = true;
    vault.totalAssets = BigInt.fromI32(0);
    vault.totalSupply = BigInt.fromI32(0);
    vault.manager = "";
    vault.createdAt = event.block.timestamp;
    vault.updatedAt = event.block.timestamp;
    vault.save();
  }

  // 更新金库时间戳
  vault.updatedAt = event.block.timestamp;
  vault.save();

  // 处理分配更新
  let allocations = event.params.allocations;
  for (let i = 0; i < allocations.length; i++) {
    let currentAllocation = allocations[i];
    if (currentAllocation) {
      let allocationId = vaultId.concat("-").concat(i.toString());
      let allocation = Allocation.load(allocationId);
      if (!allocation) {
        allocation = new Allocation(allocationId);
        allocation.vault = vaultId;
        allocation.adapterAddress = currentAllocation.adapter;
        // 通过合约地址调用 getName() 方法获取适配器类型
        let adapterContract = IProtocolAdapter.bind(currentAllocation.adapter);
        let adapterType = adapterContract.getName();
        allocation.adapterType = adapterType;
      } else {
        allocation.adapterAddress = currentAllocation.adapter;
        // 通过合约地址调用 getName() 方法获取适配器类型
        let adapterContract = IProtocolAdapter.bind(currentAllocation.adapter);
        let adapterType = adapterContract.getName();
        allocation.adapterType = adapterType;
      }
      allocation.allocation = currentAllocation.allocation;
      allocation.save();
    }
  }
}
