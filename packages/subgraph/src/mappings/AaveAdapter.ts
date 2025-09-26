import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  TokenVaultSet,
  Invested,
  Divested,
} from "../../generated/AaveAdapter/AaveAdapter";
import { AaveAdapter, AaveTokenPosition } from "../../generated/schema";

export function handleTokenVaultSet(event: TokenVaultSet): void {
  // 创建或更新适配器实体
  let adapterId = event.address.toHexString();
  let adapter = AaveAdapter.load(adapterId);
  if (!adapter) {
    adapter = new AaveAdapter(adapterId);
    adapter.address = event.address;
    adapter.save();
  }

  // 创建或更新代币头寸
  let positionId = adapterId
    .concat("-")
    .concat(event.params.token.toHexString());
  let position = AaveTokenPosition.load(positionId);
  if (!position) {
    position = new AaveTokenPosition(positionId);
    position.adapter = adapterId;
    position.token = event.params.token;
    position.vault = event.params.vault;
    position.investedAmount = BigInt.fromI32(0);
    position.aTokenBalance = BigInt.fromI32(0);
    position.save();
  } else {
    position.vault = event.params.vault;
    position.save();
  }

  // 更新适配器时间戳
  adapter.save();
}

export function handleInvested(event: Invested): void {
  // 创建或更新适配器实体
  let adapterId = event.address.toHexString();
  let adapter = AaveAdapter.load(adapterId);
  if (!adapter) {
    adapter = new AaveAdapter(adapterId);
    adapter.address = event.address;
    adapter.save();
  }

  // 创建或更新代币头寸
  let positionId = adapterId
    .concat("-")
    .concat(event.params.asset.toHexString());
  let position = AaveTokenPosition.load(positionId);
  if (!position) {
    position = new AaveTokenPosition(positionId);
    position.adapter = adapterId;
    position.token = event.params.asset;
    position.vault = Bytes.empty();
    position.investedAmount = BigInt.fromI32(0);
    position.aTokenBalance = BigInt.fromI32(0);
    position.save();
  }

  // 更新投资状态
  position.investedAmount = position.investedAmount.plus(event.params.amount);
  position.aTokenBalance = event.params.aTokenBalance;
  position.save();

  // 更新适配器时间戳
  adapter.save();
}

export function handleDivested(event: Divested): void {
  // 创建或更新适配器实体
  let adapterId = event.address.toHexString();
  let adapter = AaveAdapter.load(adapterId);
  if (!adapter) {
    adapter = new AaveAdapter(adapterId);
    adapter.address = event.address;
    adapter.save();
  }

  // 创建或更新代币头寸
  let positionId = adapterId
    .concat("-")
    .concat(event.params.asset.toHexString());
  let position = AaveTokenPosition.load(positionId);
  if (!position) {
    position = new AaveTokenPosition(positionId);
    position.adapter = adapterId;
    position.token = event.params.asset;
    position.vault = Bytes.empty();
    position.investedAmount = BigInt.fromI32(0);
    position.aTokenBalance = BigInt.fromI32(0);
    position.save();
  }

  // 更新投资状态
  position.investedAmount = position.investedAmount.minus(
    event.params.actualAmount
  );
  position.aTokenBalance = position.aTokenBalance.minus(
    event.params.actualAmount
  );
  position.save();

  // 更新适配器时间戳
  adapter.save();
}
