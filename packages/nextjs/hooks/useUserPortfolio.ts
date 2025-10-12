"use client";

import { useCallback, useEffect, useState } from "react";
import { useAccount } from "wagmi";
import type { UserStatsEntity, UserVaultBalance } from "~~/types/vault";
import { GetUserPortfolioDocument, execute } from "~~/utils/graphclient";

type GetUserPortfolioData = {
  userStats?: UserStatsEntity | null;
  userVaultBalances: UserVaultBalance[];
};

const normalizeAddress = (address?: string | null) => address?.toLowerCase() ?? null;

export const useUserPortfolio = (addressOverride?: string) => {
  const { address: connectedAddress } = useAccount();
  const resolvedAddress = normalizeAddress(addressOverride ?? connectedAddress);

  const [userStats, setUserStats] = useState<UserStatsEntity | null>(null);
  const [balances, setBalances] = useState<UserVaultBalance[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetchPortfolio = useCallback(async () => {
    if (!resolvedAddress) {
      setUserStats(null);
      setBalances([]);
      setLoading(false);
      setError(null);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const result = await execute<GetUserPortfolioData>(GetUserPortfolioDocument, {
        userId: resolvedAddress,
      });

      setUserStats(result.data?.userStats ?? null);
      setBalances(result.data?.userVaultBalances ?? []);
    } catch (err) {
      setError(err instanceof Error ? err : new Error("Failed to fetch user portfolio"));
      setUserStats(null);
      setBalances([]);
    } finally {
      setLoading(false);
    }
  }, [resolvedAddress]);

  useEffect(() => {
    void fetchPortfolio();
  }, [fetchPortfolio]);

  return {
    loading,
    error,
    userStats,
    balances,
    address: resolvedAddress ?? undefined,
    refetch: fetchPortfolio,
  };
};
