"use client";

import { useMemo, useRef, useState } from "react";
import Link from "next/link";
import { formatUnits, parseUnits } from "viem";
import { CountUp } from "~~/components/ui/CountUp";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useGsapFadeReveal, useGsapHeroIntro, useGsapStaggerReveal } from "~~/hooks/useGsapAnimations";
import { useVaultPerformance } from "~~/hooks/useVaultPerformance";
import { useVaults } from "~~/hooks/useVaults";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import { useGlobalState } from "~~/services/store/store";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type AllocationInput = {
  adapterAddress: string;
  allocation: number; // 百分比 0-100
};

const StrategiesPage = () => {
  const { vaults, loading, error, refetch } = useVaults(100);
  const { data: performanceData } = useVaultPerformance(1000);
  const nativePrice = useGlobalState(state => state.nativeCurrency.price) || 0;

  const tPage = useTranslations("admin.strategiesPage");
  const tStrategies = useTranslations("admin.strategies");
  const tMenu = useTranslations("menu");
  const tActions = useTranslations("common.actions");

  const [selectedVault, setSelectedVault] = useState<Vault | null>(null);
  const [isEditing, setIsEditing] = useState(false);
  const [allocations, setAllocations] = useState<AllocationInput[]>([]);
  const [isUpdating, setIsUpdating] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [partialUpdateState, setPartialUpdateState] = useState({
    divestAdapter: "",
    divestAmount: "",
    investAdapter: "",
    investAmount: "",
    investAllocation: "100",
  });

  const { data: adapterAddressesData, refetch: refetchAdapters } = useScaffoldReadContract({
    contractName: "AIAgentVaultManager",
    functionName: "getAllAdapters",
    query: {
      enabled: true,
    },
  });

  const adapterAddresses = useMemo(
    () =>
      Array.isArray(adapterAddressesData) ? adapterAddressesData.map(address => (address as string).toLowerCase()) : [],
    [adapterAddressesData],
  );

  const safeBigInt = (value?: string) => {
    try {
      return BigInt(value || "0");
    } catch {
      return 0n;
    }
  };

  // 写入合约 - 更新分配策略
  const { writeContractAsync: updateAllocationAsync } = useScaffoldWriteContract({
    contractName: "AIAgentVaultManager",
  });

  // 写入合约 - 部分更新分配策略
  const { writeContractAsync: partialUpdateAllocationAsync } = useScaffoldWriteContract({
    contractName: "AIAgentVaultManager",
  });

  // 写入合约 - 撤回所有投资
  const { writeContractAsync: withdrawAllAsync } = useScaffoldWriteContract({
    contractName: "AIAgentVaultManager",
  });

  // 过滤活跃金库
  const activeVaults = useMemo(() => {
    if (!vaults) return [];
    return vaults.filter(v => v.isActive);
  }, [vaults]);

  // 搜索过滤
  const filteredVaults = useMemo(() => {
    if (!searchQuery) return activeVaults;
    const query = searchQuery.toLowerCase();
    return activeVaults.filter(
      v =>
        v.name.toLowerCase().includes(query) ||
        v.address.toLowerCase().includes(query) ||
        v.asset?.symbol?.toLowerCase().includes(query),
    );
  }, [activeVaults, searchQuery]);

  // 计算总管理资产
  const totalManagedAssets = useMemo(() => {
    if (!activeVaults) return 0;
    return activeVaults.reduce((sum, vault) => {
      const assets = parseFloat(formatUnits(safeBigInt(vault.totalAssets), vault.asset?.decimals || 18));
      return sum + assets * nativePrice;
    }, 0);
  }, [activeVaults, nativePrice]);

  // 计算活跃策略数
  const activeStrategiesCount = useMemo(() => {
    if (!activeVaults) return 0;
    return activeVaults.reduce((sum, vault) => sum + (vault.allocations?.length || 0), 0);
  }, [activeVaults]);

  // 处理金库选择
  const handleVaultSelect = (vault: Vault) => {
    setSelectedVault(vault);
    setIsEditing(false);

    // 初始化分配数据
    if (vault.allocations && vault.allocations.length > 0) {
      setAllocations(
        vault.allocations.map(a => ({
          adapterAddress: (a.adapterAddress || "").toLowerCase(),
          allocation: (Number(a.allocation) / 1000) * 100,
        })),
      );
    } else if (adapterAddresses.length > 0) {
      const count = Math.min(adapterAddresses.length, 3);
      const base = Math.floor(100 / count);
      const remainder = 100 - base * count;
      const defaultAllocations = adapterAddresses.slice(0, count).map((address, index) => ({
        adapterAddress: address,
        allocation: index === 0 ? base + remainder : base,
      }));
      setAllocations(defaultAllocations);
    } else {
      setAllocations([]);
    }
  };

  // 更新分配百分比
  const handleAllocationChange = (index: number, value: number) => {
    const newAllocations = [...allocations];
    newAllocations[index].allocation = Math.max(0, Math.min(100, value));
    setAllocations(newAllocations);
  };

  // 计算总分配比例
  const totalAllocation = useMemo(() => {
    return allocations.reduce((sum, a) => sum + a.allocation, 0);
  }, [allocations]);

  // 执行策略更新
  const handleUpdateStrategy = async () => {
    if (!selectedVault) {
      notification.error(tStrategies("notifications.vaultRequired"));
      return;
    }

    if (totalAllocation !== 100) {
      notification.error(tStrategies("notifications.totalMustBeHundred"));
      return;
    }

    if (!selectedVault.asset?.address) {
      notification.error(tStrategies("notifications.assetUnavailable"));
      return;
    }

    if (adapterAddresses.length === 0) {
      notification.error(tStrategies("notifications.noAdapters"));
      return;
    }

    const adapterIndices: bigint[] = [];
    const allocationData: bigint[] = [];

    for (const allocation of allocations) {
      const adapterIndex = adapterAddresses.findIndex(address => address === allocation.adapterAddress.toLowerCase());
      if (adapterIndex < 0) {
        notification.error(`${tStrategies("notifications.adapterUnavailable")}: ${allocation.adapterAddress}`);
        return;
      }

      adapterIndices.push(BigInt(adapterIndex));
      allocationData.push(BigInt(Math.round((allocation.allocation / 100) * 1000)));
    }

    if (allocationData.length > 0) {
      const totalPrecision = allocationData.reduce((sum, value) => sum + value, 0n);
      const target = 1000n;
      if (totalPrecision !== target) {
        const diff = target - totalPrecision;
        allocationData[allocationData.length - 1] = allocationData[allocationData.length - 1] + diff;
      }
    }

    setIsUpdating(true);
    try {
      await updateAllocationAsync(
        {
          functionName: "updateHoldingAllocation",
          args: [selectedVault.asset.address as `0x${string}`, adapterIndices, allocationData],
        },
        {
          onBlockConfirmation: () => {
            notification.success(tStrategies("notifications.updateSuccess"));
            setIsEditing(false);
            refetch();
            refetchAdapters();
          },
        },
      );
    } catch (error: any) {
      console.error("Strategy update failed:", error);
      notification.error(error?.message || tStrategies("notifications.updateFailed"));
    } finally {
      setIsUpdating(false);
    }
  };

  // 撤回所有投资
  const handleWithdrawAll = async () => {
    if (!selectedVault) return;

    if (!selectedVault.asset?.address) {
      notification.error(tStrategies("notifications.assetUnavailable"));
      return;
    }

    const confirmed = window.confirm(tStrategies("confirmations.withdrawAll").replace("{vault}", selectedVault.name));

    if (!confirmed) return;

    setIsUpdating(true);
    try {
      await withdrawAllAsync(
        {
          functionName: "withdrawAllInvestments",
          args: [selectedVault.asset.address as `0x${string}`],
        },
        {
          onBlockConfirmation: () => {
            notification.success(tStrategies("notifications.withdrawSuccess"));
            refetch();
          },
        },
      );
    } catch (error: any) {
      console.error("Withdraw all failed:", error);
      notification.error(error?.message || tStrategies("notifications.withdrawFailed"));
    } finally {
      setIsUpdating(false);
    }
  };

  // 部分策略更新
  const handlePartialUpdate = async () => {
    if (!selectedVault) {
      notification.error(tStrategies("notifications.vaultRequired"));
      return;
    }

    if (!selectedVault.asset?.address) {
      notification.error(tStrategies("notifications.assetUnavailable"));
      return;
    }

    const { divestAdapter, divestAmount, investAdapter, investAmount, investAllocation } = partialUpdateState;
    if (!divestAdapter && !investAdapter) {
      notification.error(tStrategies("notifications.targetRequired"));
      return;
    }

    const decimals = selectedVault.asset?.decimals ?? 18;

    const divestAdapterIndices: bigint[] = [];
    const divestAmounts: bigint[] = [];
    const investAdapterIndices: bigint[] = [];
    const investAmounts: bigint[] = [];
    const investAllocations: bigint[] = [];

    if (divestAdapter) {
      if (!divestAmount || Number(divestAmount) <= 0) {
        notification.error(tStrategies("notifications.divestAmountRequired"));
        return;
      }

      const adapterIndex = adapterAddresses.findIndex(addr => addr === divestAdapter.toLowerCase());
      if (adapterIndex < 0) {
        notification.error(tStrategies("notifications.divestAdapterMissing"));
        return;
      }

      divestAdapterIndices.push(BigInt(adapterIndex));
      try {
        divestAmounts.push(parseUnits(divestAmount, decimals));
      } catch {
        notification.error(tStrategies("notifications.divestAmountInvalid"));
        return;
      }
    }

    if (investAdapter) {
      if (!investAmount || Number(investAmount) <= 0) {
        notification.error(tStrategies("notifications.investAmountRequired"));
        return;
      }

      const adapterIndex = adapterAddresses.findIndex(addr => addr === investAdapter.toLowerCase());
      if (adapterIndex < 0) {
        notification.error(tStrategies("notifications.investAdapterMissing"));
        return;
      }

      investAdapterIndices.push(BigInt(adapterIndex));
      try {
        investAmounts.push(parseUnits(investAmount, decimals));
      } catch {
        notification.error(tStrategies("notifications.investAmountInvalid"));
        return;
      }

      const allocationPercent = Math.min(Math.max(Number(investAllocation) || 100, 0), 100);
      investAllocations.push(BigInt(Math.round(allocationPercent * 10))); // 100% => 1000
    }

    if (divestAdapterIndices.length === 0 && investAdapterIndices.length === 0) {
      notification.error(tStrategies("notifications.adjustmentInfoRequired"));
      return;
    }

    setIsUpdating(true);
    try {
      await partialUpdateAllocationAsync(
        {
          functionName: "partialUpdateHoldingAllocation",
          args: [
            selectedVault.asset.address as `0x${string}`,
            divestAdapterIndices,
            divestAmounts,
            investAdapterIndices,
            investAmounts,
            investAllocations,
          ],
        },
        {
          onBlockConfirmation: () => {
            notification.success(tStrategies("notifications.partialSuccess"));
            setPartialUpdateState({
              divestAdapter: "",
              divestAmount: "",
              investAdapter: "",
              investAmount: "",
              investAllocation: "100",
            });
            refetch();
            refetchAdapters();
          },
        },
      );
    } catch (error: any) {
      console.error("Partial update failed:", error);
      notification.error(error?.message || tStrategies("notifications.partialFailed"));
    } finally {
      setIsUpdating(false);
    }
  };

  const formatAssets = (vault: Vault) => {
    const assets = formatUnits(safeBigInt(vault.totalAssets), vault.asset?.decimals || 18);
    return parseFloat(assets).toLocaleString(undefined, { maximumFractionDigits: 0 });
  };

  const heroRef = useRef<HTMLDivElement | null>(null);
  const statsRef = useRef<HTMLDivElement | null>(null);
  const selectorRef = useRef<HTMLDivElement | null>(null);
  const managementRef = useRef<HTMLDivElement | null>(null);

  useGsapHeroIntro(heroRef);
  useGsapStaggerReveal(statsRef, {
    selector: ".strategies-stat-card",
    deps: [totalManagedAssets, activeStrategiesCount, performanceData?.length ?? 0],
  });
  useGsapFadeReveal(selectorRef, ".strategies-selector-item", [filteredVaults.length, searchQuery]);
  useGsapFadeReveal(managementRef, ".strategies-management-card", [selectedVault?.id ?? "", isEditing]);

  if (loading) {
    return (
      <div className="flex min-h-screen flex-1 items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <span className="loading loading-spinner loading-lg text-[#fbe6dc]" />
          <p className="text-lg text-[#fbe6dc]">{tPage("loading")}</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto flex-1 px-4 py-8">
        <div className="rounded-lg border border-[#803100]/30 bg-black/60 p-6 backdrop-blur-sm">
          <span className="text-white">
            {tPage("error")}: {error.message}
          </span>
        </div>
      </div>
    );
  }

  return (
    <div className="relative flex grow flex-col items-center">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="flex justify-between items-center mb-8" ref={heroRef}>
          <div>
            <h1 className="hero-heading text-4xl font-bold mb-2 text-white">{tPage("title")}</h1>
            <div className="hero-subheading text-sm breadcrumbs">
              <ul className="text-[#fbe6dc]">
                <li>
                  <Link href="/" className="hover:text-white">
                    {tPage("breadcrumbs.home", tMenu("home"))}
                  </Link>
                </li>
                <li>
                  <Link href="/admin/vaults" className="hover:text-white">
                    {tPage("breadcrumbs.admin", tMenu("admin"))}
                  </Link>
                </li>
                <li className="text-white">{tPage("breadcrumbs.current")}</li>
              </ul>
            </div>
          </div>
          <div className="hero-cta badge badge-lg bg-[#803100] text-white border-none">{tPage("badge")}</div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8" ref={statsRef}>
          <div className="strategies-stat-card stat bg-black/60 backdrop-blur-sm shadow-lg rounded-lg border border-[#803100]/30">
            <div className="stat-title text-[#fbe6dc]">{tPage("stats.managedAssets")}</div>
            <div className="stat-value text-2xl text-white">
              <CountUp value={totalManagedAssets} format={value => `$${(value / 1_000_000).toFixed(2)}M`} />
            </div>
          </div>
          <div className="strategies-stat-card stat bg-black/60 backdrop-blur-sm shadow-lg rounded-lg border border-[#803100]/30">
            <div className="stat-title text-[#fbe6dc]">{tPage("stats.activeStrategies")}</div>
            <div className="stat-value text-2xl text-white">
              <CountUp value={activeStrategiesCount} format={value => Math.round(value).toString()} />
            </div>
          </div>
          <div className="strategies-stat-card stat bg-black/60 backdrop-blur-sm shadow-lg rounded-lg border border-[#803100]/30">
            <div className="stat-title text-[#fbe6dc]">{tPage("stats.averageApy")}</div>
            <div className="stat-value text-2xl text-success">
              <CountUp
                value={
                  performanceData.length > 0
                    ? performanceData.reduce((sum, p) => sum + p.currentAPY, 0) / performanceData.length
                    : 8.4
                }
                format={value => `${value.toFixed(1)}%`}
              />
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left: Vault Selector */}
          <div className="lg:col-span-1">
            <div className="card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30" ref={selectorRef}>
              <div className="card-body">
                <h2 className="card-title text-white">{tPage("selector.title")}</h2>

                {/* Search */}
                <input
                  type="text"
                  placeholder={tPage("selector.searchPlaceholder")}
                  className="input input-bordered w-full mb-4 bg-black/40 border-[#803100]/30 text-white placeholder:text-[#fbe6dc]/50"
                  value={searchQuery}
                  onChange={e => setSearchQuery(e.target.value)}
                />

                {/* Vault List */}
                <div className="space-y-2">
                  <p className="text-sm text-[#fbe6dc]">
                    {tPage("selector.listLabel")} ({filteredVaults.length})
                  </p>
                  <div className="space-y-2 max-h-96 overflow-y-auto">
                    {filteredVaults.map(vault => (
                      <button
                        key={vault.id}
                        onClick={() => handleVaultSelect(vault)}
                        className={`strategies-selector-item w-full text-left p-3 rounded-lg transition-colors ${
                          selectedVault?.id === vault.id
                            ? "bg-[#803100] text-white"
                            : "bg-black/40 hover:bg-black/60 text-[#fbe6dc] border border-[#803100]/30"
                        }`}
                      >
                        <p className="font-semibold">{vault.name}</p>
                        <div className="flex justify-between text-xs mt-1">
                          <span>TVL: ${formatAssets(vault)}</span>
                          <span>
                            APY:{" "}
                            {performanceData
                              .find(p => p.vault.address.toLowerCase() === vault.address.toLowerCase())
                              ?.currentAPY.toFixed(1) || "8.5"}
                            %
                          </span>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right: Strategy Management */}
          <div className="lg:col-span-2 space-y-6" ref={managementRef}>
            {selectedVault ? (
              <>
                {/* Current Allocation */}
                <div className="strategies-management-card card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30">
                  <div className="card-body">
                    <h2 className="card-title text-white">{tPage("current.title")}</h2>
                    <p className="text-sm text-[#fbe6dc] mb-4">
                      {selectedVault.name} ({selectedVault.address.slice(0, 10)}...{selectedVault.address.slice(-8)})
                    </p>

                    <div className="overflow-x-auto">
                      <table className="table table-zebra">
                        <thead>
                          <tr className="text-[#fbe6dc] border-[#803100]/30">
                            <th>{tPage("current.table.adapter")}</th>
                            <th>{tPage("current.table.allocation")}</th>
                            <th>{tPage("current.table.amount")}</th>
                            <th>{tPage("current.table.apy")}</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selectedVault.allocations && selectedVault.allocations.length > 0 ? (
                            selectedVault.allocations.map((allocation, index) => {
                              const percentage = (Number(allocation.allocation) / 1000) * 100;
                              const totalAssets = BigInt(selectedVault.totalAssets || "0");
                              const amount = (totalAssets * BigInt(allocation.allocation || 0)) / 1000n;
                              return (
                                <tr key={index} className="border-[#803100]/30">
                                  <td>
                                    <span className="font-semibold text-white">{allocation.adapterType}</span>
                                  </td>
                                  <td>
                                    <div className="flex items-center gap-2">
                                      <progress
                                        className="progress progress-primary w-24"
                                        value={percentage}
                                        max="100"
                                      ></progress>
                                      <span className="font-semibold text-white">{percentage.toFixed(1)}%</span>
                                    </div>
                                  </td>
                                  <td className="text-[#fbe6dc]">
                                    {formatUnits(amount, selectedVault.asset?.decimals || 18)}{" "}
                                    {selectedVault.asset?.symbol}
                                  </td>
                                  <td className="text-success font-semibold">
                                    {allocation.adapterType.includes("Aave")
                                      ? "6.5%"
                                      : allocation.adapterType.includes("V3")
                                        ? "9.8%"
                                        : "8.2%"}
                                  </td>
                                </tr>
                              );
                            })
                          ) : (
                            <tr>
                              <td colSpan={4} className="text-center text-[#fbe6dc]">
                                {tPage("current.empty")}
                              </td>
                            </tr>
                          )}
                        </tbody>
                      </table>
                    </div>

                    <div className="card-actions justify-end mt-4">
                      <button
                        onClick={() => setIsEditing(true)}
                        className="btn bg-[#803100] hover:bg-[#803100]/80 text-white border-none btn-sm"
                      >
                        {tPage("actions.edit")}
                      </button>
                      <button onClick={handleWithdrawAll} className="btn btn-error btn-sm" disabled={isUpdating}>
                        {tPage("actions.withdrawAll")}
                      </button>
                    </div>
                  </div>
                </div>

                {/* Edit Strategy */}
                {isEditing && (
                  <div className="strategies-management-card card bg-black/60 backdrop-blur-sm shadow-xl border-2 border-[#803100]">
                    <div className="card-body">
                      <h2 className="card-title text-white">{tPage("edit.title")}</h2>

                      {adapterAddresses.length === 0 ? (
                        <div className="alert alert-warning">
                          <span>{tPage("edit.noAdapters")}</span>
                        </div>
                      ) : (
                        <div className="space-y-4">
                          {allocations.map((allocation, index) => (
                            <div key={index} className="bg-black/40 p-4 rounded-lg border border-[#803100]/30">
                              <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
                                <div className="flex-1">
                                  <label className="label text-xs text-[#fbe6dc] mb-1">
                                    {tPage("edit.labels.adapter")}
                                  </label>
                                  <select
                                    className="select select-sm select-bordered w-full font-mono bg-black/40 border-[#803100]/30 text-white"
                                    value={allocation.adapterAddress}
                                    onChange={e =>
                                      setAllocations(prev =>
                                        prev.map((item, itemIndex) =>
                                          itemIndex === index
                                            ? { ...item, adapterAddress: e.target.value.toLowerCase() }
                                            : item,
                                        ),
                                      )
                                    }
                                    disabled={isUpdating}
                                  >
                                    <option value="" disabled>
                                      {tPage("partial.placeholders.selectAdapter")}
                                    </option>
                                    {adapterAddresses.map((adapter, adapterIndex) => (
                                      <option key={adapter} value={adapter}>
                                        #{adapterIndex} — {adapter}
                                      </option>
                                    ))}
                                  </select>
                                </div>
                                <div className="w-full md:w-40">
                                  <label className="label text-xs text-[#fbe6dc] mb-1">
                                    {tPage("edit.labels.allocation")}
                                  </label>
                                  <input
                                    type="number"
                                    min="0"
                                    max="100"
                                    step="1"
                                    value={allocation.allocation}
                                    onChange={e => handleAllocationChange(index, parseFloat(e.target.value) || 0)}
                                    className="input input-bordered input-sm w-full bg-black/40 border-[#803100]/30 text-white"
                                    disabled={isUpdating}
                                  />
                                </div>
                              </div>
                              <progress
                                className="progress progress-primary w-full mt-3"
                                value={allocation.allocation}
                                max="100"
                              ></progress>
                            </div>
                          ))}
                        </div>
                      )}

                      <div className="divider"></div>
                      <div className="flex justify-between items-center">
                        <span className="font-semibold text-white">{tPage("edit.summary.total")}</span>
                        <div className="flex items-center gap-2">
                          <progress
                            className={`progress w-48 ${totalAllocation === 100 ? "progress-success" : "progress-error"}`}
                            value={totalAllocation}
                            max="100"
                          ></progress>
                          <span className={`font-bold ${totalAllocation === 100 ? "text-success" : "text-error"}`}>
                            {totalAllocation.toFixed(1)}%
                          </span>
                        </div>
                      </div>

                      <div className="card-actions justify-end mt-4">
                        <button onClick={() => setIsEditing(false)} className="btn btn-ghost text-white">
                          {tActions("cancel")}
                        </button>
                        <button
                          onClick={handleUpdateStrategy}
                          disabled={isUpdating || totalAllocation !== 100 || adapterAddresses.length === 0}
                          className="btn bg-[#803100] hover:bg-[#803100]/80 text-white border-none"
                        >
                          {isUpdating ? (
                            <>
                              <span className="loading loading-spinner loading-sm"></span>
                              {tPage("actions.applying")}
                            </>
                          ) : (
                            tPage("actions.apply")
                          )}
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* Partial Adjustment */}
                <div className="card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30">
                  <div className="card-body">
                    <h2 className="card-title text-white">{tPage("partial.title")}</h2>
                    <p className="text-sm text-[#fbe6dc] mb-4">{tPage("partial.description")}</p>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="bg-black/40 p-4 rounded-lg border border-[#803100]/30">
                        <h3 className="font-semibold mb-3 text-error">{tPage("partial.divestHeading")}</h3>
                        <div className="space-y-3">
                          <div>
                            <label className="label text-xs text-[#fbe6dc]">{tPage("partial.labels.adapter")}</label>
                            <select
                              className="select select-sm select-bordered w-full bg-black/40 border-[#803100]/30 text-white"
                              value={partialUpdateState.divestAdapter}
                              onChange={e =>
                                setPartialUpdateState(prev => ({
                                  ...prev,
                                  divestAdapter: e.target.value,
                                }))
                              }
                              disabled={isUpdating}
                            >
                              <option value="">{tPage("partial.placeholders.selectAdapter")}</option>
                              {selectedVault.allocations?.map((allocation, index) => (
                                <option key={index} value={allocation.adapterAddress}>
                                  {allocation.adapterType} ({((Number(allocation.allocation) / 1000) * 100).toFixed(1)}
                                  %)
                                </option>
                              ))}
                            </select>
                          </div>
                          <div>
                            <label className="label text-xs text-[#fbe6dc]">
                              {`${tPage("partial.labels.divestAmount")} (${selectedVault.asset?.symbol})`}
                            </label>
                            <input
                              type="number"
                              placeholder="0.00"
                              className="input input-sm input-bordered w-full bg-black/40 border-[#803100]/30 text-white placeholder:text-[#fbe6dc]/50"
                              value={partialUpdateState.divestAmount}
                              onChange={e =>
                                setPartialUpdateState(prev => ({
                                  ...prev,
                                  divestAmount: e.target.value,
                                }))
                              }
                              disabled={isUpdating}
                            />
                          </div>
                        </div>
                      </div>

                      <div className="bg-black/40 p-4 rounded-lg border border-[#803100]/30">
                        <h3 className="font-semibold mb-3 text-success">{tPage("partial.investHeading")}</h3>
                        <div className="space-y-3">
                          <div>
                            <label className="label text-xs text-[#fbe6dc]">{tPage("partial.labels.adapter")}</label>
                            <select
                              className="select select-sm select-bordered w-full bg-black/40 border-[#803100]/30 text-white"
                              value={partialUpdateState.investAdapter}
                              onChange={e =>
                                setPartialUpdateState(prev => ({
                                  ...prev,
                                  investAdapter: e.target.value,
                                }))
                              }
                              disabled={isUpdating}
                            >
                              <option value="">{tPage("partial.placeholders.selectAdapter")}</option>
                              {selectedVault.allocations?.map((allocation, index) => (
                                <option key={index} value={allocation.adapterAddress}>
                                  {allocation.adapterType} ({((Number(allocation.allocation) / 1000) * 100).toFixed(1)}
                                  %)
                                </option>
                              ))}
                            </select>
                          </div>
                          <div>
                            <label className="label text-xs text-[#fbe6dc]">
                              {`${tPage("partial.labels.investAmount")} (${selectedVault.asset?.symbol})`}
                            </label>
                            <input
                              type="number"
                              placeholder="0.00"
                              className="input input-sm input-bordered w-full bg-black/40 border-[#803100]/30 text-white placeholder:text-[#fbe6dc]/50"
                              value={partialUpdateState.investAmount}
                              onChange={e =>
                                setPartialUpdateState(prev => ({
                                  ...prev,
                                  investAmount: e.target.value,
                                }))
                              }
                              disabled={isUpdating}
                            />
                          </div>
                          <div>
                            <label className="label text-xs text-[#fbe6dc]">
                              {tPage("partial.labels.targetAllocation")}
                            </label>
                            <input
                              type="number"
                              min="0"
                              max="100"
                              placeholder="100"
                              className="input input-sm input-bordered w-full bg-black/40 border-[#803100]/30 text-white placeholder:text-[#fbe6dc]/50"
                              value={partialUpdateState.investAllocation}
                              onChange={e =>
                                setPartialUpdateState(prev => ({
                                  ...prev,
                                  investAllocation: e.target.value,
                                }))
                              }
                              disabled={isUpdating}
                            />
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="card-actions justify-end mt-4">
                      <button
                        onClick={() =>
                          setPartialUpdateState({
                            divestAdapter: "",
                            divestAmount: "",
                            investAdapter: "",
                            investAmount: "",
                            investAllocation: "100",
                          })
                        }
                        className="btn btn-ghost btn-sm text-white"
                        disabled={isUpdating}
                      >
                        {tPage("partial.buttons.reset")}
                      </button>
                      <button onClick={handlePartialUpdate} className="btn btn-warning btn-sm" disabled={isUpdating}>
                        {isUpdating ? (
                          <>
                            <span className="loading loading-spinner loading-sm"></span>
                            {tPage("partial.buttons.submitting")}
                          </>
                        ) : (
                          tPage("partial.buttons.submit")
                        )}
                      </button>
                    </div>
                  </div>
                </div>

                {/* Strategy History */}
                <div className="card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30">
                  <div className="card-body">
                    <h2 className="card-title text-white">{tPage("history.title")}</h2>
                    <div className="overflow-x-auto">
                      <table className="table table-sm">
                        <thead>
                          <tr className="text-[#fbe6dc] border-[#803100]/30">
                            <th>{tPage("history.table.time")}</th>
                            <th>{tPage("history.table.type")}</th>
                            <th>{tPage("history.table.detail")}</th>
                            <th>{tPage("history.table.executor")}</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr>
                            <td colSpan={4} className="text-center text-[#fbe6dc] text-sm">
                              {tStrategies("history.empty")}
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </>
            ) : (
              <div className="card bg-black/60 backdrop-blur-sm shadow-xl border border-[#803100]/30">
                <div className="card-body items-center text-center">
                  <p className="text-lg text-[#fbe6dc]">{tStrategies("history.empty")}</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default StrategiesPage;
