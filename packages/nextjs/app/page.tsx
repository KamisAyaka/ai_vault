"use client";

import { useRef } from "react";
import Link from "next/link";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { CountUp } from "~~/components/ui/CountUp";
import { useGsapHeroIntro, useGsapStaggerReveal } from "~~/hooks/useGsapAnimations";
import { useUserRole } from "~~/hooks/useUserRole";
import { useVaultStats } from "~~/hooks/useVaultStats";
import { useVaults } from "~~/hooks/useVaults";
import { useTranslations } from "~~/services/i18n/I18nProvider";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const tHero = useTranslations("home.hero");
  const tMetrics = useTranslations("home.metrics");
  const { isOwner } = useUserRole();

  // Fetch top vaults
  const { vaults, loading } = useVaults(3, 0, "totalAssets", "desc");
  const stats = useVaultStats(vaults);

  const heroRef = useRef<HTMLDivElement | null>(null);
  const statsRef = useRef<HTMLDivElement | null>(null);

  const formatCurrency = (value?: number) => {
    if (!value || Number.isNaN(value)) return "$0.00";
    return `$${value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  const formatCount = (value?: number) => {
    if (!value || Number.isNaN(value)) return "0";
    return value.toLocaleString();
  };

  const formatPercentage = (value?: number) => {
    if (value === undefined || Number.isNaN(value)) return "0.0%";
    return `${value.toFixed(1)}%`;
  };

  useGsapHeroIntro(heroRef);
  useGsapStaggerReveal(statsRef, {
    selector: ".stats-line",
    from: { opacity: 0 },
    to: { opacity: 1, duration: 0.5, ease: "power2.out", stagger: 0.08 },
    deps: [loading, stats.totalValueLockedUsd, stats.activeVaults, stats.totalUsers, stats.averageApy],
  });

  return (
    <div className="relative flex grow flex-col items-center">
      {/* Hero Section */}
      <div className="hero flex-1 flex items-center justify-center relative" ref={heroRef}>
        <div className="hero-content text-center">
          <div className="max-w-4xl">
            <h1 className="hero-heading text-5xl md:text-7xl font-bold mb-6 text-white">
              <span className="bg-gradient-to-r from-[#fbe6dc] to-[#803100] bg-clip-text text-transparent">
                {tHero("tagline", "AI Vault Protocol")}
              </span>
            </h1>
            <p className="hero-subheading text-xl md:text-2xl mb-6 text-white">{tHero("title")}</p>
            <p className="hero-subheading text-lg mb-8 max-w-2xl mx-auto text-[#fbe6dc]">{tHero("subtitle")}</p>
            <div className="flex gap-4 justify-center flex-wrap">
              <Link
                href="/vaults"
                className="hero-cta btn bg-[#803100] hover:bg-[#803100]/80 border-none text-white btn-lg"
              >
                {tHero("explore")}
              </Link>
              {connectedAddress && isOwner && (
                <Link
                  href="/admin/vaults"
                  className="hero-cta btn bg-[#fbe6dc] hover:bg-[#fbe6dc]/80 border-none text-[#803100] btn-lg"
                >
                  {tHero("admin")}
                </Link>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Compact Stats Widget */}
      <div className="pointer-events-none fixed bottom-6 right-6 z-20 w-[min(90vw,500px)]" ref={statsRef}>
        <div className="pointer-events-auto rounded-xl border border-[#803100]/40 bg-black/70 px-4 py-3 backdrop-blur overflow-hidden">
          <div className="stats-line mb-2 text-xs uppercase tracking-[0.35em] text-[#fbe6dc]/60">
            {tMetrics("title", "Protocol Snapshot")}
          </div>
          {loading ? (
            <div className="flex items-center justify-center py-4">
              <span className="loading loading-spinner loading-sm text-[#fbe6dc]"></span>
              <span className="ml-2 text-xs text-[#fbe6dc]/80">{tMetrics("loading", "Loading...")}</span>
            </div>
          ) : (
            <div className="space-y-2 text-sm text-[#fbe6dc]">
              <div className="stats-line flex items-center justify-between overflow-hidden">
                <span className="whitespace-nowrap">{tMetrics("tvl", "Total Value Locked")}</span>
                <CountUp
                  className="font-semibold text-white whitespace-nowrap"
                  value={stats.totalValueLockedUsd}
                  format={formatCurrency}
                />
              </div>
              <div className="stats-line flex items-center justify-between overflow-hidden">
                <span className="whitespace-nowrap">{tMetrics("vaults", "Active Vaults")}</span>
                <CountUp
                  className="font-semibold text-white whitespace-nowrap"
                  value={stats.activeVaults}
                  format={formatCount}
                />
              </div>
              <div className="stats-line flex items-center justify-between overflow-hidden">
                <span className="whitespace-nowrap">{tMetrics("users", "Total Users")}</span>
                <CountUp
                  className="font-semibold text-white whitespace-nowrap"
                  value={stats.totalUsers}
                  format={formatCount}
                />
              </div>
              <div className="stats-line flex items-center justify-between overflow-hidden">
                <span className="whitespace-nowrap">{tMetrics("apy", "Average APY")}</span>
                <CountUp
                  className="font-semibold text-success whitespace-nowrap"
                  value={stats.averageApy}
                  format={formatPercentage}
                />
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Home;
