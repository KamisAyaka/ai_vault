"use client";

import { useMemo } from "react";
import { formatUnits } from "viem";
import { useVaults } from "./useVaults";
import { useGlobalState } from "~~/services/store/store";
import type { Vault } from "~~/types/vault";

export interface VaultPerformance {
  vault: Vault;
  currentAPY: number;
  managementFeeRate: number;
  performanceFeeRate: number;
  thirtyDayAPY: number;
  ninetyDayAPY: number;
  allTimeAPY: number;
  totalFeesPaid: number;
  feeBreakdown: {
    managementFees: number;
    performanceFees: number;
  };
  riskMetrics: {
    volatility: number;
    maxDrawdown: number;
    sharpeRatio: number;
  };
}

type AggregateStats = {
  averageAPY: number;
  totalFees: number;
  averageVolatility: number;
  bestPerformingVault: Vault | null;
  worstPerformingVault: Vault | null;
};

const DAYS_IN_YEAR = 365;

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

const clampNumber = (value: number) => {
  if (!Number.isFinite(value)) return 0;
  if (Number.isNaN(value)) return 0;
  return value;
};

const STABLE_ASSETS = new Set(["USDC", "USDT", "DAI", "USDP", "TUSD"]); // 简单稳定币列表

const calculateNetDeposits = (vault: Vault) => {
  const depositSum = (vault.deposits || []).reduce<bigint>((acc, deposit) => acc + toBigInt(deposit.assets), 0n);
  const redeemSum = (vault.redeems || []).reduce<bigint>((acc, redeem) => acc + toBigInt(redeem.assets), 0n);
  return depositSum - redeemSum;
};

const annualisedReturn = (growth: number, daysActive: number) => {
  if (!Number.isFinite(growth) || growth <= 0 || !Number.isFinite(daysActive) || daysActive <= 0) {
    return 0;
  }

  const periods = DAYS_IN_YEAR / daysActive;
  if (!Number.isFinite(periods) || periods <= 0) return 0;

  return (Math.pow(growth, periods) - 1) * 100;
};

const calcVolatility = (values: number[]) => {
  if (values.length < 2) return 0;
  const mean = values.reduce((sum, value) => sum + value, 0) / values.length;
  if (mean === 0) return 0;
  const variance = values.reduce((sum, value) => sum + Math.pow(value - mean, 2), 0) / values.length;
  return Math.sqrt(variance) / Math.abs(mean);
};

export const useVaultPerformance = (limit = 100) => {
  const { vaults, loading, error } = useVaults(limit);
  const nativePrice = useGlobalState(state => state.nativeCurrency.price) || 0;

  const performanceData = useMemo<VaultPerformance[]>(() => {
    if (!vaults || vaults.length === 0) return [];

    return vaults.map(vault => {
      const decimals = vault.asset?.decimals ?? 18;
      const totalAssets = toBigInt(vault.totalAssets);
      const netDeposits = calculateNetDeposits(vault);

      const currentValue = toNumber(totalAssets, decimals);
      const netDepositsValue = toNumber(netDeposits, decimals);

      const assetSymbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const assetPrice = STABLE_ASSETS.has(assetSymbol)
        ? 1
        : assetSymbol === "ETH" || assetSymbol === "WETH"
        ? nativePrice || 0
        : 1;

      const currentValueUsd = currentValue * (assetPrice || 0);
      const netDepositsUsd = netDepositsValue * (assetPrice || 0);
      const profitUsd = currentValueUsd - netDepositsUsd;

      const createdAt = Number(vault.createdAt ?? "0") * 1000;
      const now = Date.now();
      const daysActive = Math.max(1, (now - createdAt) / (1000 * 60 * 60 * 24));

      const growthFactor = netDepositsValue > 0 ? currentValue / netDepositsValue : 0;
      const currentAPY = clampNumber(annualisedReturn(growthFactor, daysActive));

      const DaysToPeriod = (days: number) => {
        const periodStart = now - days * 24 * 60 * 60 * 1000;
        const periodDeposits = (vault.deposits || [])
          .filter(deposit => Number(deposit.blockTimestamp) * 1000 >= periodStart)
          .reduce<bigint>((acc, deposit) => acc + toBigInt(deposit.assets), 0n);
        const periodRedeems = (vault.redeems || [])
          .filter(redeem => Number(redeem.blockTimestamp) * 1000 >= periodStart)
          .reduce<bigint>((acc, redeem) => acc + toBigInt(redeem.assets), 0n);

        const periodNet = periodDeposits - periodRedeems;
        const periodNetValue = toNumber(periodNet, decimals);
        if (periodNetValue <= 0 || currentValue <= 0) return 0;
        return clampNumber(((currentValue - periodNetValue) / periodNetValue) * 100);
      };

      const managementFeeRate = 0.01;
      const performanceFeeRate = 0.2;
      const managementFees = clampNumber(currentValueUsd * managementFeeRate * (daysActive / DAYS_IN_YEAR));
      const performanceFees = clampNumber(Math.max(profitUsd, 0) * performanceFeeRate);

      const transactionValues = (vault.deposits || [])
        .map(deposit => toNumber(toBigInt(deposit.assets), decimals))
        .filter(value => value > 0);

      const volatility = clampNumber(calcVolatility(transactionValues));
      const maxRedeem = (vault.redeems || [])
        .map(redeem => toNumber(toBigInt(redeem.assets), decimals))
        .reduce((max, value) => Math.max(max, value), 0);
      const maxDrawdown = netDepositsValue > 0 ? clampNumber(Math.min(maxRedeem / netDepositsValue, 1)) : 0;
      const sharpeRatio = volatility > 0 ? clampNumber((currentAPY / 100) / volatility) : currentAPY > 0 ? 5 : 0;

      return {
        vault,
        currentAPY,
        managementFeeRate,
        performanceFeeRate,
        thirtyDayAPY: DaysToPeriod(30),
        ninetyDayAPY: DaysToPeriod(90),
        allTimeAPY: currentAPY,
        totalFeesPaid: managementFees + performanceFees,
        feeBreakdown: {
          managementFees,
          performanceFees,
        },
        riskMetrics: {
          volatility,
          maxDrawdown,
          sharpeRatio,
        },
      };
    });
  }, [vaults, nativePrice]);

  const aggregateStats = useMemo<AggregateStats>(() => {
    if (performanceData.length === 0) {
      return {
        averageAPY: 0,
        totalFees: 0,
        averageVolatility: 0,
        bestPerformingVault: null,
        worstPerformingVault: null,
      };
    }

    const averageAPY = performanceData.reduce((sum, item) => sum + item.currentAPY, 0) / performanceData.length;
    const totalFees = performanceData.reduce((sum, item) => sum + item.totalFeesPaid, 0);
    const averageVolatility = performanceData.reduce((sum, item) => sum + item.riskMetrics.volatility, 0) / performanceData.length;

    const sorted = [...performanceData].sort((a, b) => b.currentAPY - a.currentAPY);
    return {
      averageAPY,
      totalFees,
      averageVolatility,
      bestPerformingVault: sorted[0]?.vault ?? null,
      worstPerformingVault: sorted[sorted.length - 1]?.vault ?? null,
    };
  }, [performanceData]);

  return {
    loading,
    error,
    data: performanceData,
    stats: aggregateStats,
    // 暂无额外数据源可刷新，保持接口一致
    refetch: () => undefined,
  };
};
