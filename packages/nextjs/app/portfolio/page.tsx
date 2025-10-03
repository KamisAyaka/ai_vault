"use client";

import { useMemo, useRef, useState } from "react";
import Link from "next/link";
import { usePortfolioData } from "~~/hooks/usePortfolioData";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import { useGsapFadeReveal, useGsapHeroIntro, useGsapStaggerReveal } from "~~/hooks/useGsapAnimations";

// Note: tActivity is used in transaction section but not imported
const tActivity = (key: string) => key;

const formatCurrency = (value: number, maximumFractionDigits = 0) => {
  if (!Number.isFinite(value)) return "0";
  return value.toLocaleString(undefined, { maximumFractionDigits });
};

const PortfolioPage = () => {
  const [selectedPeriod, setSelectedPeriod] = useState<"7d" | "30d" | "90d" | "all">("30d");

  const t = useTranslations("portfolio");
  const tTables = useTranslations("common.tables");

  const { loading, error, isConnected, data } = usePortfolioData();
  const { positions, stats, revenueHistory, feeBreakdown, transactionHistory } = data || {};

  const filteredRevenueHistory = useMemo(() => {
    if (!revenueHistory) return [];
    const days =
      selectedPeriod === "7d"
        ? 7
        : selectedPeriod === "30d"
          ? 30
          : selectedPeriod === "90d"
            ? 90
            : revenueHistory.length;
    return revenueHistory.slice(-days);
  }, [revenueHistory, selectedPeriod]);

  const heroRef = useRef<HTMLDivElement | null>(null);
  const statsRef = useRef<HTMLDivElement | null>(null);
  const revenueRef = useRef<HTMLDivElement | null>(null);
  const positionsRef = useRef<HTMLDivElement | null>(null);
  const feesRef = useRef<HTMLDivElement | null>(null);
  const activityRef = useRef<HTMLDivElement | null>(null);

  useGsapHeroIntro(heroRef, [loading]);
  useGsapStaggerReveal(statsRef, {
    selector: ".portfolio-stat-card",
    deps: [stats?.totalPortfolioValue ?? 0, stats?.totalProfitLoss ?? 0, stats?.totalFees ?? 0, stats?.totalPositions ?? 0],
  });
  useGsapFadeReveal(revenueRef, ".portfolio-section-card", [filteredRevenueHistory.length, selectedPeriod]);
  useGsapFadeReveal(positionsRef, ".portfolio-position-row", [positions?.length || 0]);
  useGsapFadeReveal(feesRef, ".portfolio-fee-row", [feeBreakdown?.length || 0]);
  useGsapFadeReveal(activityRef, ".portfolio-activity-row", [transactionHistory?.length || 0]);

  if (!isConnected) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="rounded-lg border border-[#803100]/30 bg-black/60 p-6 backdrop-blur-sm">
          <div className="flex items-center gap-4">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-6 w-6 shrink-0 stroke-current text-[#fbe6dc]"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <span className="text-[#fbe6dc]">{t("connectNotice")}</span>
          </div>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex min-h-screen flex-1 items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <span className="loading loading-spinner loading-lg text-[#fbe6dc]" />
          <p className="text-lg text-[#fbe6dc]">{t("loading")}</p>
        </div>
      </div>
    );
  }

  if (error || !stats) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="rounded-lg border border-[#803100]/30 bg-black/60 p-6 backdrop-blur-sm">
          <div className="flex items-center gap-4 text-[#fbe6dc]">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-6 w-6 shrink-0 stroke-current text-red-400"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>
              {t("error")}
              {error ? `: ${error.message}` : ""}
            </span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      <div className="container mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-8" ref={heroRef}>
          <div>
            <h1 className="hero-heading text-4xl font-bold mb-2 text-white">{t("title")}</h1>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8" ref={statsRef}>
        <div className="portfolio-stat-card card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30">
          <div className="card-body">
            <h3 className="text-sm text-[#fbe6dc]">{t("stats.totalValue")}</h3>
            <p className="text-3xl font-bold text-white">${formatCurrency(stats.totalPortfolioValue)}</p>
            <div className="text-xs text-[#fbe6dc] mt-1">{stats.totalPositions}</div>
          </div>
        </div>
        <div className="portfolio-stat-card card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30">
          <div className="card-body">
            <h3 className="text-sm text-[#fbe6dc]">{t("stats.totalPnL")}</h3>
            <p className={`text-3xl font-bold ${stats.totalProfitLoss >= 0 ? "text-green-400" : "text-red-400"}`}>
              {stats.totalProfitLoss >= 0 ? "+" : ""}${formatCurrency(stats.totalProfitLoss)}
            </p>
            <p className={`${stats.totalProfitLoss >= 0 ? "text-green-400" : "text-red-400"}`}>
              {stats.totalProfitLoss >= 0 ? "+" : ""}{stats.totalProfitLossPercent.toFixed(2)}%
            </p>
          </div>
        </div>
        <div className="portfolio-stat-card card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30">
          <div className="card-body">
            <h3 className="text-sm text-[#fbe6dc]">{t("stats.totalFees")}</h3>
            <p className="text-3xl font-bold text-white">${formatCurrency(stats.totalFees)}</p>
          </div>
        </div>
        <div className="portfolio-stat-card card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30">
          <div className="card-body">
            <h3 className="text-sm text-[#fbe6dc]">{t("stats.vaultCount")}</h3>
            <p className="text-3xl font-bold text-white">{stats.totalPositions}</p>
          </div>
        </div>
      </div>

      <div className="portfolio-section-card card bg-black/60 backdrop-blur-sm shadow-xl mb-8 border border-[#803100]/30" ref={revenueRef}>
        <div className="card-body">
          <div className="flex justify-between items-center mb-4">
            <h2 className="card-title text-white">{t("revenue.title")}</h2>
            <div className="btn-group">
              <button className={`btn btn-sm ${selectedPeriod === "7d" ? "bg-[#803100] text-white" : "bg-black/60 text-[#fbe6dc] border-[#803100]/30"}`} onClick={() => setSelectedPeriod("7d")}>
                {t("revenue.period.7d")}
              </button>
              <button className={`btn btn-sm ${selectedPeriod === "30d" ? "bg-[#803100] text-white" : "bg-black/60 text-[#fbe6dc] border-[#803100]/30"}`} onClick={() => setSelectedPeriod("30d")}>
                {t("revenue.period.30d")}
              </button>
              <button className={`btn btn-sm ${selectedPeriod === "90d" ? "bg-[#803100] text-white" : "bg-black/60 text-[#fbe6dc] border-[#803100]/30"}`} onClick={() => setSelectedPeriod("90d")}>
                {t("revenue.period.90d")}
              </button>
              <button className={`btn btn-sm ${selectedPeriod === "all" ? "bg-[#803100] text-white" : "bg-black/60 text-[#fbe6dc] border-[#803100]/30"}`} onClick={() => setSelectedPeriod("all")}>
                {t("revenue.period.all")}
              </button>
            </div>
          </div>

          {!filteredRevenueHistory || filteredRevenueHistory.length === 0 ? (
            <div className="flex items-center justify-center h-64 text-[#fbe6dc]">
              <div className="text-center">
                <span className="loading loading-spinner loading-md text-[#fbe6dc]"></span>
                <p className="mt-2">{t("revenue.loading")}</p>
              </div>
            </div>
          ) : (
            <div className="h-64 flex items-end justify-between gap-1">
              {filteredRevenueHistory.map((point, index) => {
                const maxValue = Math.max(...filteredRevenueHistory.map(item => item.value));
                const height = maxValue > 0 ? (point.value / maxValue) * 100 : 0;
                const isLatest = index === filteredRevenueHistory.length - 1;
                return (
                  <div key={point.timestamp} className="flex flex-col items-center flex-1 group relative">
                    <div
                      className={`w-full ${isLatest ? "bg-[#803100]" : "bg-[#fbe6dc]"} rounded-t transition-all hover:opacity-80`}
                      style={{ height: `${Math.max(5, height)}%` }}
                    ></div>
                    {index % 5 === 0 && <p className="text-xs mt-2 text-[#fbe6dc] rotate-45 origin-top-left">{point.date}</p>}
                    <div className="absolute bottom-full mb-2 hidden group-hover:block bg-black/80 text-xs p-2 rounded shadow-lg whitespace-nowrap z-10 border border-[#803100]/30">
                      <p className="font-semibold text-white">{point.date}</p>
                      <p className="text-[#fbe6dc]">{point.formatted}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      <div className="portfolio-section-card card bg-black/60 backdrop-blur-sm shadow-xl mb-8 border border-[#803100]/30" ref={positionsRef}>
        <div className="card-body">
          <h2 className="card-title mb-4 text-white">{t("positions.title")}</h2>

          {!positions || positions.length === 0 ? (
            <div className="text-center py-16">
              <h3 className="text-2xl font-bold mb-2 text-white">{t("positions.empty.title")}</h3>
              <p className="text-[#fbe6dc]">
                {t("positions.empty.description")}
                <Link href="/vaults" className="text-[#803100] hover:text-[#803100]/80 ml-1 underline">
                  {t("positions.empty.cta")}
                </Link>
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="table">
                <thead>
                  <tr className="border-b border-[#803100]/30">
                    <th className="text-[#fbe6dc]">{tTables("vault")}</th>
                    <th className="text-[#fbe6dc]">Asset</th>
                    <th className="text-[#fbe6dc]">{t("positions.table.value")}</th>
                    <th className="text-[#fbe6dc]">{t("positions.table.pnl")}</th>
                    <th className="text-[#fbe6dc]">{t("positions.table.shares")}</th>
                    <th className="text-[#fbe6dc]">{t("positions.table.days")}</th>
                    <th className="text-[#fbe6dc]">{tTables("transaction")}</th>
                  </tr>
                </thead>
                <tbody>
                  {positions.map(position => (
                    <tr key={position.vault.id} className="portfolio-position-row border-b border-[#803100]/30 hover:bg-[#803100]/10">
                      <td>
                        <Link href={`/vaults/${position.vault.id}`} className="font-semibold text-white hover:text-[#803100]">
                          {position.vault.name}
                        </Link>
                      </td>
                      <td>
                        <span className="badge bg-[#803100]/20 border-[#803100]/30 text-[#fbe6dc]">{position.assetSymbol}</span>
                      </td>
                      <td className="font-semibold text-white">${formatCurrency(position.valueUsd, 2)}</td>
                      <td>
                        <div className={position.profitLossUsd >= 0 ? "text-green-400" : "text-red-400"}>
                          <p className="font-semibold">
                            {position.profitLossUsd >= 0 ? "+" : ""}
                            {formatCurrency(position.profitLossUsd, 2)}
                          </p>
                          <p className="text-xs">
                            {position.profitLossPercent >= 0 ? "+" : ""}
                            {position.profitLossPercent.toFixed(2)}%
                          </p>
                        </div>
                      </td>
                      <td className="text-sm text-[#fbe6dc]">
                        {Number.isFinite(parseFloat(position.sharesFormatted))
                          ? `${parseFloat(position.sharesFormatted).toLocaleString(undefined, { maximumFractionDigits: 4 })} v${position.assetSymbol}`
                          : `${position.sharesFormatted} v${position.assetSymbol}`}
                      </td>
                      <td className="text-sm text-[#fbe6dc]">{Math.round(position.daysHeld)} {t("positions.table.days")}</td>
                      <td>
                        <Link href={`/vaults/${position.vault.id}`} className="btn btn-xs bg-[#803100] hover:bg-[#803100]/80 border-none text-white">
                          {t("positions.table.action")}
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {feeBreakdown && feeBreakdown.length > 0 && (
        <div className="portfolio-section-card card bg-black/60 backdrop-blur-sm shadow-xl mb-8 border border-[#803100]/30" ref={feesRef}>
          <div className="card-body">
            <h2 className="card-title mb-4 text-white">{t("fees.title")}</h2>
            <div className="overflow-x-auto">
              <table className="table table-sm">
                <thead>
                  <tr className="border-b border-[#803100]/30">
                    <th className="text-[#fbe6dc]">{tTables("vault")}</th>
                    <th className="text-[#fbe6dc]">{t("fees.management")}</th>
                    <th className="text-[#fbe6dc]">{t("fees.performance")}</th>
                    <th className="text-[#fbe6dc]">{t("fees.daysHeld")}</th>
                    <th className="text-[#fbe6dc]">{t("fees.total")}</th>
                  </tr>
                </thead>
                <tbody>
                  {feeBreakdown.map(row => (
                    <tr key={row.vaultAddress} className="portfolio-fee-row border-b border-[#803100]/30 hover:bg-[#803100]/10">
                      <td className="font-semibold text-white">{row.vaultName}</td>
                      <td className="text-[#fbe6dc]">${formatCurrency(row.managementFee, 2)}</td>
                      <td className="text-[#fbe6dc]">${formatCurrency(row.performanceFee, 2)}</td>
                      <td className="text-sm text-[#fbe6dc]">{row.daysHeld}</td>
                      <td className="font-semibold text-white">${formatCurrency(row.totalFee, 2)}</td>
                    </tr>
                  ))}
                  <tr className="font-bold border-t-2 border-[#803100]/30">
                    <td className="text-white">{tTables("total", "Total")}</td>
                    <td className="text-[#fbe6dc]">${formatCurrency(feeBreakdown.reduce((sum, row) => sum + row.managementFee, 0), 2)}</td>
                    <td className="text-[#fbe6dc]">${formatCurrency(feeBreakdown.reduce((sum, row) => sum + row.performanceFee, 0), 2)}</td>
                    <td className="text-[#fbe6dc]">-</td>
                    <td className="text-white">${formatCurrency(stats.totalFees, 2)}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {transactionHistory && transactionHistory.length > 0 && (
        <div className="portfolio-section-card card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30" ref={activityRef}>
          <div className="card-body">
            <h2 className="card-title mb-4 text-white">{t("transactions.title")}</h2>
            <div className="overflow-x-auto">
              <table className="table table-sm">
                <thead>
                  <tr className="border-b border-[#803100]/30">
                    <th className="text-[#fbe6dc]">{tTables("time")}</th>
                    <th className="text-[#fbe6dc]">{tTables("type")}</th>
                    <th className="text-[#fbe6dc]">{tTables("vault")}</th>
                    <th className="text-[#fbe6dc]">{tTables("amount")}</th>
                    <th className="text-[#fbe6dc]">{tTables("shares")}</th>
                    <th className="text-[#fbe6dc]">{tTables("valueUsd")}</th>
                    <th className="text-[#fbe6dc]">{tTables("transaction")}</th>
                  </tr>
                </thead>
                <tbody>
                  {transactionHistory.map(tx => (
                    <tr key={tx.id} className="portfolio-activity-row border-b border-[#803100]/30 hover:bg-[#803100]/10">
                      <td className="text-xs text-[#fbe6dc]">{new Date(tx.timestamp).toLocaleString("zh-CN")}</td>
                      <td>
                        <span className={`badge badge-sm ${tx.type === "deposit" ? "bg-green-400/20 border-green-400/30 text-green-400" : "bg-red-400/20 border-red-400/30 text-red-400"}`}>
                          {tx.type === "deposit" ? tActivity("deposit") : tActivity("withdraw")}
                        </span>
                      </td>
                      <td className="text-sm">
                        <Link href={`/vaults/${tx.vault.id}`} className="text-white hover:text-[#803100]">
                          {tx.vault.name}
                        </Link>
                      </td>
                      <td className="font-mono text-sm text-[#fbe6dc]">{tx.amount}</td>
                      <td className="font-mono text-sm text-[#fbe6dc]">{tx.shares}</td>
                      <td className={tx.type === "deposit" ? "text-green-400" : "text-red-400"}>{tx.amountUsd}</td>
                      <td>
                        {tx.transactionHash ? (
                          <a
                            href={`https://etherscan.io/tx/${tx.transactionHash}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-xs text-[#803100] hover:text-[#803100]/80"
                          >
                            {tx.transactionHash.slice(0, 8)}...
                          </a>
                        ) : (
                          <span className="text-[#fbe6dc]">-</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
    </>
  );
};

export default PortfolioPage;
