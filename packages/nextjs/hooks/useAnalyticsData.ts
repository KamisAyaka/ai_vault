"use client";

import { useMemo } from "react";
import { useVaults } from "./useVaults";
import { formatUnits } from "viem";
import { useGlobalState } from "~~/services/store/store";
import type { Vault } from "~~/types/vault";

const STABLE_ASSETS = new Set(["USDC", "USDT", "DAI", "USDP", "TUSD"]);
const DAYS_IN_YEAR = 365;

type HistoryPoint = {
  date: string;
  timestamp: number;
  value: number;
  formatted: string;
};

type AssetDistributionItem = {
  symbol: string;
  address: string;
  decimals: number;
  value: number;
  percentage: number;
  formattedValue: string;
  formattedAssetValue: string;
};

type ProtocolDistributionItem = {
  name: string;
  value: number;
  percentage: number;
  formattedValue: string;
};

type TrendPoint = {
  date: string;
  deposits: number;
  withdrawals: number;
  depositCount: number;
  withdrawalCount: number;
  formattedDeposits: string;
  formattedWithdrawals: string;
  depositsHeight: number;
  withdrawalsHeight: number;
};

type ActivityItem = {
  id: string;
  type: "deposit" | "withdraw";
  vault: string;
  amount: string;
  usdValue: string;
  user: string;
  transactionHash: string;
  timestamp: number;
  timeAgo: string;
};

type RankedVault = {
  vault: Vault;
  tvlUsd: number;
  apy: number;
  userCount: number;
  sevenDayRevenueUsd: number;
};

type AnalyticsStats = {
  totalVaults: number;
  activeVaults: number;
  totalValueLockedUsd: number;
  totalUsers: number;
  averageApy: number;
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

const getAssetPrice = (symbol: string, nativePrice: number) => {
  if (STABLE_ASSETS.has(symbol)) return 1;
  if (symbol === "ETH" || symbol === "WETH") return nativePrice || 0;
  return 1;
};

const calculateNetDeposits = (vault: Vault) => {
  const deposits = (vault.deposits || []).reduce<bigint>((acc, deposit) => acc + toBigInt(deposit.assets), 0n);
  const redeems = (vault.redeems || []).reduce<bigint>((acc, redeem) => acc + toBigInt(redeem.assets), 0n);
  return deposits - redeems;
};

const annualisedReturn = (growth: number, daysActive: number) => {
  if (!Number.isFinite(growth) || growth <= 0 || !Number.isFinite(daysActive) || daysActive <= 0) return 0;
  const periods = DAYS_IN_YEAR / daysActive;
  if (!Number.isFinite(periods) || periods <= 0) return 0;
  return (Math.pow(growth, periods) - 1) * 100;
};

const formatUsd = (value: number) => {
  if (!Number.isFinite(value)) return "$0";
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(2)}M`;
  if (value >= 1_000) return `$${(value / 1_000).toFixed(2)}K`;
  return `$${value.toFixed(2)}`;
};

const formatTimeAgo = (ms: number) => {
  const minutes = Math.floor(ms / (1000 * 60));
  const hours = Math.floor(ms / (1000 * 60 * 60));
  if (minutes < 60) return `${minutes}m ago`;
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
};

export const useAnalyticsData = () => {
  const { vaults, loading, error } = useVaults(1000, 0, "totalAssets", "desc");
  const nativePrice = useGlobalState(state => state.nativeCurrency.price) || 0;

  const vaultSnapshots = useMemo(() => {
    if (!vaults)
      return [] as Array<{
        vault: Vault;
        valueUsd: number;
        netDepositsUsd: number;
        profitUsd: number;
        apy: number;
        daysActive: number;
      }>;

    return vaults.map(vault => {
      const decimals = vault.asset?.decimals ?? 18;
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const price = getAssetPrice(symbol, nativePrice);

      const totalAssets = toBigInt(vault.totalAssets);
      const netDeposits = calculateNetDeposits(vault);

      const totalAssetsValue = toNumber(totalAssets, decimals);
      const netDepositsValue = toNumber(netDeposits, decimals);
      const valueUsd = totalAssetsValue * price;
      const netDepositsUsd = netDepositsValue * price;
      const profitUsd = valueUsd - netDepositsUsd;

      const createdAtMs = Number(vault.createdAt ?? "0") * 1000;
      const daysActive = Math.max(1, (Date.now() - createdAtMs) / (1000 * 60 * 60 * 24));
      const growthFactor = netDepositsValue > 0 ? totalAssetsValue / Math.max(netDepositsValue, 1e-9) : 0;
      const apy = annualisedReturn(growthFactor, daysActive);

      return {
        vault,
        valueUsd,
        netDepositsUsd,
        profitUsd,
        apy,
        daysActive,
      };
    });
  }, [vaults, nativePrice]);

  const totalValueLockedUsd = useMemo(
    () => vaultSnapshots.reduce((sum, snapshot) => sum + Math.max(snapshot.valueUsd, 0), 0),
    [vaultSnapshots],
  );

  const flowEvents = useMemo(() => {
    if (!vaults) return [] as Array<{ timestamp: number; delta: number }>;

    const events: Array<{ timestamp: number; delta: number }> = [];

    vaults.forEach(vault => {
      const decimals = vault.asset?.decimals ?? 18;
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const price = getAssetPrice(symbol, nativePrice);

      (vault.deposits || []).forEach(deposit => {
        const timestamp = Number(deposit.blockTimestamp) * 1000;
        const value = toNumber(toBigInt(deposit.assets), decimals) * price;
        events.push({ timestamp, delta: value });
      });

      (vault.redeems || []).forEach(redeem => {
        const timestamp = Number(redeem.blockTimestamp) * 1000;
        const value = toNumber(toBigInt(redeem.assets), decimals) * price;
        events.push({ timestamp, delta: -value });
      });
    });

    return events.sort((a, b) => a.timestamp - b.timestamp);
  }, [vaults, nativePrice]);

  const tvlHistory = useMemo<HistoryPoint[]>(() => {
    const daysToShow = 7;
    const points: HistoryPoint[] = [];
    if (!vaults) return points;

    const totalFlow = flowEvents.reduce((sum, event) => sum + event.delta, 0);
    const initialValue = Math.max(totalValueLockedUsd - totalFlow, 0);

    const days: Date[] = [];
    for (let index = daysToShow - 1; index >= 0; index--) {
      const date = new Date();
      date.setHours(23, 59, 59, 999);
      date.setDate(date.getDate() - index);
      days.push(date);
    }

    let cumulative = initialValue;
    let eventIndex = 0;

    days.forEach(day => {
      while (eventIndex < flowEvents.length && flowEvents[eventIndex].timestamp <= day.getTime()) {
        cumulative = Math.max(0, cumulative + flowEvents[eventIndex].delta);
        eventIndex++;
      }

      points.push({
        date: day.toLocaleDateString("en-US", { month: "short", day: "numeric" }),
        timestamp: Math.floor(day.getTime() / 1000),
        value: cumulative,
        formatted: formatUsd(cumulative),
      });
    });

    return points;
  }, [flowEvents, totalValueLockedUsd, vaults]);

  const assetDistribution = useMemo<AssetDistributionItem[]>(() => {
    if (!vaults) return [];

    const map = new Map<string, AssetDistributionItem>();

    vaults.forEach(vault => {
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "UNKNOWN";
      const decimals = vault.asset?.decimals ?? 18;
      const price = getAssetPrice(symbol, nativePrice);
      const value = toNumber(toBigInt(vault.totalAssets), decimals) * price;

      if (!map.has(symbol)) {
        map.set(symbol, {
          symbol,
          address: vault.asset?.address ?? "",
          decimals,
          value: 0,
          percentage: 0,
          formattedValue: "",
          formattedAssetValue: "",
        });
      }

      const entry = map.get(symbol)!;
      entry.value += value;
    });

    const total = Array.from(map.values()).reduce((sum, entry) => sum + entry.value, 0);

    return Array.from(map.values())
      .map(entry => ({
        ...entry,
        percentage: total > 0 ? (entry.value / total) * 100 : 0,
        formattedValue: formatUsd(entry.value),
        formattedAssetValue: entry.value.toLocaleString(undefined, { maximumFractionDigits: 0 }),
      }))
      .sort((a, b) => b.value - a.value);
  }, [vaults, nativePrice]);

  const protocolDistribution = useMemo<ProtocolDistributionItem[]>(() => {
    if (!vaults) return [];

    const valueByProtocol = new Map<string, number>();

    const addValue = (name: string, value: number) => {
      valueByProtocol.set(name, (valueByProtocol.get(name) ?? 0) + value);
    };

    vaults.forEach(vault => {
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const price = getAssetPrice(symbol, nativePrice);
      const decimals = vault.asset?.decimals ?? 18;
      const vaultValue = toNumber(toBigInt(vault.totalAssets), decimals) * price;

      const allocated =
        vault.allocations?.reduce((sum, allocation) => sum + Number(allocation.allocation || "0"), 0) ?? 0;

      (vault.allocations || []).forEach(allocation => {
        const percentage = Number(allocation.allocation || "0") / 1000;
        const value = vaultValue * percentage;
        const adapterType = allocation.adapterType?.toLowerCase() ?? "unknown";

        if (adapterType.includes("aave")) {
          addValue("Aave V3", value);
        } else if (adapterType.includes("v3")) {
          addValue("Uniswap V3", value);
        } else if (adapterType.includes("v2")) {
          addValue("Uniswap V2", value);
        } else {
          addValue("Other", value);
        }
      });

      const unallocated = Math.max(0, 1000 - allocated) / 1000;
      if (unallocated > 0) {
        addValue("Unallocated", vaultValue * unallocated);
      }
    });

    const total = Array.from(valueByProtocol.values()).reduce((sum, value) => sum + value, 0);

    return Array.from(valueByProtocol.entries())
      .map(([name, value]) => ({
        name,
        value,
        percentage: total > 0 ? (value / total) * 100 : 0,
        formattedValue: formatUsd(value),
      }))
      .sort((a, b) => b.value - a.value);
  }, [vaults, nativePrice]);

  const transactionTrends = useMemo<{ deposits: TrendPoint[]; withdrawals: TrendPoint[] }>(() => {
    if (!vaults) {
      return { deposits: [], withdrawals: [] };
    }

    const days: TrendPoint[] = [];
    const now = new Date();

    for (let index = 6; index >= 0; index--) {
      const date = new Date(now);
      date.setHours(0, 0, 0, 0);
      date.setDate(date.getDate() - index);
      days.push({
        date: date.toLocaleDateString("en-US", { weekday: "short" }),
        deposits: 0,
        withdrawals: 0,
        depositCount: 0,
        withdrawalCount: 0,
        formattedDeposits: "$0",
        formattedWithdrawals: "$0",
        depositsHeight: 0,
        withdrawalsHeight: 0,
      });
    }

    const updateDay = (timestamp: number, updater: (day: TrendPoint) => void) => {
      const dayDiff = Math.floor((now.getTime() - timestamp) / (1000 * 60 * 60 * 24));
      if (dayDiff >= 0 && dayDiff < days.length) {
        const index = days.length - 1 - dayDiff;
        updater(days[index]);
      }
    };

    vaults.forEach(vault => {
      const decimals = vault.asset?.decimals ?? 18;
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const price = getAssetPrice(symbol, nativePrice);

      (vault.deposits || []).forEach(deposit => {
        const timestamp = Number(deposit.blockTimestamp) * 1000;
        const value = toNumber(toBigInt(deposit.assets), decimals) * price;
        updateDay(timestamp, day => {
          day.deposits += value;
          day.depositCount += 1;
        });
      });

      (vault.redeems || []).forEach(redeem => {
        const timestamp = Number(redeem.blockTimestamp) * 1000;
        const value = toNumber(toBigInt(redeem.assets), decimals) * price;
        updateDay(timestamp, day => {
          day.withdrawals += value;
          day.withdrawalCount += 1;
        });
      });
    });

    const maxDeposit = Math.max(...days.map(day => day.deposits), 0);
    const maxWithdrawal = Math.max(...days.map(day => day.withdrawals), 0);

    days.forEach(day => {
      day.formattedDeposits = formatUsd(day.deposits);
      day.formattedWithdrawals = formatUsd(day.withdrawals);
      day.depositsHeight = maxDeposit > 0 ? (day.deposits / maxDeposit) * 100 : 0;
      day.withdrawalsHeight = maxWithdrawal > 0 ? (day.withdrawals / maxWithdrawal) * 100 : 0;
    });

    return {
      deposits: days.map(day => ({ ...day })),
      withdrawals: days.map(day => ({ ...day })),
    };
  }, [vaults, nativePrice]);

  const recentActivity = useMemo<ActivityItem[]>(() => {
    if (!vaults) return [];

    const activities: ActivityItem[] = [];

    vaults.forEach(vault => {
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const decimals = vault.asset?.decimals ?? 18;
      const price = getAssetPrice(symbol, nativePrice);

      (vault.deposits || []).forEach((deposit, index) => {
        const timestamp = Number(deposit.blockTimestamp) * 1000;
        const amount = toNumber(toBigInt(deposit.assets), decimals);
        const usd = amount * price;
        activities.push({
          id: `deposit-${vault.id}-${index}-${deposit.id}`,
          type: "deposit",
          vault: vault.name,
          amount: `+${amount.toLocaleString(undefined, { maximumFractionDigits: 4 })} ${symbol}`,
          usdValue: formatUsd(usd),
          user: deposit.user?.address ?? "0x0000",
          transactionHash: deposit.transactionHash ?? "0x0000",
          timestamp,
          timeAgo: formatTimeAgo(Date.now() - timestamp),
        });
      });

      (vault.redeems || []).forEach((redeem, index) => {
        const timestamp = Number(redeem.blockTimestamp) * 1000;
        const amount = toNumber(toBigInt(redeem.assets), decimals);
        const usd = amount * price;
        activities.push({
          id: `redeem-${vault.id}-${index}-${redeem.id}`,
          type: "withdraw",
          vault: vault.name,
          amount: `-${amount.toLocaleString(undefined, { maximumFractionDigits: 4 })} ${symbol}`,
          usdValue: formatUsd(usd),
          user: redeem.user?.address ?? "0x0000",
          transactionHash: redeem.transactionHash ?? "0x0000",
          timestamp,
          timeAgo: formatTimeAgo(Date.now() - timestamp),
        });
      });
    });

    return activities.sort((a, b) => b.timestamp - a.timestamp).slice(0, 25);
  }, [vaults, nativePrice]);

  const rankedVaults = useMemo<RankedVault[]>(() => {
    return vaultSnapshots
      .map(snapshot => {
        const sevenDayShare = Math.min(7 / Math.max(snapshot.daysActive, 1), 1);
        const sevenDayRevenueUsd = Math.max(snapshot.profitUsd, 0) * sevenDayShare;
        const userCount = new Set(
          (snapshot.vault.deposits || []).map(deposit => deposit.user?.address?.toLowerCase() ?? ""),
        ).size;

        return {
          vault: snapshot.vault,
          tvlUsd: snapshot.valueUsd,
          apy: snapshot.apy,
          userCount,
          sevenDayRevenueUsd,
        };
      })
      .sort((a, b) => b.tvlUsd - a.tvlUsd)
      .slice(0, 10);
  }, [vaultSnapshots]);

  const stats = useMemo<AnalyticsStats>(() => {
    if (!vaults || vaults.length === 0) {
      return {
        totalVaults: 0,
        activeVaults: 0,
        totalValueLockedUsd: 0,
        totalUsers: 0,
        averageApy: 0,
      };
    }

    const totalVaults = vaults.length;
    const activeVaults = vaults.filter(vault => vault.isActive).length;
    const totalUsers = new Set(
      vaults.flatMap(vault => vault.deposits?.map(deposit => deposit.user?.address?.toLowerCase() ?? "")),
    ).size;

    const apyValues = vaultSnapshots
      .filter(snapshot => snapshot.netDepositsUsd > 0)
      .map(snapshot => snapshot.apy)
      .filter(value => Number.isFinite(value));

    const averageApy = apyValues.length > 0 ? apyValues.reduce((sum, value) => sum + value, 0) / apyValues.length : 0;

    return {
      totalVaults,
      activeVaults,
      totalValueLockedUsd,
      totalUsers,
      averageApy,
    };
  }, [vaults, vaultSnapshots, totalValueLockedUsd]);

  return {
    loading,
    error,
    data: {
      tvlHistory,
      assetDistribution,
      protocolDistribution,
      transactionTrends,
      recentActivity,
      rankedVaults,
      stats,
    },
  };
};
