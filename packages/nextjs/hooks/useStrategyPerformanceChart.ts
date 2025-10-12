"use client";

import { useMemo } from "react";
import { formatUnits } from "viem";
import type { Vault } from "~~/types/vault";

export type PerformanceChartPoint = {
  date: string;
  timestamp: number;
  strategyValue: number; // 策略净值
  holdValue: number; // 持有不动净值
  formattedStrategy: string;
  formattedHold: string;
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

/**
 * 计算策略净值曲线和持有不动基准曲线
 */
export const useStrategyPerformanceChart = (vault: Vault | undefined, days = 30) => {
  const chartData = useMemo<PerformanceChartPoint[]>(() => {
    if (!vault) return [];

    const decimals = vault.asset?.decimals ?? 18;
    const deposits = vault.deposits || [];
    const redeems = vault.redeems || [];

    // 合并所有交易事件
    type TxEvent = {
      timestamp: number;
      type: "deposit" | "redeem";
      assets: bigint;
      shares: bigint;
    };

    const events: TxEvent[] = [
      ...deposits.map(d => ({
        timestamp: Number(d.blockTimestamp) * 1000,
        type: "deposit" as const,
        assets: toBigInt(d.assets),
        shares: toBigInt(d.userShares),
      })),
      ...redeems.map(r => ({
        timestamp: Number(r.blockTimestamp) * 1000,
        type: "redeem" as const,
        assets: toBigInt(r.assets),
        shares: toBigInt(r.shares),
      })),
    ].sort((a, b) => a.timestamp - b.timestamp);

    if (events.length === 0) return [];

    // 计算初始投入
    const firstEvent = events[0];
    const initialInvestment = toNumber(firstEvent.assets, decimals);
    if (initialInvestment === 0) return [];

    // 生成时间点
    const now = Date.now();
    const startTime = firstEvent.timestamp;
    const endTime = now;
    const totalDays = Math.min(days, Math.ceil((endTime - startTime) / (1000 * 60 * 60 * 24)));
    const interval = (endTime - startTime) / Math.max(totalDays, 1);

    const points: PerformanceChartPoint[] = [];

    // 模拟策略净值增长(使用当前TVL作为最终值)
    const currentTVL = toNumber(toBigInt(vault.totalAssets), decimals);
    const totalDeposits = deposits.reduce((sum, d) => sum + toBigInt(d.assets), 0n);
    const totalRedeems = redeems.reduce((sum, r) => sum + toBigInt(r.assets), 0n);
    const netDeposits = toNumber(totalDeposits - totalRedeems, decimals);

    // 计算策略最终净值倍数
    const finalStrategyMultiplier = netDeposits > 0 ? currentTVL / netDeposits : 1;

    for (let i = 0; i <= totalDays; i++) {
      const timestamp = startTime + i * interval;
      const date = new Date(timestamp);

      // 线性增长策略净值(简化模型)
      const progress = i / totalDays;
      const strategyValue = initialInvestment * (1 + (finalStrategyMultiplier - 1) * progress);

      // 持有不动基准(假设无增长)
      const holdValue = initialInvestment;

      points.push({
        date: date.toLocaleDateString("en-US", { month: "short", day: "numeric" }),
        timestamp: Math.floor(timestamp / 1000),
        strategyValue,
        holdValue,
        formattedStrategy: `$${strategyValue.toFixed(2)}`,
        formattedHold: `$${holdValue.toFixed(2)}`,
      });
    }

    return points;
  }, [vault, days]);

  // 计算超额收益
  const excessReturn = useMemo(() => {
    if (chartData.length === 0) return 0;
    const first = chartData[0];
    const last = chartData[chartData.length - 1];
    if (first.holdValue === 0) return 0;

    const strategyReturn = ((last.strategyValue - first.strategyValue) / first.strategyValue) * 100;
    const holdReturn = ((last.holdValue - first.holdValue) / first.holdValue) * 100;

    return strategyReturn - holdReturn;
  }, [chartData]);

  return {
    chartData,
    excessReturn,
    loading: false,
    error: null,
  };
};
