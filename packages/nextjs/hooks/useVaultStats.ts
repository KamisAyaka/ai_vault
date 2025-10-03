"use client";

import { useMemo } from "react";
import { formatUnits } from "viem";
import type { Vault, VaultStats, VaultStatsBreakdown } from "~~/types/vault";
import { useGlobalState } from "~~/services/store/store";

const STABLE_ASSETS = new Set(["USDC", "USDT", "DAI", "USDP", "TUSD"]);

const safeBigInt = (value?: string) => {
  try {
    return BigInt(value || "0");
  } catch {
    return 0n;
  }
};

const getUsdPrice = (symbol: string, nativeCurrencyPrice: number) => {
  if (STABLE_ASSETS.has(symbol)) {
    return 1;
  }

  if (symbol === "ETH" || symbol === "WETH") {
    return nativeCurrencyPrice;
  }

  return null;
};

export const useVaultStats = (vaults: Vault[]): VaultStats => {
  const nativeCurrencyPrice = useGlobalState(state => state.nativeCurrency.price);

  const stats = useMemo(() => {
    if (!vaults || vaults.length === 0) {
      return {
        totalVaults: 0,
        activeVaults: 0,
        totalValueLockedUsd: 0,
        totalValueLockedBreakdown: [],
        averageApy: 0,
        totalUsers: 0,
      } satisfies VaultStats;
    }

    const activeVaults = vaults.filter(v => v.isActive).length;

    const breakdownMap = new Map<string, VaultStatsBreakdown>();

    vaults.forEach(vault => {
      const symbol = vault.asset?.symbol?.toUpperCase() ?? "TOKEN";
      const decimals = vault.asset?.decimals ?? 18;
      const current = breakdownMap.get(symbol);
      const totalAssets = safeBigInt(vault.totalAssets);

      if (current) {
        breakdownMap.set(symbol, {
          ...current,
          amount: current.amount + totalAssets,
        });
      } else {
        breakdownMap.set(symbol, {
          symbol,
          amount: totalAssets,
          decimals,
        });
      }
    });

    const totalValueLockedBreakdown = Array.from(breakdownMap.values()).map(item => {
      const price = getUsdPrice(item.symbol, nativeCurrencyPrice);

      if (price === null || price <= 0) {
        return {
          ...item,
          usdValue: 0,
        } satisfies VaultStatsBreakdown;
      }

      try {
        const normalized = Number.parseFloat(formatUnits(item.amount, item.decimals));
        const usdValue = Number.isFinite(normalized) ? normalized * price : 0;
        return {
          ...item,
          usdValue,
        } satisfies VaultStatsBreakdown;
      } catch {
        return {
          ...item,
          usdValue: 0,
        } satisfies VaultStatsBreakdown;
      }
    });

    const totalValueLockedUsd = totalValueLockedBreakdown.reduce((sum, item) => sum + item.usdValue, 0);

    const uniqueUsers = new Set<string>();
    vaults.forEach(vault => {
      vault.deposits?.forEach(deposit => {
        if (deposit.user?.address) {
          uniqueUsers.add(deposit.user.address.toLowerCase());
        }
      });
    });

    // Placeholder: use static APY until historical performance is available
    const averageApy = totalValueLockedBreakdown.length > 0 ? 8.5 : 0;

    return {
      totalVaults: vaults.length,
      activeVaults,
      totalValueLockedUsd,
      totalValueLockedBreakdown,
      averageApy,
      totalUsers: uniqueUsers.size,
    } satisfies VaultStats;
  }, [nativeCurrencyPrice, vaults]);

  return stats;
};
