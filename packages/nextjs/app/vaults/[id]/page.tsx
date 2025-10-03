"use client";

import Link from "next/link";
import { useMemo, useRef, useState } from "react";
import { useParams } from "next/navigation";
import { formatUnits } from "viem";
import { useAccount } from "wagmi";
import { VaultReactivationModal } from "~~/components/admin/VaultReactivationModal";
import { RoleDisplay } from "~~/components/auth/RoleDisplay";
import { Address } from "~~/components/scaffold-eth";
import {
  DepositETHModal,
  DepositModal,
  MintETHModal,
  MintModal,
  WithdrawETHModal,
  WithdrawModal,
} from "~~/components/vault";
import { useVaultPerformance } from "~~/hooks/useVaultPerformance";
import { useUserRole } from "~~/hooks/useUserRole";
import { useVaults } from "~~/hooks/useVaults";
import { useGsapFadeReveal, useGsapHeroIntro } from "~~/hooks/useGsapAnimations";

const safeBigInt = (value?: string) => {
  try {
    return BigInt(value || "0");
  } catch {
    return 0n;
  }
};

const formatTokenAmount = (amount: bigint, decimals: number, fractionDigits = 2) => {
  try {
    const normalized = Number(formatUnits(amount, decimals));
    if (!Number.isFinite(normalized)) return "0";
    return normalized.toLocaleString(undefined, { maximumFractionDigits: fractionDigits });
  } catch {
    return "0";
  }
};

const formatPercent = (value?: number, fractionDigits = 1) => {
  if (!Number.isFinite(value ?? NaN)) return "0.0%";
  return `${value!.toFixed(fractionDigits)}%`;
};

const VaultDetailPage = () => {
  const params = useParams<{ id: string }>();
  const vaultParam = (params?.id ?? "").toLowerCase();
  const { address: connectedAddress } = useAccount();
  const { vaults, loading, error, refetch } = useVaults(200);
  const { data: performanceData } = useVaultPerformance(200);

  const [isDepositModalOpen, setIsDepositModalOpen] = useState(false);
  const [isWithdrawModalOpen, setIsWithdrawModalOpen] = useState(false);
  const [isMintModalOpen, setIsMintModalOpen] = useState(false);
  const [isReactivationModalOpen, setIsReactivationModalOpen] = useState(false);

  const heroRef = useRef<HTMLDivElement | null>(null);
  const leftColumnRef = useRef<HTMLDivElement | null>(null);
  const rightColumnRef = useRef<HTMLDivElement | null>(null);
  const activityRef = useRef<HTMLDivElement | null>(null);
  const roleRef = useRef<HTMLDivElement | null>(null);

  const vault = useMemo(
    () =>
      vaults.find(
        v => v.id.toLowerCase() === vaultParam || v.address.toLowerCase() === vaultParam,
      ),
    [vaults, vaultParam],
  );

  const performance = useMemo(
    () => performanceData.find(p => p.vault.id === vault?.id),
    [performanceData, vault?.id],
  );

  const { permissions } = useUserRole(vault?.address, {
    managerAddress: vault?.manager?.owner ?? vault?.manager?.address ?? null,
  });

  useGsapHeroIntro(heroRef);
  useGsapFadeReveal(leftColumnRef, ".vault-detail-card", [vault?.id ?? "", connectedAddress ?? ""]);
  useGsapFadeReveal(rightColumnRef, ".vault-detail-card", [
    vault?.id ?? "",
    performance?.currentAPY ?? 0,
    vault?.allocations?.length ?? 0,
  ]);
  useGsapFadeReveal(activityRef, ".vault-activity-row", [vault?.deposits?.length ?? 0, vault?.redeems?.length ?? 0]);
  useGsapFadeReveal(roleRef, ".vault-role-card", [vault?.address ?? ""]);

  const assetSymbol = vault?.asset?.symbol?.toUpperCase() ?? "TOKEN";
  const assetDecimals = vault?.asset?.decimals ?? 18;
  const isETHVault = assetSymbol === "WETH" || assetSymbol === "ETH";

  const totalAssets = safeBigInt(vault?.totalAssets);
  const totalSupply = safeBigInt(vault?.totalSupply);

  const sharePrice = useMemo(() => {
    if (totalSupply === 0n) return "1.0000";
    try {
      const assets = Number(formatUnits(totalAssets, assetDecimals));
      const supply = Number(formatUnits(totalSupply, assetDecimals));
      if (!Number.isFinite(assets) || !Number.isFinite(supply) || supply === 0) return "1.0000";
      return (assets / supply).toFixed(4);
    } catch {
      return "1.0000";
    }
  }, [totalAssets, totalSupply, assetDecimals]);

  const uniqueHolders = useMemo(() => {
    const deposits = vault?.deposits ?? [];
    const holders = new Set(
      deposits.map(deposit => deposit.user?.address?.toLowerCase()).filter(Boolean) as string[],
    );
    return holders.size;
  }, [vault?.deposits]);

  const userStats = useMemo(() => {
    if (!connectedAddress) {
      return {
        shares: 0n,
        deposited: 0n,
        redeemed: 0n,
        value: 0n,
        profit: 0n,
        profitPercent: 0,
      };
    }

    const deposits = vault?.deposits ?? [];
    const redeems = vault?.redeems ?? [];

    const lower = connectedAddress.toLowerCase();
    const depositShares = deposits
      .filter(deposit => deposit.user?.address?.toLowerCase() === lower)
      .reduce((sum, deposit) => sum + safeBigInt(deposit.userShares), 0n);

    const redeemShares = redeems
      .filter(redeem => redeem.user?.address?.toLowerCase() === lower)
      .reduce((sum, redeem) => sum + safeBigInt(redeem.shares), 0n);

    const currentShares = depositShares - redeemShares;

    const totalDeposited = deposits
      .filter(deposit => deposit.user?.address?.toLowerCase() === lower)
      .reduce((sum, deposit) => sum + safeBigInt(deposit.assets), 0n);

    const totalRedeemed = redeems
      .filter(redeem => redeem.user?.address?.toLowerCase() === lower)
      .reduce((sum, redeem) => sum + safeBigInt(redeem.assets), 0n);

    const currentValue = totalSupply > 0n ? (totalAssets * currentShares) / totalSupply : 0n;
    const investedPrincipal = totalDeposited - totalRedeemed;
    const profit = currentValue - investedPrincipal;
    const profitPercent = Number(investedPrincipal > 0n ? (profit * 10000n) / investedPrincipal : 0n) / 100;

    return {
      shares: currentShares,
      deposited: totalDeposited,
      redeemed: totalRedeemed,
      value: currentValue,
      profit,
      profitPercent,
    };
  }, [connectedAddress, vault?.deposits, vault?.redeems, totalAssets, totalSupply]);

  const transactionRows = useMemo(() => {
    const deposits = vault?.deposits ?? [];
    const redeems = vault?.redeems ?? [];

    const mappedDeposits = deposits.map(deposit => ({
      type: "Deposit" as const,
      assets: safeBigInt(deposit.assets),
      shares: safeBigInt(deposit.userShares),
      timestamp: Number(deposit.blockTimestamp) * 1000,
      hash: deposit.transactionHash,
    }));
    const mappedRedeems = redeems.map(redeem => ({
      type: "Withdraw" as const,
      assets: safeBigInt(redeem.assets),
      shares: safeBigInt(redeem.shares),
      timestamp: Number(redeem.blockTimestamp) * 1000,
      hash: redeem.transactionHash,
    }));
    return [...mappedDeposits, ...mappedRedeems]
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice(0, 20);
  }, [vault?.deposits, vault?.redeems]);

  if (loading) {
    return (
      <div className="flex min-h-screen flex-1 items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <span className="loading loading-spinner loading-lg text-[#fbe6dc]" />
          <p className="text-lg text-[#fbe6dc]">Loading vault details...</p>
        </div>
      </div>
    );
  }

  if (error || !vault) {
    return (
      <div className="container mx-auto px-4 py-10">
        <div className="rounded-xl border border-[#803100]/30 bg-black/60 p-6 text-[#fbe6dc] backdrop-blur-sm">
          Unable to locate this vault. Please verify the URL or return to the vault list.
        </div>
      </div>
    );
  }
  return (
    <div className="container mx-auto px-4 py-10 text-[#fbe6dc]">
      <div className="mb-8 flex flex-col gap-4 md:flex-row md:items-start md:justify-between" ref={heroRef}>
        <div>
          <div className="hero-subheading text-sm breadcrumbs">
            <ul className="opacity-80">
              <li>
                <Link href="/" className="hover:text-white">
                  Home
                </Link>
              </li>
              <li>
                <Link href="/vaults" className="hover:text-white">
                  Vaults
                </Link>
              </li>
              <li className="text-white">{vault.name}</li>
            </ul>
          </div>
          <h1 className="hero-heading text-4xl font-bold text-white">
            {vault.name}
            <span
              className={`badge ml-3 border-none bg-[#803100] ${vault.isActive ? "" : "bg-red-700"}`}
            >
              {vault.isActive ? "Active" : "Inactive"}
            </span>
          </h1>
          <div className="mt-2 text-sm hero-subheading">
            <Address address={vault.address} size="sm" />
          </div>
        </div>
        {!vault.isActive && permissions.canActivateVault && (
          <button
            onClick={() => setIsReactivationModalOpen(true)}
            className="hero-cta btn btn-success"
          >
            Reactivate Vault
          </button>
        )}
      </div>

      <div className="grid gap-8 lg:grid-cols-3">
        <div className="space-y-6" ref={leftColumnRef}>
          <div className="vault-detail-card card bg-base-100 shadow-xl">
            <div className="card-body space-y-3">
              <h2 className="card-title text-white">Vault Metrics</h2>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="opacity-70">Total Assets</p>
                  <p className="text-lg font-semibold">
                    {formatTokenAmount(totalAssets, assetDecimals)} {assetSymbol}
                  </p>
                </div>
                <div>
                  <p className="opacity-70">Total Supply</p>
                  <p className="text-lg font-semibold">
                    {formatTokenAmount(totalSupply, assetDecimals)} v{assetSymbol}
                  </p>
                </div>
                <div>
                  <p className="opacity-70">Share Price</p>
                  <p className="text-lg font-semibold">{sharePrice}</p>
                </div>
                <div>
                  <p className="opacity-70">Holders</p>
                  <p className="text-lg font-semibold">{uniqueHolders}</p>
                </div>
              </div>
              <div className="divider my-3" />
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="opacity-70">Manager</p>
                  <Address address={vault.manager?.address} size="sm" />
                </div>
                <div>
                  <p className="opacity-70">Owner</p>
                  <Address address={vault.manager?.owner} size="sm" />
                </div>
                <div>
                  <p className="opacity-70">Created</p>
                  <p>{new Date(Number(vault.createdAt) * 1000).toLocaleDateString()}</p>
                </div>
                <div>
                  <p className="opacity-70">Updated</p>
                  <p>{new Date(Number(vault.updatedAt) * 1000).toLocaleDateString()}</p>
                </div>
              </div>
            </div>
          </div>

          {connectedAddress && (
            <div className="vault-detail-card card bg-base-100 shadow-xl">
              <div className="card-body space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="card-title text-white">Your Position</h2>
                  {userStats.shares > 0n && (
                    <span className="badge border-none bg-[#803100]/70 text-white">
                      {formatTokenAmount(userStats.shares, assetDecimals, 4)} shares
                    </span>
                  )}
                </div>

                {userStats.shares === 0n ? (
                  <p className="text-sm opacity-70">You do not have a position in this vault yet.</p>
                ) : (
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="opacity-70">Current Value</span>
                      <span className="font-semibold">
                        {formatTokenAmount(userStats.value, assetDecimals)} {assetSymbol}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="opacity-70">Total Deposited</span>
                      <span>{formatTokenAmount(userStats.deposited, assetDecimals)} {assetSymbol}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="opacity-70">Total Withdrawn</span>
                      <span>{formatTokenAmount(userStats.redeemed, assetDecimals)} {assetSymbol}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="opacity-70">Profit / Loss</span>
                      <span className={userStats.profit >= 0n ? "text-success" : "text-error"}>
                        {userStats.profit >= 0n ? "+" : ""}
                        {formatTokenAmount(userStats.profit, assetDecimals)} {assetSymbol} ({
                          formatPercent(userStats.profitPercent, 2)
                        })
                      </span>
                    </div>
                  </div>
                )}

                <div className="card-actions justify-end gap-2 pt-2">
                  <button
                    className="btn btn-primary"
                    onClick={() => setIsDepositModalOpen(true)}
                    disabled={!vault.isActive}
                  >
                    Deposit
                  </button>
                  <button
                    className="btn btn-accent"
                    onClick={() => setIsMintModalOpen(true)}
                    disabled={!vault.isActive}
                  >
                    Mint Shares
                  </button>
                  <button
                    className="btn btn-secondary"
                    onClick={() => setIsWithdrawModalOpen(true)}
                    disabled={userStats.shares === 0n}
                  >
                    Withdraw
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="space-y-6 lg:col-span-2" ref={rightColumnRef}>
          <div className="vault-detail-card card bg-base-100 shadow-xl">
            <div className="card-body">
              <h2 className="card-title text-white">Performance Overview</h2>
              <div className="mt-4 grid gap-4 md:grid-cols-4">
                <div>
                  <p className="opacity-70">Current APY</p>
                  <p className="text-2xl font-semibold text-success">
                    {formatPercent(performance?.currentAPY ?? 0)}
                  </p>
                </div>
                <div>
                  <p className="opacity-70">30d APY</p>
                  <p className="text-2xl font-semibold text-white">
                    {formatPercent(performance?.thirtyDayAPY ?? 0)}
                  </p>
                </div>
                <div>
                  <p className="opacity-70">90d APY</p>
                  <p className="text-2xl font-semibold text-white">
                    {formatPercent(performance?.ninetyDayAPY ?? 0)}
                  </p>
                </div>
                <div>
                  <p className="opacity-70">All-Time Fees</p>
                  <p className="text-2xl font-semibold text-white">
                    ${
                      (performance?.totalFeesPaid ?? 0).toLocaleString(undefined, {
                        maximumFractionDigits: 0,
                      })
                    }
                  </p>
                </div>
              </div>

              {performance && (
                <div className="mt-6 grid gap-4 md:grid-cols-2">
                  <div className="rounded-lg bg-black/30 p-4">
                    <h3 className="font-semibold text-white">Fee Breakdown</h3>
                    <div className="mt-2 space-y-1 text-sm">
                      <div className="flex justify-between">
                        <span className="opacity-70">Management Fee Rate</span>
                        <span>{formatPercent(performance.managementFeeRate * 100)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="opacity-70">Performance Fee Rate</span>
                        <span>{formatPercent(performance.performanceFeeRate * 100)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="opacity-70">Management Fees (USD)</span>
                        <span>${performance.feeBreakdown.managementFees.toFixed(2)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="opacity-70">Performance Fees (USD)</span>
                        <span>${performance.feeBreakdown.performanceFees.toFixed(2)}</span>
                      </div>
                    </div>
                  </div>
                  <div className="rounded-lg bg-black/30 p-4">
                    <h3 className="font-semibold text-white">Risk Metrics</h3>
                    <div className="mt-2 space-y-1 text-sm">
                      <div className="flex justify-between">
                        <span className="opacity-70">Volatility</span>
                        <span>{formatPercent(performance.riskMetrics.volatility * 100, 2)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="opacity-70">Max Drawdown</span>
                        <span>{formatPercent(performance.riskMetrics.maxDrawdown * 100, 2)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="opacity-70">Sharpe Ratio</span>
                        <span>{performance.riskMetrics.sharpeRatio.toFixed(2)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>

          <div className="vault-detail-card card bg-base-100 shadow-xl">
            <div className="card-body">
              <h2 className="card-title text-white">Investment Allocations</h2>
              {vault.allocations && vault.allocations.length > 0 ? (
                <div className="mt-4 space-y-3">
                  {vault.allocations.map(allocation => {
                    const percentage = (Number(allocation.allocation) / 1000) * 100;
                    const allocationAmount = totalAssets * BigInt(allocation.allocation) / 1000n;
                    return (
                      <div
                        key={allocation.id}
                        className="rounded-lg border border-[#803100]/30 bg-black/30 p-4"
                      >
                        <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
                          <div>
                            <p className="text-lg font-semibold text-white">{allocation.adapterType}</p>
                            <Address address={allocation.adapterAddress} size="sm" />
                          </div>
                          <div className="flex flex-col items-end">
                            <span className="text-2xl font-semibold text-white">{percentage.toFixed(1)}%</span>
                            <span className="text-sm opacity-70">
                              {formatTokenAmount(allocationAmount, assetDecimals)} {assetSymbol}
                            </span>
                          </div>
                        </div>
                        <progress className="progress progress-primary mt-3 w-full" value={percentage} max={100} />
                      </div>
                    );
                  })}
                </div>
              ) : (
                <p className="opacity-70">No strategy allocations configured yet.</p>
              )}
            </div>
          </div>

          <div className="vault-detail-card card bg-base-100 shadow-xl" ref={activityRef}>
            <div className="card-body">
              <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <h2 className="card-title text-white">Recent Activity</h2>
                <span className="badge border-none bg-[#803100]/70 text-white">Last {transactionRows.length} entries</span>
              </div>
              <div className="mt-4 overflow-x-auto">
                <table className="table table-zebra">
                  <thead>
                    <tr className="text-xs uppercase opacity-70">
                      <th>Type</th>
                      <th className="text-right">Assets</th>
                      <th className="text-right">Shares</th>
                      <th>Timestamp</th>
                      <th>Tx Hash</th>
                    </tr>
                  </thead>
                  <tbody>
                    {transactionRows.length === 0 && (
                      <tr>
                        <td colSpan={5} className="py-8 text-center text-sm opacity-70">
                          No on-chain activity recorded yet.
                        </td>
                      </tr>
                    )}
                    {transactionRows.map(tx => (
                      <tr key={`${tx.hash}-${tx.type}-${tx.timestamp}`} className="vault-activity-row text-sm">
                        <td>
                          <span
                            className={`badge border-none ${tx.type === "Deposit" ? "bg-success/60" : "bg-error/60"}`}
                          >
                            {tx.type}
                          </span>
                        </td>
                        <td className="text-right">
                          {tx.type === "Deposit" ? "+" : "-"}
                          {formatTokenAmount(tx.assets, assetDecimals)} {assetSymbol}
                        </td>
                        <td className="text-right">
                          {tx.type === "Deposit" ? "+" : "-"}
                          {formatTokenAmount(tx.shares, assetDecimals)} v{assetSymbol}
                        </td>
                        <td>{new Date(tx.timestamp).toLocaleString()}</td>
                        <td>
                          <span className="font-mono text-xs">
                            {tx.hash?.slice(0, 10)}...{tx.hash?.slice(-6)}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-10" ref={roleRef}>
        <div className="vault-role-card">
          <RoleDisplay
            vaultAddress={vault.address}
            managerAddress={vault.manager?.owner ?? vault.manager?.address ?? null}
            showPermissions
          />
        </div>
      </div>

      {isETHVault ? (
        <>
          <DepositETHModal
            vault={vault}
            isOpen={isDepositModalOpen}
            onClose={() => setIsDepositModalOpen(false)}
            onSuccess={refetch}
          />
          <MintETHModal
            vault={vault}
            isOpen={isMintModalOpen}
            onClose={() => setIsMintModalOpen(false)}
            onSuccess={refetch}
          />
          <WithdrawETHModal
            vault={vault}
            isOpen={isWithdrawModalOpen}
            onClose={() => setIsWithdrawModalOpen(false)}
            onSuccess={refetch}
          />
        </>
      ) : (
        <>
          <DepositModal
            vault={vault}
            isOpen={isDepositModalOpen}
            onClose={() => setIsDepositModalOpen(false)}
            onSuccess={refetch}
          />
          <MintModal
            vault={vault}
            isOpen={isMintModalOpen}
            onClose={() => setIsMintModalOpen(false)}
            onSuccess={refetch}
          />
          <WithdrawModal
            vault={vault}
            isOpen={isWithdrawModalOpen}
            onClose={() => setIsWithdrawModalOpen(false)}
            onSuccess={refetch}
          />
        </>
      )}

      <VaultReactivationModal
        vault={vault}
        isOpen={isReactivationModalOpen}
        onClose={() => setIsReactivationModalOpen(false)}
        onSuccess={refetch}
      />
    </div>
  );
};

export default VaultDetailPage;
