import { BigInt, Bytes, Address, dataSource } from "@graphprotocol/graph-ts";
import {
  VaultCreated,
  VaultFactory,
} from "../../generated/VaultFactory/VaultFactory";
import { IERC20Metadata } from "../../generated/VaultFactory/IERC20Metadata";
import { AIAgentVaultManager } from "../../generated/VaultFactory/AIAgentVaultManager";
import {
  VaultFactory as VaultFactoryEntity,
  Vault,
  Asset,
  VaultManager,
} from "../../generated/schema";

export function handleVaultCreated(event: VaultCreated): void {
  // 创建或获取VaultFactory实体
  let factoryId = event.address.toHexString();
  let factory = VaultFactoryEntity.load(factoryId);
  if (!factory) {
    factory = new VaultFactoryEntity(factoryId);
    factory.address = event.address;
    // 从合约中获取实现地址和管理者地址
    let factoryContract = VaultFactory.bind(event.address);
    factory.vaultImplementation = factoryContract.vaultImplementation();
    factory.vaultManager = factoryContract.vaultManager();
    factory.createdAt = event.block.timestamp;
    factory.updatedAt = event.block.timestamp;
    factory.save();
  }

  // 创建或获取Asset实体
  let assetId = event.params.asset.toHexString();
  let asset = Asset.load(assetId);
  if (!asset) {
    asset = new Asset(assetId);
    asset.address = event.params.asset;

    // 从ERC20合约获取代币信息
    let tokenContract = IERC20Metadata.bind(event.params.asset);
    asset.symbol = tokenContract.symbol();
    asset.name = tokenContract.name();
    asset.decimals = tokenContract.decimals();
    asset.createdAt = event.block.timestamp;
    asset.save();
  }

  // 创建或获取VaultManager实体
  let managerId = factory.vaultManager.toHexString();
  let manager = VaultManager.load(managerId);
  if (!manager) {
    manager = new VaultManager(managerId);
    manager.address = factory.vaultManager;
    // 从AIAgentVaultManager合约获取owner
    let managerContract = AIAgentVaultManager.bind(
      Address.fromBytes(factory.vaultManager)
    );
    manager.owner = managerContract.owner();
    manager.createdAt = event.block.timestamp;
    manager.updatedAt = event.block.timestamp;
    manager.save();
  }

  // 创建Vault实体
  let vaultId = event.params.vault.toHexString();
  let vault = new Vault(vaultId);
  vault.address = event.params.vault;
  vault.name = event.params.vaultName;
  vault.symbol = event.params.vaultSymbol;
  vault.fee = event.params.fee;
  vault.isActive = true;
  vault.totalAssets = BigInt.fromI32(0);
  vault.totalSupply = BigInt.fromI32(0);
  vault.factory = factoryId;
  vault.manager = managerId;
  vault.asset = assetId;
  vault.createdAt = event.block.timestamp;
  vault.updatedAt = event.block.timestamp;
  vault.save();

  // 为新的金库实例创建模板数据源
  dataSource.create("VaultInstance", [event.params.vault.toHexString()]);
}
