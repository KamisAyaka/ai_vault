"use client";

import { useRef, useState } from "react";
import { useAccount } from "wagmi";
import { VaultStatsOverview } from "~~/components/vault/StatsCard";
import { VaultCard } from "~~/components/vault/VaultCard";
import { useGsapHeroIntro, useGsapStaggerReveal } from "~~/hooks/useGsapAnimations";
import { useVaultStats } from "~~/hooks/useVaultStats";
import { useVaults } from "~~/hooks/useVaults";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import { notification } from "~~/utils/scaffold-eth";

const VaultsPage = () => {
  const { address: connectedAddress } = useAccount();
  const tVaults = useTranslations("vaults");
  const tNotices = useTranslations("common.notices");

  const [searchTerm, setSearchTerm] = useState("");
  const [filterAsset, setFilterAsset] = useState<string>("all");

  const { vaults, loading, error, refetch } = useVaults(100, 0, "totalAssets", "desc");
  const stats = useVaultStats(vaults);

  const heroRef = useRef<HTMLDivElement | null>(null);
  const statsRef = useRef<HTMLDivElement | null>(null);
  const listRef = useRef<HTMLDivElement | null>(null);

  const filteredVaults = vaults.filter(vault => {
    const matchesSearch =
      vault.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      vault.address.toLowerCase().includes(searchTerm.toLowerCase()) ||
      vault.asset?.symbol?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesAsset = filterAsset === "all" || vault.asset?.symbol?.toLowerCase() === filterAsset.toLowerCase();

    return matchesSearch && matchesAsset;
  });

  const handleTransactionSuccess = () => {
    refetch();
    notification.success(tNotices("transactionSuccess", "Transaction completed successfully!"));
  };

  useGsapHeroIntro(heroRef, [loading]);
  useGsapStaggerReveal(statsRef, {
    selector: ".stat",
    deps: [stats.totalValueLockedUsd, stats.activeVaults, stats.totalUsers, stats.averageApy],
  });
  useGsapStaggerReveal(listRef, {
    selector: ".vault-card-animate",
    deps: [filteredVaults.length],
  });

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="flex flex-col items-center gap-4">
          <span className="loading loading-spinner loading-lg text-[#fbe6dc]"></span>
          <p className="text-lg text-white">{tVaults("loading")}</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="alert alert-error">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="stroke-current shrink-0 h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth="2"
              d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <span>
            {tVaults("errors.load")}: {error.message}
          </span>
        </div>
      </div>
    );
  }

  return (
    <div className="relative flex grow flex-col items-center">
      <div className="relative container mx-auto px-4 py-8">
        <div className="text-center mb-8" ref={heroRef}>
          <h1 className="hero-heading text-4xl md:text-5xl font-bold mb-3 text-white">{tVaults("title")}</h1>
          <p className="hero-subheading text-lg text-white">{tVaults("subtitle")}</p>
        </div>

        <div className="mb-8" ref={statsRef}>
          <VaultStatsOverview
            totalVaults={stats.totalVaults}
            activeVaults={stats.activeVaults}
            totalValueLockedUsd={stats.totalValueLockedUsd}
            totalValueLockedBreakdown={stats.totalValueLockedBreakdown}
            averageApy={stats.averageApy}
            totalUsers={stats.totalUsers}
          />
        </div>

        <div className="bg-black/60 backdrop-blur-sm p-4 rounded-lg shadow-lg mb-8 border border-[#803100]/30">
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1">
              <div className="join w-full">
                <span className="btn btn-square join-item bg-[#803100]/20 border-[#803100]/30">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5 text-white"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth="2"
                      d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                    />
                  </svg>
                </span>
                <input
                  type="text"
                  placeholder={tVaults("search")}
                  className="input input-bordered join-item w-full bg-black/40 border-[#803100]/30 text-white placeholder-[#fbe6dc]/50"
                  value={searchTerm}
                  onChange={e => setSearchTerm(e.target.value)}
                />
              </div>
            </div>

            <div className="flex gap-2 flex-wrap">
              <button
                className={`btn btn-sm ${filterAsset === "all" ? "bg-[#803100] hover:bg-[#803100]/80 border-none text-white" : "bg-black/40 border-[#803100]/30 text-[#fbe6dc] hover:bg-[#803100]/20"}`}
                onClick={() => setFilterAsset("all")}
              >
                {tVaults("filters.all")}
              </button>
              <button
                className={`btn btn-sm ${filterAsset === "usdc" ? "bg-[#803100] hover:bg-[#803100]/80 border-none text-white" : "bg-black/40 border-[#803100]/30 text-[#fbe6dc] hover:bg-[#803100]/20"}`}
                onClick={() => setFilterAsset("usdc")}
              >
                {tVaults("filters.usdc")}
              </button>
              <button
                className={`btn btn-sm ${filterAsset === "weth" ? "bg-[#803100] hover:bg-[#803100]/80 border-none text-white" : "bg-black/40 border-[#803100]/30 text-[#fbe6dc] hover:bg-[#803100]/20"}`}
                onClick={() => setFilterAsset("weth")}
              >
                {tVaults("filters.weth")}
              </button>
              <button
                className={`btn btn-sm ${filterAsset === "dai" ? "bg-[#803100] hover:bg-[#803100]/80 border-none text-white" : "bg-black/40 border-[#803100]/30 text-[#fbe6dc] hover:bg-[#803100]/20"}`}
                onClick={() => setFilterAsset("dai")}
              >
                {tVaults("filters.dai")}
              </button>
            </div>
          </div>
        </div>

        {filteredVaults.length === 0 ? (
          <div className="text-center py-16">
            <h3 className="text-2xl font-bold mb-2 text-white">{tVaults("empty.title")}</h3>
            <p className="text-[#fbe6dc]">
              {searchTerm || filterAsset !== "all" ? tVaults("empty.hintFiltered") : tVaults("empty.hintEmpty")}
            </p>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8" ref={listRef}>
              {filteredVaults.map(vault => (
                <div key={vault.id} className="vault-card-animate">
                  <VaultCard vault={vault} userAddress={connectedAddress} onSuccess={handleTransactionSuccess} />
                </div>
              ))}
            </div>

            <div className="text-center text-[#fbe6dc]">
              <p>
                {filteredVaults.length} / {vaults.length}
              </p>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default VaultsPage;
