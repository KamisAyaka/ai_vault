import { BigInt } from "@graphprotocol/graph-ts";
import {
  VaultCreatedAndRegistered,
  AdapterAddedToList,
} from "../../generated/AIAgentVaultManager/AIAgentVaultManager";
import {
  VaultManager,
  Vault,
  AaveAdapter,
  UniswapV2Adapter,
  UniswapV3Adapter,
} from "../../generated/schema";

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

  // 创建金库实体
  let vaultId = event.params.vault.toHexString();
  let vault = new Vault(vaultId);
  vault.address = event.params.vault;
  vault.name = event.params.vaultName;
  vault.isActive = true;
  vault.totalAssets = BigInt.fromI32(0);
  vault.totalSupply = BigInt.fromI32(0);
  vault.manager = managerId;
  vault.createdAt = event.block.timestamp;
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
