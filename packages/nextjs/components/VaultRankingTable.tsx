"use client";

import { useMemo, useState } from "react";
import { useTranslations } from "~~/services/i18n/I18nProvider";

type RankedVault = {
  vault: {
    id: string;
    name: string;
    isActive: boolean;
  };
  tvlUsd: number;
  apy: number;
  sevenDayRevenueUsd: number;
  userCount: number;
  sharpeRatio?: number;
};

type SortField = "tvl" | "apy" | "revenue" | "users" | "sharpe";
type SortOrder = "asc" | "desc";

type VaultRankingTableProps = {
  vaults: RankedVault[];
};

const formatNumber = (value: number, maximumFractionDigits = 0) => {
  if (!Number.isFinite(value)) return "0";
  return value.toLocaleString(undefined, { maximumFractionDigits });
};

export const VaultRankingTable = ({ vaults }: VaultRankingTableProps) => {
  const tTables = useTranslations("common.tables");
  const tStatus = useTranslations("common.status");
  const t = useTranslations("analytics.ranking");

  const [sortField, setSortField] = useState<SortField>("tvl");
  const [sortOrder, setSortOrder] = useState<SortOrder>("desc");

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      // Toggle order if clicking the same field
      setSortOrder(sortOrder === "asc" ? "desc" : "asc");
    } else {
      // Default to descending for new field
      setSortField(field);
      setSortOrder("desc");
    }
  };

  const sortedVaults = useMemo(() => {
    const sorted = [...vaults].sort((a, b) => {
      let compareA: number;
      let compareB: number;

      switch (sortField) {
        case "tvl":
          compareA = Number.isFinite(a.tvlUsd) ? a.tvlUsd : 0;
          compareB = Number.isFinite(b.tvlUsd) ? b.tvlUsd : 0;
          break;
        case "apy":
          compareA = Number.isFinite(a.apy) ? a.apy : 0;
          compareB = Number.isFinite(b.apy) ? b.apy : 0;
          break;
        case "revenue":
          compareA = Number.isFinite(a.sevenDayRevenueUsd) ? a.sevenDayRevenueUsd : 0;
          compareB = Number.isFinite(b.sevenDayRevenueUsd) ? b.sevenDayRevenueUsd : 0;
          break;
        case "users":
          compareA = a.userCount || 0;
          compareB = b.userCount || 0;
          break;
        case "sharpe":
          compareA = a.sharpeRatio ?? 0;
          compareB = b.sharpeRatio ?? 0;
          break;
        default:
          return 0;
      }

      if (sortOrder === "asc") {
        return compareA - compareB;
      } else {
        return compareB - compareA;
      }
    });

    return sorted;
  }, [vaults, sortField, sortOrder]);

  const getSortIcon = (field: SortField) => {
    if (sortField !== field) {
      return <span className="opacity-40">↕</span>;
    }
    return sortOrder === "desc" ? <span className="text-[#803100]">↓</span> : <span className="text-[#803100]">↑</span>;
  };

  return (
    <div>
      <div className="mb-4 flex flex-wrap gap-2">
        <span className="text-sm text-[#fbe6dc]/70">{t("sortBy")}:</span>
        <button
          onClick={() => handleSort("tvl")}
          className={`btn btn-xs ${sortField === "tvl" ? "bg-[#803100] text-white" : "bg-black/40 text-[#fbe6dc] border-[#803100]/30"}`}
        >
          {tTables("tvl")} {getSortIcon("tvl")}
        </button>
        <button
          onClick={() => handleSort("apy")}
          className={`btn btn-xs ${sortField === "apy" ? "bg-[#803100] text-white" : "bg-black/40 text-[#fbe6dc] border-[#803100]/30"}`}
        >
          {tTables("apy")} {getSortIcon("apy")}
        </button>
        <button
          onClick={() => handleSort("revenue")}
          className={`btn btn-xs ${sortField === "revenue" ? "bg-[#803100] text-white" : "bg-black/40 text-[#fbe6dc] border-[#803100]/30"}`}
        >
          {tTables("revenue7d")} {getSortIcon("revenue")}
        </button>
        <button
          onClick={() => handleSort("users")}
          className={`btn btn-xs ${sortField === "users" ? "bg-[#803100] text-white" : "bg-black/40 text-[#fbe6dc] border-[#803100]/30"}`}
        >
          {tTables("users")} {getSortIcon("users")}
        </button>
        <button
          onClick={() => handleSort("sharpe")}
          className={`btn btn-xs ${sortField === "sharpe" ? "bg-[#803100] text-white" : "bg-black/40 text-[#fbe6dc] border-[#803100]/30"}`}
        >
          {t("sharpeRatio")} {getSortIcon("sharpe")}
        </button>
      </div>

      <div className="card bg-black/60 backdrop-blur-sm shadow-xl overflow-x-auto border border-[#803100]/30">
        <table className="table">
          <thead>
            <tr className="border-b border-[#803100]/30">
              <th className="text-[#fbe6dc]">{tTables("rank")}</th>
              <th className="text-[#fbe6dc] cursor-pointer hover:text-white" onClick={() => handleSort("tvl")}>
                {tTables("vault")}
              </th>
              <th className="text-[#fbe6dc] cursor-pointer hover:text-white" onClick={() => handleSort("tvl")}>
                {tTables("tvl")} {getSortIcon("tvl")}
              </th>
              <th className="text-[#fbe6dc] cursor-pointer hover:text-white" onClick={() => handleSort("apy")}>
                {tTables("apy")} {getSortIcon("apy")}
              </th>
              <th className="text-[#fbe6dc] cursor-pointer hover:text-white" onClick={() => handleSort("revenue")}>
                {tTables("revenue7d")} {getSortIcon("revenue")}
              </th>
              <th className="text-[#fbe6dc] cursor-pointer hover:text-white" onClick={() => handleSort("users")}>
                {tTables("users")} {getSortIcon("users")}
              </th>
              <th className="text-[#fbe6dc] cursor-pointer hover:text-white" onClick={() => handleSort("sharpe")}>
                {t("sharpeRatio")} {getSortIcon("sharpe")}
              </th>
              <th className="text-[#fbe6dc]">{tTables("status")}</th>
            </tr>
          </thead>
          <tbody>
            {sortedVaults.map((entry, index) => {
              const tvlValue = Number.isFinite(entry.tvlUsd) ? entry.tvlUsd : 0;
              const revenueValue = Number.isFinite(entry.sevenDayRevenueUsd) ? entry.sevenDayRevenueUsd : 0;
              const apyValue = Number.isFinite(entry.apy) ? entry.apy : 0;
              const sharpeValue = entry.sharpeRatio ?? 0;

              return (
                <tr
                  key={entry.vault.id}
                  className="analytics-ranking-item border-b border-[#803100]/30 hover:bg-[#803100]/10 transition-colors"
                >
                  <td>
                    <div className="text-2xl font-bold text-[#803100]">
                      {index === 0 ? "#1 🥇" : index === 1 ? "#2 🥈" : index === 2 ? "#3 🥉" : `#${index + 1}`}
                    </div>
                  </td>
                  <td className="font-semibold text-white">{entry.vault.name}</td>
                  <td className="text-white">${formatNumber(tvlValue)}</td>
                  <td className="font-semibold text-[#fbe6dc]">{apyValue.toFixed(2)}%</td>
                  <td className="text-green-400">+${formatNumber(revenueValue)}</td>
                  <td className="text-white">{entry.userCount}</td>
                  <td className="text-[#fbe6dc]">{sharpeValue > 0 ? sharpeValue.toFixed(2) : "-"}</td>
                  <td>
                    <span
                      className={`badge ${entry.vault.isActive ? "bg-green-900/60 border-green-500/30 text-white" : "bg-yellow-900/60 border-yellow-500/30 text-white"}`}
                    >
                      {entry.vault.isActive ? tStatus("active") : tStatus("inactive")}
                    </span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("totalVaults")}</div>
          <div className="text-2xl font-bold text-white mt-1">{vaults.length}</div>
        </div>
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("avgTVL")}</div>
          <div className="text-lg font-bold text-white mt-1">
            ${formatNumber(vaults.reduce((sum, v) => sum + (v.tvlUsd || 0), 0) / vaults.length)}
          </div>
        </div>
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("avgAPY")}</div>
          <div className="text-lg font-bold text-green-400 mt-1">
            {(vaults.reduce((sum, v) => sum + (v.apy || 0), 0) / vaults.length).toFixed(2)}%
          </div>
        </div>
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("total7dRevenue")}</div>
          <div className="text-lg font-bold text-green-400 mt-1">
            +${formatNumber(vaults.reduce((sum, v) => sum + (v.sevenDayRevenueUsd || 0), 0))}
          </div>
        </div>
      </div>
    </div>
  );
};
