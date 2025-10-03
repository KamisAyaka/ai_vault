"use client";

import { formatUnits } from "viem";
import { CountUp } from "~~/components/ui/CountUp";
import type { VaultStatsBreakdown } from "~~/types/vault";

type StatsCardProps = {
  icon: string;
  label: string;
  value: string | number;
  formatValue?: (val: number) => string;
  subValue?: string;
  iconBg?: string;
};

export const StatsCard = ({ icon, label, value, subValue, iconBg = "bg-[#803100]", formatValue }: StatsCardProps) => {
  return (
    <div className="stat bg-black/40 backdrop-blur-sm shadow-lg rounded-lg border border-[#803100]/30">
      <div className="stat-figure text-[#fbe6dc]">
        <div className={`w-16 h-16 rounded-full ${iconBg} bg-opacity-20 flex items-center justify-center`}>
          <span className="text-3xl">{icon}</span>
        </div>
      </div>
      <div className="stat-title text-[#fbe6dc] opacity-90">{label}</div>
      <div className="stat-value text-white text-2xl md:text-3xl">
        {typeof value === "number" ? <CountUp value={value} format={formatValue} /> : value}
      </div>
      {subValue && <div className="stat-desc text-[#fbe6dc] text-sm opacity-70">{subValue}</div>}
    </div>
  );
};

type VaultStatsOverviewProps = {
  totalVaults: number;
  activeVaults: number;
  totalValueLockedUsd: number;
  totalValueLockedBreakdown: VaultStatsBreakdown[];
  averageApy: number;
  totalUsers: number;
};

const formatUsdValue = (value: number) => {
  if (!Number.isFinite(value) || value <= 0) {
    return "$0.00";
  }

  if (value >= 1_000_000_000) {
    return `$${(value / 1_000_000_000).toFixed(2)}B`;
  }

  if (value >= 1_000_000) {
    return `$${(value / 1_000_000).toFixed(2)}M`;
  }

  if (value >= 1_000) {
    return `$${(value / 1_000).toFixed(2)}K`;
  }

  return `$${value.toFixed(2)}`;
};

const formatBreakdown = (breakdown: VaultStatsBreakdown[]) => {
  if (!breakdown.length) {
    return "No current deposits";
  }

  return breakdown
    .map(({ symbol, amount, decimals, usdValue }) => {
      try {
        const normalized = formatUnits(amount, decimals);
        const numeric = Number.parseFloat(normalized);
        const formatted = Number.isFinite(numeric)
          ? numeric.toLocaleString(undefined, { maximumFractionDigits: 2 })
          : normalized;
        const usdText = usdValue > 0 ? ` ($${usdValue.toLocaleString(undefined, { maximumFractionDigits: 2 })})` : "";
        return `${formatted} ${symbol}${usdText}`;
      } catch {
        return `${symbol}`;
      }
    })
    .join(" · ");
};

export const VaultStatsOverview = ({
  totalVaults,
  activeVaults,
  totalValueLockedUsd,
  totalValueLockedBreakdown,
  averageApy,
  totalUsers,
}: VaultStatsOverviewProps) => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 w-full">
      <StatsCard
        icon="📊"
        label="Total Value Locked"
        value={totalValueLockedUsd}
        formatValue={formatUsdValue}
        subValue={formatBreakdown(totalValueLockedBreakdown)}
        iconBg="bg-[#803100]"
      />

      <StatsCard
        icon="💰"
        label="Active Vaults"
        value={activeVaults}
        formatValue={val => Math.round(val).toLocaleString()}
        subValue={`${totalVaults} total vaults`}
        iconBg="bg-[#803100]"
      />

      <StatsCard
        icon="👥"
        label="Total Users"
        value={totalUsers}
        formatValue={val => Math.round(val).toLocaleString()}
        iconBg="bg-[#803100]"
      />

      <StatsCard
        icon="📈"
        label="Average APY"
        value={averageApy}
        formatValue={val => `${val.toFixed(1)}%`}
        iconBg="bg-[#803100]"
      />
    </div>
  );
};
