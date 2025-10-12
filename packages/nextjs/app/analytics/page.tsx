"use client";

import { useMemo, useRef } from "react";
import Link from "next/link";
import { useAnalyticsData } from "~~/hooks/useAnalyticsData";
import { useGsapFadeReveal, useGsapHeroIntro, useGsapStaggerReveal } from "~~/hooks/useGsapAnimations";
import { useTranslations } from "~~/services/i18n/I18nProvider";

const formatNumber = (value: number, maximumFractionDigits = 0) => {
  if (!Number.isFinite(value)) return "0";
  return value.toLocaleString(undefined, { maximumFractionDigits });
};

const AnalyticsPage = () => {
  const t = useTranslations("analytics");
  const tTables = useTranslations("common.tables");
  const tStatus = useTranslations("common.status");
  const tTime = useTranslations("common.timeRanges");
  const tActivity = useTranslations("common.activity");
  const tMenu = useTranslations("menu");
  const tAnalyticsPage = useTranslations("analyticsPage");

  const { loading, error, data } = useAnalyticsData();
  const { tvlHistory, assetDistribution, protocolDistribution, transactionTrends, recentActivity, stats } = data || {};

  const rankedVaults = data?.rankedVaults ?? [];

  const maxTvl = useMemo(() => {
    if (!tvlHistory || tvlHistory.length === 0) return 0;
    return Math.max(...tvlHistory.map(d => d.value));
  }, [tvlHistory]);

  const heroRef = useRef<HTMLDivElement | null>(null);
  const overviewRef = useRef<HTMLDivElement | null>(null);
  const distributionRef = useRef<HTMLDivElement | null>(null);
  const rankingRef = useRef<HTMLDivElement | null>(null);
  const activityRef = useRef<HTMLDivElement | null>(null);

  useGsapHeroIntro(heroRef, [loading]);
  useGsapStaggerReveal(overviewRef, {
    selector: ".analytics-overview-card",
    deps: [stats?.totalValueLockedUsd, stats?.totalVaults, stats?.totalUsers, stats?.averageApy],
  });
  useGsapFadeReveal(distributionRef, ".analytics-card", [
    assetDistribution?.length,
    protocolDistribution?.length,
    transactionTrends?.deposits?.length || 0,
    transactionTrends?.withdrawals?.length || 0,
  ]);
  useGsapFadeReveal(rankingRef, ".analytics-ranking-item", [rankedVaults.length]);
  useGsapFadeReveal(activityRef, ".analytics-activity-row", [recentActivity?.length || 0]);

  if (loading) {
    return (
      <div className="flex min-h-screen flex-1 items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <span className="loading loading-spinner loading-lg text-[#fbe6dc]" />
          <p className="text-lg text-white/80">{t("loading")}</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto flex-1 px-4 py-8">
        <div className="rounded-lg border border-red-500/30 bg-red-900/60 p-6 backdrop-blur-sm text-white">
          {t("error")}: {error.message}
        </div>
      </div>
    );
  }

  return (
    <div className="relative">
      <div className="container mx-auto px-4 py-8">
        <div className="flex justify-between items-center mb-8" ref={heroRef}>
          <div>
            <h1 className="hero-heading text-4xl font-bold mb-2 text-white">{t("title")}</h1>
            <div className="hero-subheading text-sm breadcrumbs">
              <ul>
                <li>
                  <Link href="/" className="text-[#fbe6dc] hover:text-white">
                    {tMenu("home")}
                  </Link>
                </li>
                <li className="text-white">{t("breadcrumbs.analytics")}</li>
              </ul>
            </div>
          </div>
          <div className="flex gap-2 hero-cta">
            <div className="badge bg-black/60 backdrop-blur-sm border-[#803100]/30 text-[#fbe6dc]">{tTime("7d")}</div>
            <div className="badge bg-black/60 backdrop-blur-sm border-[#803100]/30 text-[#fbe6dc]">{tTime("30d")}</div>
            <div className="badge bg-black/60 backdrop-blur-sm border-[#803100]/30 text-[#fbe6dc]">{tTime("90d")}</div>
            <div className="badge bg-[#803100] border-[#803100] text-white">{tTime("all")}</div>
          </div>
        </div>

        <div className="mb-8">
          <h2 className="text-2xl font-bold mb-4 text-white">{t("overview.title")}</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4" ref={overviewRef}>
            <div className="analytics-overview-card stat bg-black/60 backdrop-blur-sm shadow-lg rounded-lg border border-[#803100]/30">
              <div className="stat-title text-[#fbe6dc]">{t("overview.tvl")}</div>
              <div className="stat-value text-2xl text-white">
                ${stats ? (stats.totalValueLockedUsd / 1_000_000).toFixed(2) : "0.00"}M
              </div>
              <div className="stat-desc text-[#fbe6dc]">
                {tvlHistory && tvlHistory.length > 1 && tvlHistory[0].value > 0
                  ? `+${(((tvlHistory[tvlHistory.length - 1].value - tvlHistory[0].value) / tvlHistory[0].value) * 100).toFixed(1)}% (${tTime("7d")})`
                  : t("overview.pending")}
              </div>
            </div>
            <div className="analytics-overview-card stat bg-black/60 backdrop-blur-sm shadow-lg rounded-lg border border-[#803100]/30">
              <div className="stat-title text-[#fbe6dc]">{t("overview.vaults")}</div>
              <div className="stat-value text-2xl text-white">{stats?.totalVaults || 0}</div>
              <div className="stat-desc text-[#fbe6dc]">
                {t("overview.vaultsActive")}: {stats?.activeVaults || 0}
              </div>
            </div>
            <div className="analytics-overview-card stat bg-black/60 backdrop-blur-sm shadow-lg rounded-lg border border-[#803100]/30">
              <div className="stat-title text-[#fbe6dc]">{t("overview.users")}</div>
              <div className="stat-value text-2xl text-white">{stats?.totalUsers || 0}</div>
              <div className="stat-desc text-[#fbe6dc]">{tAnalyticsPage("activeUsers")}</div>
            </div>
            <div className="analytics-overview-card stat bg-black/60 backdrop-blur-sm shadow-lg rounded-lg border border-[#803100]/30">
              <div className="stat-title text-[#fbe6dc]">{t("overview.apy")}</div>
              <div className="stat-value text-2xl bg-gradient-to-r from-[#fbe6dc] to-[#803100] bg-clip-text text-transparent">
                {stats ? stats.averageApy.toFixed(1) : "0.0"}%
              </div>
              <div className="stat-desc text-[#fbe6dc]">{tAnalyticsPage("averageReturn")}</div>
            </div>
          </div>
        </div>

        <div className="mb-8">
          <h2 className="text-2xl font-bold mb-4 text-white">{t("charts.tvlTitle")}</h2>
          <div className="card bg-black/60 backdrop-blur-sm shadow-xl p-6 border border-[#803100]/30">
            <div className="h-64 relative">
              {!tvlHistory || tvlHistory.length === 0 ? (
                <div className="flex items-center justify-center h-full text opacity-70">
                  <div className="text-center">
                    <span className="loading loading-spinner loading-md text-[#fbe6dc]"></span>
                    <p className="mt-2 text-white">{t("charts.tvlLoading")}</p>
                  </div>
                </div>
              ) : (
                <div className="flex items-end justify-between h-full gap-2">
                  {tvlHistory.map((point, index) => {
                    const heightPercent = maxTvl > 0 ? (point.value / maxTvl) * 100 : 0;
                    const isToday = index === tvlHistory.length - 1;
                    return (
                      <div key={point.date} className="flex flex-col items-center flex-1 h-full justify-end">
                        <div
                          className={`rounded-t-lg w-full transition-all hover:opacity-80 cursor-pointer relative group ${
                            isToday ? "bg-[#803100]" : "bg-[#fbe6dc]"
                          }`}
                          style={{ height: `${Math.max(5, heightPercent)}%` }}
                        >
                          <div className="absolute bottom-full mb-2 hidden group-hover:block bg-black/80 backdrop-blur-sm text-xs px-2 py-1 rounded whitespace-nowrap left-1/2 -translate-x-1/2 z-10 border border-[#803100]/30">
                            <p className="font-semibold text-white">{point.date}</p>
                            <p className="text-[#fbe6dc]">{point.formatted}</p>
                          </div>
                        </div>
                        <p className="text-xs mt-2 opacity-70 text-[#fbe6dc]">{point.date.split(" ")[1]}</p>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
            <div className="divider before:bg-[#803100]/30 after:bg-[#803100]/30"></div>
            <div className="flex justify-center gap-4 text-sm">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-[#803100] rounded"></div>
                <span className="text-white">{t("overview.tvl")}</span>
              </div>
              {tvlHistory && tvlHistory.length > 0 && (
                <div className="text-sm opacity-70 text-[#fbe6dc]">
                  {t("charts.totals.current")}: {tvlHistory[tvlHistory.length - 1].formatted}
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8" ref={distributionRef}>
          <div className="analytics-card">
            <h2 className="text-2xl font-bold mb-4 text-white">{t("charts.assetsTitle")}</h2>
            <div className="card bg-black/60 backdrop-blur-sm shadow-xl p-6 border border-[#803100]/30">
              {!assetDistribution || assetDistribution.length === 0 ? (
                <div className="text-center opacity-70 py-8">
                  <span className="loading loading-spinner loading-md text-[#fbe6dc]"></span>
                  <p className="mt-2 text-white">{t("charts.assetsLoading")}</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {assetDistribution.map(asset => (
                    <div key={asset.symbol}>
                      <div className="flex justify-between mb-2">
                        <span className="font-semibold text-white">{asset.symbol}</span>
                        <span className="font-semibold text-[#fbe6dc]">
                          {asset.percentage.toFixed(1)}% ({asset.formattedValue})
                        </span>
                      </div>
                      <progress
                        className="progress bg-black/40 [&::-webkit-progress-value]:bg-gradient-to-r [&::-webkit-progress-value]:from-[#fbe6dc] [&::-webkit-progress-value]:to-[#803100] w-full"
                        value={asset.percentage}
                        max="100"
                      ></progress>
                      <div className="text-xs opacity-70 mt-1 text-[#fbe6dc]">
                        {asset.formattedAssetValue} {asset.symbol}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div className="analytics-card">
            <h2 className="text-2xl font-bold mb-4 text-white">{t("charts.protocolTitle")}</h2>
            <div className="card bg-black/60 backdrop-blur-sm shadow-xl p-6 border border-[#803100]/30">
              {!protocolDistribution || protocolDistribution.length === 0 ? (
                <div className="text-center opacity-70 py-8">
                  <span className="loading loading-spinner loading-md text-[#fbe6dc]"></span>
                  <p className="mt-2 text-white">{t("charts.protocolLoading")}</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {protocolDistribution.map((protocol, index) => {
                    const progressOpacity = index === 0 ? "80" : index === 1 ? "60" : index === 2 ? "40" : "20";
                    return (
                      <div key={protocol.name}>
                        <div className="flex justify-between mb-2">
                          <span className="font-semibold text-white">{protocol.name}</span>
                          <span className="font-semibold text-[#fbe6dc]">
                            {protocol.percentage.toFixed(1)}% ({protocol.formattedValue})
                          </span>
                        </div>
                        <progress
                          className={`progress bg-black/40 w-full`}
                          value={protocol.percentage}
                          max="100"
                          style={{
                            ["--progress-color" as string]: `rgba(128, 49, 0, 0.${progressOpacity})`,
                          }}
                        ></progress>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="mb-8">
          <h2 className="text-2xl font-bold mb-4 text-white">{t("ranking.title")}</h2>
          <div
            className="card bg-black/60 backdrop-blur-sm shadow-xl overflow-x-auto border border-[#803100]/30"
            ref={rankingRef}
          >
            <table className="table">
              <thead>
                <tr className="border-b border-[#803100]/30">
                  <th className="text-[#fbe6dc]">{tTables("rank")}</th>
                  <th className="text-[#fbe6dc]">{tTables("vault")}</th>
                  <th className="text-[#fbe6dc]">{tTables("tvl")}</th>
                  <th className="text-[#fbe6dc]">{tTables("apy")}</th>
                  <th className="text-[#fbe6dc]">{tTables("revenue7d")}</th>
                  <th className="text-[#fbe6dc]">{tTables("users")}</th>
                  <th className="text-[#fbe6dc]">{tTables("status")}</th>
                </tr>
              </thead>
              <tbody>
                {rankedVaults.map((entry, index) => {
                  const tvlValue = Number.isFinite(entry.tvlUsd) ? entry.tvlUsd : 0;
                  const revenueValue = Number.isFinite(entry.sevenDayRevenueUsd) ? entry.sevenDayRevenueUsd : 0;
                  const apyValue = Number.isFinite(entry.apy) ? entry.apy : 0;
                  return (
                    <tr
                      key={entry.vault.id}
                      className="analytics-ranking-item border-b border-[#803100]/30 hover:bg-[#803100]/10"
                    >
                      <td>
                        <div className="text-2xl font-bold text-[#803100]">
                          {index === 0 ? "#1" : index === 1 ? "#2" : index === 2 ? "#3" : `#${index + 1}`}
                        </div>
                      </td>
                      <td className="font-semibold text-white">{entry.vault.name}</td>
                      <td className="text-white">${formatNumber(tvlValue)}</td>
                      <td className="font-semibold text-[#fbe6dc]">{apyValue.toFixed(2)}%</td>
                      <td className="text-[#fbe6dc]">+${formatNumber(revenueValue)}</td>
                      <td className="text-white">{entry.userCount}</td>
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
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <div className="analytics-card">
            <h2 className="text-2xl font-bold mb-4 text-white">{t("charts.depositsTitle")}</h2>
            <div className="card bg-black/60 backdrop-blur-sm shadow-xl p-6 border border-[#803100]/30">
              {!transactionTrends?.deposits || transactionTrends.deposits.length === 0 ? (
                <div className="text-center opacity-70 py-8">
                  <span className="loading loading-spinner loading-md text-[#fbe6dc]"></span>
                  <p className="mt-2 text-white">{t("charts.tvlLoading")}</p>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="grid grid-cols-3 gap-4">
                    <div>
                      <p className="text-sm opacity-70 text-[#fbe6dc]">{t("charts.totals.deposits")}</p>
                      <p className="text-2xl font-bold text-white">
                        ${formatNumber(transactionTrends.deposits.reduce((sum, day) => sum + day.deposits, 0))}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm opacity-70 text-[#fbe6dc]">{t("charts.totals.count")}</p>
                      <p className="text-2xl font-bold text-white">
                        {transactionTrends.deposits.reduce((sum, day) => sum + day.depositCount, 0)}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm opacity-70 text-[#fbe6dc]">{t("charts.totals.average")}</p>
                      <p className="text-2xl font-bold text-white">
                        $
                        {formatNumber(
                          transactionTrends.deposits.reduce((sum, day) => sum + day.deposits, 0) /
                            Math.max(
                              1,
                              transactionTrends.deposits.reduce((sum, day) => sum + day.depositCount, 0),
                            ),
                        )}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-end gap-2 h-32">
                    {transactionTrends.deposits.map(day => (
                      <div
                        key={day.date}
                        className="bg-gradient-to-t from-[#803100] to-[#fbe6dc] flex-1 rounded-t transition-all hover:opacity-80 relative group cursor-pointer"
                        style={{ height: `${day.depositsHeight}%` }}
                      >
                        <div className="absolute bottom-full mb-2 hidden group-hover:block bg-black/80 backdrop-blur-sm text-xs px-2 py-1 rounded whitespace-nowrap left-1/2 -translate-x-1/2 border border-[#803100]/30">
                          <p className="text-white">{day.date}</p>
                          <p className="text-[#fbe6dc]">{day.formattedDeposits}</p>
                          <p className="text-[#fbe6dc]">
                            {day.depositCount} {t("charts.totals.count")}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                  <div className="flex justify-between text-xs opacity-70">
                    {transactionTrends.deposits.map(day => (
                      <span key={day.date} className="text-[#fbe6dc]">
                        {day.date}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          <div className="analytics-card">
            <h2 className="text-2xl font-bold mb-4 text-white">{t("charts.withdrawalsTitle")}</h2>
            <div className="card bg-black/60 backdrop-blur-sm shadow-xl p-6 border border-[#803100]/30">
              {!transactionTrends?.withdrawals || transactionTrends.withdrawals.length === 0 ? (
                <div className="text-center opacity-70 py-8">
                  <span className="loading loading-spinner loading-md text-[#fbe6dc]"></span>
                  <p className="mt-2 text-white">{t("charts.tvlLoading")}</p>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="grid grid-cols-3 gap-4">
                    <div>
                      <p className="text-sm opacity-70 text-[#fbe6dc]">{t("charts.totals.withdrawals")}</p>
                      <p className="text-2xl font-bold text-white">
                        ${formatNumber(transactionTrends.withdrawals.reduce((sum, day) => sum + day.withdrawals, 0))}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm opacity-70 text-[#fbe6dc]">{t("charts.totals.count")}</p>
                      <p className="text-2xl font-bold text-white">
                        {transactionTrends.withdrawals.reduce((sum, day) => sum + day.withdrawalCount, 0)}
                      </p>
                    </div>
                    <div>
                      <p className="text-sm opacity-70 text-[#fbe6dc]">{t("charts.totals.average")}</p>
                      <p className="text-2xl font-bold text-white">
                        $
                        {formatNumber(
                          transactionTrends.withdrawals.reduce((sum, day) => sum + day.withdrawals, 0) /
                            Math.max(
                              1,
                              transactionTrends.withdrawals.reduce((sum, day) => sum + day.withdrawalCount, 0),
                            ),
                        )}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-end gap-2 h-32">
                    {transactionTrends.withdrawals.map(day => (
                      <div
                        key={day.date}
                        className="bg-red-900/60 flex-1 rounded-t transition-all hover:opacity-80 relative group cursor-pointer"
                        style={{ height: `${day.withdrawalsHeight}%` }}
                      >
                        <div className="absolute bottom-full mb-2 hidden group-hover:block bg-black/80 backdrop-blur-sm text-xs px-2 py-1 rounded whitespace-nowrap left-1/2 -translate-x-1/2 border border-[#803100]/30">
                          <p className="text-white">{day.date}</p>
                          <p className="text-[#fbe6dc]">{day.formattedWithdrawals}</p>
                          <p className="text-[#fbe6dc]">
                            {day.withdrawalCount} {t("charts.totals.count")}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                  <div className="flex justify-between text-xs opacity-70">
                    {transactionTrends.withdrawals.map(day => (
                      <span key={day.date} className="text-[#fbe6dc]">
                        {day.date}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="mb-8">
          <h2 className="text-2xl font-bold mb-4 text-white">{t("activity.title")}</h2>
          <div
            className="card bg-black/60 backdrop-blur-sm shadow-xl overflow-x-auto border border-[#803100]/30"
            ref={activityRef}
          >
            <table className="table">
              <thead>
                <tr className="border-b border-[#803100]/30">
                  <th className="text-[#fbe6dc]">{tTables("time")}</th>
                  <th className="text-[#fbe6dc]">{tTables("type")}</th>
                  <th className="text-[#fbe6dc]">{tTables("vault")}</th>
                  <th className="text-[#fbe6dc]">{tTables("amount")}</th>
                  <th className="text-[#fbe6dc]">{tTables("valueUsd")}</th>
                  <th className="text-[#fbe6dc]">{tTables("users")}</th>
                  <th className="text-[#fbe6dc]">{tTables("transaction")}</th>
                </tr>
              </thead>
              <tbody>
                {!recentActivity || recentActivity.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="text-center opacity-70 py-8">
                      <span className="loading loading-spinner loading-sm text-[#fbe6dc]"></span>
                      <p className="mt-2 text-white">{t("activity.loading")}</p>
                    </td>
                  </tr>
                ) : (
                  recentActivity.map(activity => (
                    <tr
                      key={activity.id}
                      className="analytics-activity-row border-b border-[#803100]/30 hover:bg-[#803100]/10"
                    >
                      <td className="opacity-70 text-[#fbe6dc]">{activity.timeAgo}</td>
                      <td>
                        <span
                          className={`badge ${activity.type === "deposit" ? "bg-green-900/60 border-green-500/30" : "bg-red-900/60 border-red-500/30"} text-white`}
                        >
                          {activity.type === "deposit" ? tActivity("deposit") : tActivity("withdraw")}
                        </span>
                      </td>
                      <td className="font-semibold text-white">{activity.vault}</td>
                      <td className={activity.type === "deposit" ? "text-[#fbe6dc]" : "text-red-300"}>
                        {activity.amount}
                      </td>
                      <td className={activity.type === "deposit" ? "text-[#fbe6dc]" : "text-red-300"}>
                        {activity.usdValue}
                      </td>
                      <td>
                        <code className="text-xs text-[#fbe6dc]">
                          {activity.user.slice(0, 8)}...{activity.user.slice(-6)}
                        </code>
                      </td>
                      <td>
                        {activity.transactionHash ? (
                          <a
                            href={`https://etherscan.io/tx/${activity.transactionHash}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-xs text-[#803100] hover:text-[#fbe6dc] underline"
                          >
                            {activity.transactionHash.slice(0, 8)}...
                          </a>
                        ) : (
                          <span className="text-white">-</span>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AnalyticsPage;
