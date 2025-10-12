"use client";

import { useCallback, useEffect } from "react";
import { useGlobalState } from "~~/services/store/store";

type TokenPriceResponse = {
  prices: Record<string, number>;
  updatedAt: number;
};

const REFRESH_INTERVAL = 5 * 60 * 1000; // 5 minutes

export const useTokenUsdPrices = () => {
  const tokenPrices = useGlobalState(state => state.tokenPrices);
  const tokenPricesUpdatedAt = useGlobalState(state => state.tokenPricesUpdatedAt);
  const isFetchingTokenPrices = useGlobalState(state => state.isFetchingTokenPrices);
  const setTokenPrices = useGlobalState(state => state.setTokenPrices);
  const setIsFetchingTokenPrices = useGlobalState(state => state.setIsFetchingTokenPrices);

  const fetchPrices = useCallback(async () => {
    try {
      setIsFetchingTokenPrices(true);
      const response = await fetch("/api/token-prices", {
        method: "GET",
        headers: {
          "Cache-Control": "no-cache",
        },
      });

      if (!response.ok) {
        console.error("Failed to fetch token prices", response.statusText);
        return;
      }

      const json = (await response.json()) as TokenPriceResponse;
      if (json?.prices) {
        setTokenPrices(json.prices, json.updatedAt);
      }
    } catch (error) {
      console.error("Failed to fetch token prices", error);
    } finally {
      setIsFetchingTokenPrices(false);
    }
  }, [setIsFetchingTokenPrices, setTokenPrices]);

  useEffect(() => {
    const shouldFetch = !tokenPricesUpdatedAt || Date.now() - tokenPricesUpdatedAt > REFRESH_INTERVAL;
    if (shouldFetch && !isFetchingTokenPrices) {
      void fetchPrices();
    }
  }, [fetchPrices, isFetchingTokenPrices, tokenPricesUpdatedAt]);

  useEffect(() => {
    const interval = setInterval(() => {
      void fetchPrices();
    }, REFRESH_INTERVAL);

    return () => clearInterval(interval);
  }, [fetchPrices]);

  return {
    tokenPrices,
    updatedAt: tokenPricesUpdatedAt,
    isFetching: isFetchingTokenPrices,
    refresh: fetchPrices,
  };
};
