import { BigInt, Address } from "@graphprotocol/graph-ts";
import {
  VaultCreatedAndRegistered,
  AdapterAddedToList,
  AIAgentVaultManager,
} from "../../generated/AIAgentVaultManager/AIAgentVaultManager";
import { VaultImplementation } from "../../generated/AIAgentVaultManager/VaultImplementation";
import { IERC20Metadata } from "../../generated/AIAgentVaultManager/IERC20Metadata";
import {
  VaultManager,
  Vault,
  Asset,
  AaveAdapter,
  UniswapV2Adapter,
  UniswapV3Adapter,
} from "../../generated/schema";

// 辅助函数：获取或创建Asset实体
function getOrCreateAsset(
  assetAddress: Address,
  blockTimestamp: BigInt
): string {
  let assetId = assetAddress.toHexString();
  let asset = Asset.load(assetId);

  if (!asset) {
    asset = new Asset(assetId);
    asset.address = assetAddress;

    // 从ERC20合约获取代币信息
    let tokenContract = IERC20Metadata.bind(assetAddress);
    asset.symbol = tokenContract.symbol();
    asset.name = tokenContract.name();
    asset.decimals = tokenContract.decimals();
    asset.createdAt = blockTimestamp;
    asset.save();
  }

  return assetId;
}

export function handleVaultCreatedAndRegistered(
  event: VaultCreatedAndRegistered
): void {
  // 获取或创建管理器实体
  let managerId = event.address.toHexString();
  let manager = VaultManager.load(managerId);
  if (!manager) {
    manager = new VaultManager(managerId);
    manager.address = event.address;
    manager.owner = event.transaction.from;
    manager.createdAt = event.block.timestamp;
    manager.updatedAt = event.block.timestamp;
    manager.save();
  }

  // 加载金库实体（应该已经由 VaultFactory 创建）
  let vaultId = event.params.vault.toHexString();
  let vault = Vault.load(vaultId);

  if (!vault) {
    // 如果金库不存在，创建一个新的（兜底情况）
    vault = new Vault(vaultId);
    vault.address = event.params.vault;
    vault.name = event.params.vaultName;
    vault.symbol = "";
    vault.fee = BigInt.fromI32(0);
    vault.isActive = true;
    vault.totalAssets = BigInt.fromI32(0);
    vault.totalSupply = BigInt.fromI32(0);
    vault.factory = null;

    // 从Vault合约获取asset地址并创建Asset实体
    let vaultContract = VaultImplementation.bind(event.params.vault);
    let assetAddress = Address.fromBytes(vaultContract.asset());
    vault.asset = getOrCreateAsset(assetAddress, event.block.timestamp);

    vault.createdAt = event.block.timestamp;
  }

  // 更新 manager 引用（无论 vault 是否存在都需要更新）
  vault.manager = managerId;
  vault.updatedAt = event.block.timestamp;
  vault.save();

  // 更新管理器时间戳
  manager.updatedAt = event.block.timestamp;
  manager.save();
}

export function handleAdapterAddedToList(event: AdapterAddedToList): void {
  // 获取管理器
  let managerId = event.address.toHexString();
  let manager = VaultManager.load(managerId);
  if (!manager) {
    manager = new VaultManager(managerId);
    manager.address = event.address;
    manager.owner = event.transaction.from;
    manager.createdAt = event.block.timestamp;
    manager.updatedAt = event.block.timestamp;
    manager.save();
  }

  // 根据适配器类型创建对应的适配器实体
  let adapterId = event.params.adapter.toHexString();
  let adapterName = event.params.adapterName;

  if (adapterName == "Aave") {
    let adapter = new AaveAdapter(adapterId);
    adapter.address = event.params.adapter;
    adapter.save();
  } else if (adapterName == "UniswapV2") {
    let adapter = new UniswapV2Adapter(adapterId);
    adapter.address = event.params.adapter;
    adapter.save();
  } else if (adapterName == "UniswapV3") {
    let adapter = new UniswapV3Adapter(adapterId);
    adapter.address = event.params.adapter;
    adapter.save();
  }

  // 更新管理器时间戳
  manager.updatedAt = event.block.timestamp;
  manager.save();
}
