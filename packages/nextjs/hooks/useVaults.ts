"use client";

import { useCallback, useEffect, useState } from "react";
import { execute, GetVaultsDocument } from "~~/utils/graphclient";
import type { Vault } from "~~/types/vault";

type UseVaultsResult = {
  vaults: Vault[];
  loading: boolean;
  error: Error | null;
  refetch: () => Promise<void>;
};

type GetVaultsData = {
  vaults: Vault[];
};

export const useVaults = (
  first: number = 100,
  skip: number = 0,
  orderBy: string = "totalAssets",
  orderDirection: "asc" | "desc" = "desc",
): UseVaultsResult => {
  const [vaults, setVaults] = useState<Vault[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchVaults = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const result = await execute<GetVaultsData>(GetVaultsDocument, {
        first,
        skip,
        orderBy,
        orderDirection,
      });

      if (result.data?.vaults) {
        setVaults(result.data.vaults);
      } else {
        setVaults([]);
      }
    } catch (err) {
      console.error("Error fetching vaults:", err);
      setError(err instanceof Error ? err : new Error("Failed to fetch vaults"));
      setVaults([]);
    } finally {
      setLoading(false);
    }
  }, [first, skip, orderBy, orderDirection]);

  useEffect(() => {
    void fetchVaults();
  }, [fetchVaults]);

  return {
    vaults,
    loading,
    error,
    refetch: fetchVaults,
  };
};
