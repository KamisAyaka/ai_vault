"use client";

import { useRef, useState } from "react";
import { useAccount } from "wagmi";
import { AdminVaultActions } from "~~/components/admin/AdminVaultActions";
import { VaultCreationForm } from "~~/components/admin/VaultCreationForm";
import { VaultStatsOverview } from "~~/components/vault/StatsCard";
import { VaultCard } from "~~/components/vault/VaultCard";
import { useGsapFadeReveal, useGsapHeroIntro, useGsapStaggerReveal } from "~~/hooks/useGsapAnimations";
import { useVaultStats } from "~~/hooks/useVaultStats";
import { useVaults } from "~~/hooks/useVaults";

const AdminVaultsPage = () => {
  const { address: connectedAddress } = useAccount();
  const [selectedVaultId, setSelectedVaultId] = useState<string | null>(null);

  // Fetch vaults data
  const { vaults, loading, error, refetch } = useVaults(100, 0, "createdAt", "desc");

  // Calculate stats
  const stats = useVaultStats(vaults);

  const selectedVault = vaults.find(v => v.id === selectedVaultId);

  const heroRef = useRef<HTMLDivElement | null>(null);
  const statsRef = useRef<HTMLDivElement | null>(null);
  const listRef = useRef<HTMLDivElement | null>(null);
  const actionsRef = useRef<HTMLDivElement | null>(null);

  useGsapHeroIntro(heroRef);
  useGsapStaggerReveal(statsRef, {
    selector: ".stat",
    deps: [stats.totalValueLockedUsd, stats.activeVaults, stats.totalUsers, stats.averageApy],
  });
  useGsapFadeReveal(listRef, ".admin-vault-card", [vaults.length]);
  useGsapFadeReveal(actionsRef, ".admin-action-card", [selectedVaultId]);

  const handleVaultActionSuccess = () => {
    refetch();
    setSelectedVaultId(null);
  };

  if (loading) {
    return (
      <div className="flex min-h-screen flex-1 items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <span className="loading loading-spinner loading-lg text-[#fbe6dc]" />
          <p className="text-lg text-[#fbe6dc]">Loading admin panel...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto flex-1 px-4 py-8">
        <div className="rounded-lg border border-[#803100]/30 bg-black/60 p-6 backdrop-blur-sm">
          <div className="flex items-center gap-4">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-6 w-6 shrink-0 stroke-current text-[#803100]"
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
            <span className="text-white">Error loading vaults: {error.message}</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="relative flex grow flex-col items-center">
      <div className="container mx-auto w-full px-4 py-8">
        {/* Header */}
        <div className="mb-8" ref={heroRef}>
          <h1 className="hero-heading text-4xl font-bold mb-2 text-white">
            <span className="bg-gradient-to-r from-[#fbe6dc] to-[#803100] bg-clip-text text-transparent">
              Vault Admin Panel
            </span>
          </h1>
          <p className="hero-subheading text-lg text-[#fbe6dc]">Create and manage AI Vault Protocol vaults</p>
        </div>

        {/* Stats Overview */}
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

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column: Vault Creation & Admin Actions */}
          <div className="lg:col-span-1 space-y-6">
            <VaultCreationForm />

            {/* Selected Vault Admin Actions */}
            {selectedVault && (
              <div ref={actionsRef}>
                <div className="admin-action-card">
                  <AdminVaultActions vault={selectedVault} onSuccess={handleVaultActionSuccess} />
                </div>
              </div>
            )}
          </div>

          {/* Right Column: Vaults List */}
          <div className="lg:col-span-2">
            <div className="mb-4 flex justify-between items-center">
              <h2 className="text-2xl font-bold text-white">Existing Vaults</h2>
              <button
                onClick={refetch}
                className="btn btn-sm bg-[#803100] hover:bg-[#803100]/80 border-none text-white"
              >
                Refresh
              </button>
            </div>

            {vaults.length === 0 ? (
              <div className="text-center py-16 bg-black/60 backdrop-blur-sm border border-[#803100]/30 rounded-lg shadow-xl">
                <h3 className="text-2xl font-bold mb-2 text-white">No Vaults Yet</h3>
                <p className="text-[#fbe6dc]">Create your first vault using the form on the left</p>
              </div>
            ) : (
              <div className="space-y-4" ref={listRef}>
                {vaults.map(vault => (
                  <div
                    key={vault.id}
                    className={`admin-vault-card cursor-pointer transition-all rounded-lg ${
                      selectedVaultId === vault.id ? "ring-2 ring-[#803100] ring-offset-2 ring-offset-black" : ""
                    }`}
                    onClick={() => setSelectedVaultId(vault.id === selectedVaultId ? null : vault.id)}
                  >
                    <VaultCard vault={vault} userAddress={connectedAddress} />
                    {selectedVaultId === vault.id && (
                      <div className="bg-[#803100]/20 border-t border-[#803100]/30 px-4 py-2 text-sm font-semibold rounded-b-lg text-[#fbe6dc]">
                        Selected for management
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdminVaultsPage;
