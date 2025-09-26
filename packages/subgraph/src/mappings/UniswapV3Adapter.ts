import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  TokenConfigSet,
  TokenConfigUpdated,
  TokenConfigReinvested,
  UniswapV3Invested,
  UniswapV3Divested,
} from "../../generated/UniswapV3Adapter/UniswapV3Adapter";
import {
  UniswapV3Adapter,
  UniswapV3TokenPosition,
} from "../../generated/schema";

export function handleTokenConfigSet(event: TokenConfigSet): void {
  // 创建或更新适配器实体
  let adapterId = event.address.toHexString();
  let adapter = UniswapV3Adapter.load(adapterId);
  if (!adapter) {
    adapter = new UniswapV3Adapter(adapterId);
    adapter.address = event.address;
    // 需要从其他地方获取管理器地址
    adapter.save();
  }

  // 创建或更新代币头寸
  let positionId = adapterId
    .concat("-")
    .concat(event.params.token.toHexString());
  let position = UniswapV3TokenPosition.load(positionId);
  if (!position) {
    position = new UniswapV3TokenPosition(positionId);
    position.adapter = adapterId;
    position.token = event.params.token;
    position.counterPartyToken = event.params.counterPartyToken;
    position.vault = event.params.vault;
    position.slippageTolerance = event.params.slippageTolerance;
    position.feeTier = BigInt.fromI32(event.params.feeTier);
    position.tickLower = BigInt.fromI32(event.params.tickLower);
    position.tickUpper = BigInt.fromI32(event.params.tickUpper);
    position.tokenId = BigInt.fromI32(0); // 需要从合约中获取
    position.liquidity = BigInt.fromI32(0);
    position.tokenAmount = BigInt.fromI32(0);
    position.counterPartyTokenAmount = BigInt.fromI32(0);
    position.save();
  } else {
    position.counterPartyToken = event.params.counterPartyToken;
    position.vault = event.params.vault;
    position.slippageTolerance = event.params.slippageTolerance;
    position.feeTier = BigInt.fromI32(event.params.feeTier);
    position.tickLower = BigInt.fromI32(event.params.tickLower);
    position.tickUpper = BigInt.fromI32(event.params.tickUpper);
    position.save();
  }

  // 更新适配器时间戳
  adapter.save();
}

export function handleTokenConfigUpdated(event: TokenConfigUpdated): void {
  // 创建或更新适配器实体
  let adapterId = event.address.toHexString();
  let adapter = UniswapV3Adapter.load(adapterId);
  if (!adapter) {
    adapter = new UniswapV3Adapter(adapterId);
    adapter.address = event.address;
    adapter.save();
  }

  // 更新代币头寸的滑点容忍度
  let positionId = adapterId
    .concat("-")
    .concat(event.params.token.toHexString());
  let position = UniswapV3TokenPosition.load(positionId);
  if (position) {
    position.slippageTolerance = event.params.slippageTolerance;
    position.save();
  }

  // 更新适配器时间戳
  adapter.save();
}

export function handleTokenConfigReinvested(
  event: TokenConfigReinvested
): void {
  // 创建或更新适配器实体
  let adapterId = event.address.toHexString();
  let adapter = UniswapV3Adapter.load(adapterId);
  if (!adapter) {
    adapter = new UniswapV3Adapter(adapterId);
    adapter.address = event.address;
    adapter.save();
  }

  // 更新代币头寸的配置
  let positionId = adapterId
    .concat("-")
    .concat(event.params.token.toHexString());
  let position = UniswapV3TokenPosition.load(positionId);
  if (position) {
    position.counterPartyToken = event.params.newCounterPartyToken;
    position.feeTier = BigInt.fromI32(event.params.feeTier);
    position.tickLower = BigInt.fromI32(event.params.tickLower);
    position.tickUpper = BigInt.fromI32(event.params.tickUpper);
    position.save();
  }

  // 更新适配器时间戳
  adapter.save();
}

export function handleUniswapV3Invested(event: UniswapV3Invested): void {
  // 创建或更新适配器实体
  let adapterId = event.address.toHexString();
  let adapter = UniswapV3Adapter.load(adapterId);
  if (!adapter) {
    adapter = new UniswapV3Adapter(adapterId);
    adapter.address = event.address;
    adapter.save();
  }

  // 创建或更新代币头寸
  let positionId = adapterId
    .concat("-")
    .concat(event.params.token.toHexString());
  let position = UniswapV3TokenPosition.load(positionId);
  if (!position) {
    position = new UniswapV3TokenPosition(positionId);
    position.adapter = adapterId;
    position.token = event.params.token;
    position.counterPartyToken = Bytes.empty();
    position.vault = Bytes.empty();
    position.slippageTolerance = BigInt.fromI32(0);
    position.feeTier = BigInt.fromI32(0);
    position.tickLower = BigInt.fromI32(0);
    position.tickUpper = BigInt.fromI32(0);
    position.tokenId = BigInt.fromI32(0);
    position.liquidity = BigInt.fromI32(0);
    position.tokenAmount = BigInt.fromI32(0);
    position.counterPartyTokenAmount = BigInt.fromI32(0);
    position.save();
  }

  // 更新投资状态
  position.liquidity = position.liquidity.plus(event.params.liquidity);
  position.tokenAmount = position.tokenAmount.plus(event.params.tokenAmount);
  position.counterPartyTokenAmount = position.counterPartyTokenAmount.plus(
    event.params.counterPartyTokenAmount
  );
  position.save();

  // 更新适配器时间戳
  adapter.save();
}

export function handleUniswapV3Divested(event: UniswapV3Divested): void {
  // 创建或更新适配器实体
  let adapterId = event.address.toHexString();
  let adapter = UniswapV3Adapter.load(adapterId);
  if (!adapter) {
    adapter = new UniswapV3Adapter(adapterId);
    adapter.address = event.address;
    adapter.save();
  }

  // 创建或更新代币头寸
  let positionId = adapterId
    .concat("-")
    .concat(event.params.token.toHexString());
  let position = UniswapV3TokenPosition.load(positionId);
  if (!position) {
    position = new UniswapV3TokenPosition(positionId);
    position.adapter = adapterId;
    position.token = event.params.token;
    position.counterPartyToken = Bytes.empty();
    position.vault = Bytes.empty();
    position.slippageTolerance = BigInt.fromI32(0);
    position.feeTier = BigInt.fromI32(0);
    position.tickLower = BigInt.fromI32(0);
    position.tickUpper = BigInt.fromI32(0);
    position.tokenId = BigInt.fromI32(0);
    position.liquidity = BigInt.fromI32(0);
    position.tokenAmount = BigInt.fromI32(0);
    position.counterPartyTokenAmount = BigInt.fromI32(0);
    position.save();
  }

  // 更新投资状态
  position.liquidity = position.liquidity.minus(event.params.liquidity);
  position.tokenAmount = position.tokenAmount.minus(event.params.tokenAmount);
  position.counterPartyTokenAmount = position.counterPartyTokenAmount.minus(
    event.params.counterPartyTokenAmount
  );
  position.save();

  // 更新适配器时间戳
  adapter.save();
}
