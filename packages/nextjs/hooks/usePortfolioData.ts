"use client";

import { useMemo } from "react";
import { useTokenUsdPrices } from "./useTokenUsdPrices";
import { useUserPortfolio } from "./useUserPortfolio";
import { useVaults } from "./useVaults";
import { formatUnits } from "viem";
import { useAccount } from "wagmi";
import { useGlobalState } from "~~/services/store/store";
import type { Vault } from "~~/types/vault";

const STABLE_ASSETS = new Set(["USDC", "USDT", "DAI", "USDP", "TUSD"]);
const DAYS_IN_YEAR = 365;

type PortfolioPosition = {
  vault: Vault;
  assetSymbol: string;
  assetDecimals: number;
  shares: bigint;
  sharesFormatted: string;
  value: number;
  valueUsd: number;
  totalDeposited: number;
  totalDepositedUsd: number;
  totalRedeemed: number;
  totalRedeemedUsd: number;
  profitLoss: number;
  profitLossUsd: number;
  profitLossPercent: number;
  daysHeld: number;
  managementFeeUsd: number;
  performanceFeeUsd: number;
};

type PortfolioStats = {
  totalPortfolioValue: number;
  totalProfitLoss: number;
  totalProfitLossPercent: number;
  totalFees: number;
  totalPositions: number;
  totalDeposits: number;
  totalWithdrawals: number;
};

type RevenuePoint = {
  date: string;
  timestamp: number;
  value: number;
  formatted: string;
};

type FeeBreakdownRow = {
  vaultName: string;
  vaultAddress: string;
  managementFee: number;
  performanceFee: number;
  totalFee: number;
  assetSymbol: string;
  daysHeld: number;
};

type PortfolioTransaction = {
  id: string;
  type: "deposit" | "withdraw";
  vault: Vault;
  vaultAddress: string;
  amount: string;
  amountUsd: string;
  symbol: string;
  timestamp: number;
  transactionHash: string;
  shares: string;
};

type UserStatsSummary = {
  totalDeposited: bigint;
  totalShares: bigint;
  activeVaultAddresses: string[];
  lastUpdated: number;
};

const toBigInt = (value?: string) => {
  try {
    return BigInt(value || "0");
  } catch {
    return 0n;
  }
};

const toNumber = (value: bigint, decimals: number) => {
  try {
    return Number(formatUnits(value, decimals));
  } catch {
    return 0;
  }
};

const getAssetPrice = (symbol: string, nativePrice: number, tokenPrices: Record<string, number>) => {
  const upper = symbol.toUpperCase();
  if (tokenPrices[upper]) {
    return tokenPrices[upper];
  }
  if (STABLE_ASSETS.has(upper)) return 1;
  if (upper === "ETH" || upper === "WETH") return tokenPrices.WETH ?? nativePrice ?? 0;
  return 1;
};

const annualisedFee = (value: number, rate: number, daysHeld: number) => {
  if (!Number.isFinite(value) || !Number.isFinite(rate)) return 0;
  return value * rate * (daysHeld / DAYS_IN_YEAR);
};

const formatUsd = (value: number) => {
  if (!Number.isFinite(value)) return "$0";
  return `$${value.toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
};

const formatAmount = (value: number, symbol: string) => {
  if (!Number.isFinite(value)) return `0 ${symbol}`;
  return `${value.toLocaleString(undefined, { maximumFractionDigits: 4 })} ${symbol}`;
};

export const usePortfolioData = () => {
  const { address: connectedAddress } = useAccount();
  const { vaults, loading: vaultLoading, error: vaultError } = useVaults(200);
  const {
    userStats: userStatsEntity,
    balances: userBalances,
    loading: userPortfolioLoading,
    error: userPortfolioError,
  } = useUserPortfolio();
  const nativePrice = useGlobalState(state => state.nativeCurrency.price) || 0;
  const { tokenPrices } = useTokenUsdPrices();

  const lowerAddress = connectedAddress?.toLowerCase();

  const vaultMap = useMemo(() => {
    return new Map(vaults.map(vault => [vault.id.toLowerCase(), vault]));
  }, [vaults]);

  const positions = useMemo<PortfolioPosition[]>(() => {
    if (userBalances.length > 0) {
      return userBalances
        .map(balance => {
          const vault = vaultMap.get(balance.vault.id.toLowerCase());
          if (!vault) {
            return null;
          }

          const decimals = vault.asset?.decimals ?? 18;
          const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
          const price = getAssetPrice(symbol, nativePrice, tokenPrices);

          const shares = toBigInt(balance.currentShares);
          const assetValue = toNumber(toBigInt(balance.currentValue), decimals);
          const depositedValue = toNumber(toBigInt(balance.totalDeposited), decimals);
          const redeemedValue = toNumber(toBigInt(balance.totalRedeemed), decimals);

          if (shares === 0n && depositedValue === 0 && redeemedValue === 0) {
            return null;
          }

          const valueUsd = assetValue * price;
          const depositedUsd = depositedValue * price;
          const redeemedUsd = redeemedValue * price;
          const profitLoss = assetValue + redeemedValue - depositedValue;
          const profitLossUsd = valueUsd + redeemedUsd - depositedUsd;
          const profitLossPercent = depositedUsd > 0 ? (profitLossUsd / depositedUsd) * 100 : 0;

          const lastUpdatedMs = Number(balance.lastUpdated ?? "0") * 1000;
          const daysHeld = Math.max(
            1,
            (Date.now() - (lastUpdatedMs > 0 ? lastUpdatedMs : Date.now())) / (1000 * 60 * 60 * 24),
          );

          const managementFeeUsd = annualisedFee(valueUsd, 0.01, daysHeld);
          const performanceFeeUsd = Math.max(profitLossUsd, 0) * 0.2;

          return {
            vault,
            assetSymbol: symbol,
            assetDecimals: decimals,
            shares,
            sharesFormatted: formatUnits(shares, decimals),
            value: assetValue,
            valueUsd,
            totalDeposited: depositedValue,
            totalDepositedUsd: depositedUsd,
            totalRedeemed: redeemedValue,
            totalRedeemedUsd: redeemedUsd,
            profitLoss,
            profitLossUsd,
            profitLossPercent,
            daysHeld,
            managementFeeUsd,
            performanceFeeUsd,
          } satisfies PortfolioPosition | null;
        })
        .filter(Boolean) as PortfolioPosition[];
    }

    if (!vaults.length || !lowerAddress) return [];

    return vaults
      .map(vault => {
        const decimals = vault.asset?.decimals ?? 18;
        const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
        const price = getAssetPrice(symbol, nativePrice, tokenPrices);

        const userDeposits = (vault.deposits || []).filter(
          deposit => deposit.user?.address?.toLowerCase() === lowerAddress,
        );
        const userRedeems = (vault.redeems || []).filter(
          redeem => redeem.user?.address?.toLowerCase() === lowerAddress,
        );

        if (userDeposits.length === 0 && userRedeems.length === 0) {
          return null;
        }

        const depositShares = userDeposits.reduce<bigint>((acc, deposit) => acc + toBigInt(deposit.userShares), 0n);
        const redeemShares = userRedeems.reduce<bigint>((acc, redeem) => acc + toBigInt(redeem.shares), 0n);
        const userShares = depositShares - redeemShares;

        if (userShares === 0n && userDeposits.length === 0) {
          return null;
        }

        const totalAssets = toBigInt(vault.totalAssets);
        const totalSupply = toBigInt(vault.totalSupply);
        const userAssetValue = totalSupply > 0n ? (totalAssets * userShares) / totalSupply : 0n;

        const totalDepositedAssets = userDeposits.reduce<bigint>((acc, deposit) => acc + toBigInt(deposit.assets), 0n);
        const totalRedeemedAssets = userRedeems.reduce<bigint>((acc, redeem) => acc + toBigInt(redeem.assets), 0n);

        const assetValue = toNumber(userAssetValue, decimals);
        const depositedValue = toNumber(totalDepositedAssets, decimals);
        const redeemedValue = toNumber(totalRedeemedAssets, decimals);

        const valueUsd = assetValue * price;
        const depositedUsd = depositedValue * price;
        const redeemedUsd = redeemedValue * price;

        const profitLoss = assetValue + redeemedValue - depositedValue;
        const profitLossUsd = valueUsd + redeemedUsd - depositedUsd;
        const profitLossPercent = depositedUsd > 0 ? (profitLossUsd / depositedUsd) * 100 : 0;

        const firstDepositTimestamp =
          userDeposits.length > 0 ? Number(userDeposits[userDeposits.length - 1].blockTimestamp) * 1000 : Date.now();
        const daysHeld = Math.max(1, (Date.now() - firstDepositTimestamp) / (1000 * 60 * 60 * 24));

        const managementFeeUsd = annualisedFee(valueUsd, 0.01, daysHeld);
        const performanceFeeUsd = Math.max(profitLossUsd, 0) * 0.2;

        return {
          vault,
          assetSymbol: symbol,
          assetDecimals: decimals,
          shares: userShares,
          sharesFormatted: formatUnits(userShares, decimals),
          value: assetValue,
          valueUsd,
          totalDeposited: depositedValue,
          totalDepositedUsd: depositedUsd,
          totalRedeemed: redeemedValue,
          totalRedeemedUsd: redeemedUsd,
          profitLoss,
          profitLossUsd,
          profitLossPercent,
          daysHeld,
          managementFeeUsd,
          performanceFeeUsd,
        } satisfies PortfolioPosition | null;
      })
      .filter(Boolean) as PortfolioPosition[];
  }, [userBalances, vaultMap, vaults, lowerAddress, nativePrice]);

  const totalPortfolioValue = useMemo(
    () => positions.reduce((sum, position) => sum + position.valueUsd, 0),
    [positions],
  );
  const totalDepositsUsd = useMemo(
    () => positions.reduce((sum, position) => sum + position.totalDepositedUsd, 0),
    [positions],
  );
  const totalWithdrawalsUsd = useMemo(
    () => positions.reduce((sum, position) => sum + position.totalRedeemedUsd, 0),
    [positions],
  );
  const totalProfitLossUsd = useMemo(
    () => positions.reduce((sum, position) => sum + position.profitLossUsd, 0),
    [positions],
  );
  const totalFeesUsd = useMemo(
    () => positions.reduce((sum, position) => sum + position.managementFeeUsd + position.performanceFeeUsd, 0),
    [positions],
  );

  const userStatsSummary = useMemo<UserStatsSummary | null>(() => {
    if (!userStatsEntity) return null;
    return {
      totalDeposited: toBigInt(userStatsEntity.totalDeposited),
      totalShares: toBigInt(userStatsEntity.totalShares),
      activeVaultAddresses: userStatsEntity.activeVaults ?? [],
      lastUpdated: Number(userStatsEntity.lastUpdated ?? "0") * 1000,
    };
  }, [userStatsEntity]);

  const totalPositionsCount = userStatsSummary?.activeVaultAddresses.length ?? positions.length;

  const stats = useMemo<PortfolioStats>(() => {
    const profitLossPercent = totalDepositsUsd > 0 ? (totalProfitLossUsd / totalDepositsUsd) * 100 : 0;

    return {
      totalPortfolioValue,
      totalProfitLoss: totalProfitLossUsd,
      totalProfitLossPercent: profitLossPercent,
      totalFees: totalFeesUsd,
      totalPositions: totalPositionsCount,
      totalDeposits: totalDepositsUsd,
      totalWithdrawals: totalWithdrawalsUsd,
    };
  }, [
    totalPortfolioValue,
    totalProfitLossUsd,
    totalFeesUsd,
    totalDepositsUsd,
    totalWithdrawalsUsd,
    totalPositionsCount,
  ]);

  const revenueHistory = useMemo<RevenuePoint[]>(() => {
    if (!positions.length) return [];

    const events: Array<{ timestamp: number; delta: number }> = [];

    vaults?.forEach(vault => {
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const price = getAssetPrice(symbol, nativePrice, tokenPrices);
      const decimals = vault.asset?.decimals ?? 18;

      (vault.deposits || []).forEach(deposit => {
        if (deposit.user?.address?.toLowerCase() === lowerAddress) {
          const timestamp = Number(deposit.blockTimestamp) * 1000;
          const value = toNumber(toBigInt(deposit.assets), decimals) * price;
          events.push({ timestamp, delta: value });
        }
      });

      (vault.redeems || []).forEach(redeem => {
        if (redeem.user?.address?.toLowerCase() === lowerAddress) {
          const timestamp = Number(redeem.blockTimestamp) * 1000;
          const value = toNumber(toBigInt(redeem.assets), decimals) * price;
          events.push({ timestamp, delta: -value });
        }
      });
    });

    events.sort((a, b) => a.timestamp - b.timestamp);

    const finalValue = totalPortfolioValue;
    const totalFlows = events.reduce((sum, event) => sum + event.delta, 0);
    const initialValue = Math.max(0, finalValue - totalFlows);

    const days = 30;
    const points: RevenuePoint[] = [];
    let cumulative = initialValue;
    let eventIndex = 0;

    for (let dayOffset = days; dayOffset >= 0; dayOffset--) {
      const date = new Date();
      date.setHours(23, 59, 59, 999);
      date.setDate(date.getDate() - dayOffset);

      while (eventIndex < events.length && events[eventIndex].timestamp <= date.getTime()) {
        cumulative = Math.max(0, cumulative + events[eventIndex].delta);
        eventIndex++;
      }

      points.push({
        date: date.toLocaleDateString("zh-CN", { month: "short", day: "numeric" }),
        timestamp: Math.floor(date.getTime() / 1000),
        value: cumulative,
        formatted: formatUsd(cumulative),
      });
    }

    return points;
  }, [positions.length, vaults, nativePrice, lowerAddress, totalPortfolioValue]);

  const feeBreakdown = useMemo<FeeBreakdownRow[]>(() => {
    return positions.map(position => ({
      vaultName: position.vault.name,
      vaultAddress: position.vault.address,
      managementFee: position.managementFeeUsd,
      performanceFee: position.performanceFeeUsd,
      totalFee: position.managementFeeUsd + position.performanceFeeUsd,
      assetSymbol: position.assetSymbol,
      daysHeld: Math.round(position.daysHeld),
    }));
  }, [positions]);

  const transactionHistory = useMemo<PortfolioTransaction[]>(() => {
    if (!vaults || !lowerAddress) return [];

    const transactions: PortfolioTransaction[] = [];

    vaults.forEach(vault => {
      const decimals = vault.asset?.decimals ?? 18;
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const price = getAssetPrice(symbol, nativePrice, tokenPrices);

      (vault.deposits || []).forEach((deposit, index) => {
        if (deposit.user?.address?.toLowerCase() !== lowerAddress) return;

        const timestamp = Number(deposit.blockTimestamp) * 1000;
        const amount = toNumber(toBigInt(deposit.assets), decimals);
        const amountUsd = amount * price;
        const shares = toNumber(toBigInt(deposit.userShares), decimals);

        transactions.push({
          id: `${vault.id}-deposit-${index}-${deposit.id}`,
          type: "deposit",
          vault,
          vaultAddress: vault.address,
          amount: formatAmount(amount, symbol),
          amountUsd: formatUsd(amountUsd),
          symbol,
          timestamp,
          transactionHash: deposit.transactionHash ?? "",
          shares: formatAmount(shares, `v${symbol}`),
        });
      });

      (vault.redeems || []).forEach((redeem, index) => {
        if (redeem.user?.address?.toLowerCase() !== lowerAddress) return;

        const timestamp = Number(redeem.blockTimestamp) * 1000;
        const amount = toNumber(toBigInt(redeem.assets), decimals);
        const amountUsd = amount * price;
        const shares = toNumber(toBigInt(redeem.shares), decimals);

        transactions.push({
          id: `${vault.id}-redeem-${index}-${redeem.id}`,
          type: "withdraw",
          vault,
          vaultAddress: vault.address,
          amount: formatAmount(amount, symbol),
          amountUsd: formatUsd(amountUsd),
          symbol,
          timestamp,
          transactionHash: redeem.transactionHash ?? "",
          shares: formatAmount(shares, `v${symbol}`),
        });
      });
    });

    return transactions.sort((a, b) => b.timestamp - a.timestamp).slice(0, 50);
  }, [vaults, lowerAddress, nativePrice]);

  const loading = vaultLoading || userPortfolioLoading;
  const error = vaultError ?? userPortfolioError ?? null;

  return {
    loading,
    error,
    isConnected: !!connectedAddress,
    data: {
      positions,
      stats,
      revenueHistory,
      feeBreakdown,
      transactionHistory,
      userStats: userStatsSummary,
      userVaultBalances: userBalances,
    },
  };
};
