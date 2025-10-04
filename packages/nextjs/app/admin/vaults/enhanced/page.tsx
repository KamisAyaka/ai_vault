"use client";

import { useMemo, useRef, useState } from "react";
import Link from "next/link";
import { formatUnits } from "viem";
import { useAccount } from "wagmi";
import { AdminVaultActions } from "~~/components/admin/AdminVaultActions";
import { VaultCreationForm } from "~~/components/admin/VaultCreationForm";
import { RoleDisplay } from "~~/components/auth/RoleDisplay";
import { useGsapFadeReveal, useGsapHeroIntro, useGsapStaggerReveal } from "~~/hooks/useGsapAnimations";
import { useVaults } from "~~/hooks/useVaults";
import type { Vault } from "~~/types/vault";

const EnhancedAdminVaultsPage = () => {
  const { address: connectedAddress } = useAccount();
  const { vaults, loading, error, refetch } = useVaults(100);

  const [selectedVault, setSelectedVault] = useState<Vault | null>(null);
  const [selectedVaults, setSelectedVaults] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | "active" | "inactive">("all");
  const [assetFilter, setAssetFilter] = useState<string>("all");
  const [sortBy, setSortBy] = useState<"tvl" | "apy" | "users">("tvl");

  // 检查是否为管理员
  const isAdmin = useMemo(() => {
    // 简化版权限检查 - 实际应该检查是否为工厂所有者或金库管理器
    return !!connectedAddress;
  }, [connectedAddress]);

  // 过滤和排序金库
  const filteredAndSortedVaults = useMemo(() => {
    let result = [...vaults];

    // 状态过滤
    if (statusFilter === "active") {
      result = result.filter(v => v.isActive);
    } else if (statusFilter === "inactive") {
      result = result.filter(v => !v.isActive);
    }

    // 资产过滤
    if (assetFilter !== "all") {
      result = result.filter(v => v.asset?.symbol === assetFilter);
    }

    // 搜索过滤
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      result = result.filter(
        v =>
          v.name.toLowerCase().includes(query) ||
          v.address.toLowerCase().includes(query) ||
          v.asset?.symbol?.toLowerCase().includes(query),
      );
    }

    // 排序
    result.sort((a, b) => {
      if (sortBy === "tvl") {
        return Number(BigInt(b.totalAssets || "0") - BigInt(a.totalAssets || "0"));
      } else if (sortBy === "users") {
        const aUsers = new Set(a.deposits?.map(d => d.user?.address) || []).size;
        const bUsers = new Set(b.deposits?.map(d => d.user?.address) || []).size;
        return bUsers - aUsers;
      }
      return 0;
    });

    return result;
  }, [vaults, statusFilter, assetFilter, searchQuery, sortBy]);

  // 获取所有资产类型
  const assetTypes = useMemo(() => {
    const types = new Set(vaults.map(v => v.asset?.symbol).filter(Boolean));
    return Array.from(types) as string[];
  }, [vaults]);

  // 切换金库选中状态
  const toggleVaultSelection = (vaultId: string) => {
    const newSelected = new Set(selectedVaults);
    if (newSelected.has(vaultId)) {
      newSelected.delete(vaultId);
    } else {
      newSelected.add(vaultId);
    }
    setSelectedVaults(newSelected);
  };

  // 批量操作
  const handleBatchAction = (action: "activate" | "deactivate" | "export") => {
    if (selectedVaults.size === 0) {
      alert("请先选择金库");
      return;
    }

    const confirmed = window.confirm(`确认对 ${selectedVaults.size} 个金库执行 ${action} 操作吗？`);
    if (!confirmed) return;

    // TODO: 实现批量操作逻辑
    console.log(`Batch ${action}:`, Array.from(selectedVaults));
    alert(`批量${action}功能开发中...`);
  };

  const formatAssets = (vault: Vault) => {
    const assets = formatUnits(BigInt(vault.totalAssets || "0"), vault.asset?.decimals || 18);
    return parseFloat(assets).toLocaleString(undefined, { maximumFractionDigits: 0 });
  };

  const heroRef = useRef<HTMLDivElement | null>(null);
  const permissionRef = useRef<HTMLDivElement | null>(null);
  const topCardsRef = useRef<HTMLDivElement | null>(null);
  const listRef = useRef<HTMLDivElement | null>(null);
  const detailRef = useRef<HTMLDivElement | null>(null);

  useGsapHeroIntro(heroRef);
  useGsapFadeReveal(permissionRef, ".enhanced-permission-line", [isAdmin]);
  useGsapStaggerReveal(topCardsRef, {
    selector: ".enhanced-top-card",
    deps: [selectedVaults.size, searchQuery, statusFilter, assetFilter],
  });
  useGsapFadeReveal(listRef, ".enhanced-vault-row", [
    filteredAndSortedVaults.length,
    searchQuery,
    statusFilter,
    assetFilter,
    sortBy,
  ]);
  useGsapFadeReveal(detailRef, ".enhanced-detail-card", [selectedVault?.id ?? "", selectedVaults.size]);

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="flex flex-col items-center gap-4">
          <span className="loading loading-spinner loading-lg text-primary"></span>
          <p className="text-lg opacity-70">加载管理后台...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="alert alert-error">
          <span>加载失败: {error.message}</span>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex justify-between items-center mb-8" ref={heroRef}>
        <div>
          <h1 className="hero-heading text-4xl font-bold mb-2">🔧 金库管理后台</h1>
          <div className="hero-subheading text-sm breadcrumbs">
            <ul>
              <li>
                <Link href="/">Home</Link>
              </li>
              <li>
                <Link href="/admin/vaults">Admin</Link>
              </li>
              <li>Enhanced Vault Management</li>
            </ul>
          </div>
        </div>
      </div>
      {/* Permission Check */}
      {!isAdmin && (
        <div className="alert alert-warning mb-8" ref={permissionRef}>
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
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
          <div className="enhanced-permission-line">
            <h3 className="font-bold">⚠️ 权限不足</h3>
            <div className="text-xs">请连接管理员钱包以执行管理操作</div>
          </div>
        </div>
      )}

      {/* Top Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8" ref={topCardsRef}>
        {/* Vault Creation */}
        <div className="lg:col-span-1">
          <div className="enhanced-top-card card bg-base-100 shadow-xl">
            <div className="card-body">
              <h2 className="card-title">🆕 创建金库</h2>
              <VaultCreationForm onVaultCreated={refetch} />
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="lg:col-span-1">
          <div className="enhanced-top-card card bg-base-100 shadow-xl">
            <div className="card-body">
              <h2 className="card-title">📊 快捷操作</h2>

              {selectedVaults.size > 0 && (
                <div className="bg-primary/10 p-3 rounded-lg mb-4">
                  <p className="font-semibold">选中 {selectedVaults.size} 个金库</p>
                  <div className="flex gap-2 mt-2 flex-wrap">
                    <button onClick={() => handleBatchAction("activate")} className="btn btn-xs btn-success">
                      ⚡ 批量激活
                    </button>
                    <button onClick={() => handleBatchAction("deactivate")} className="btn btn-xs btn-warning">
                      ⏸️ 批量暂停
                    </button>
                    <button onClick={() => handleBatchAction("export")} className="btn btn-xs btn-ghost">
                      📊 导出数据
                    </button>
                  </div>
                </div>
              )}

              <div className="divider">权限状态</div>
              <RoleDisplay showPermissions={true} />
            </div>
          </div>
        </div>

        {/* Selected Vault Actions */}
        <div className="lg:col-span-1" ref={detailRef}>
          {selectedVault ? (
            <div className="enhanced-detail-card">
              <AdminVaultActions vault={selectedVault} onSuccess={refetch} />
            </div>
          ) : (
            <div className="enhanced-detail-card card bg-base-100 shadow-xl">
              <div className="card-body items-center text-center">
                <p className="opacity-70">点击金库查看管理选项</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Vault List */}
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <h2 className="card-title mb-4">🏦 金库列表管理</h2>

          {/* Filters */}
          <div className="flex flex-wrap gap-4 mb-4">
            {/* Status Filter */}
            <select
              className="select select-bordered select-sm"
              value={statusFilter}
              onChange={e => setStatusFilter(e.target.value as any)}
            >
              <option value="all">全部状态</option>
              <option value="active">活跃</option>
              <option value="inactive">未激活</option>
            </select>

            {/* Asset Filter */}
            <select
              className="select select-bordered select-sm"
              value={assetFilter}
              onChange={e => setAssetFilter(e.target.value)}
            >
              <option value="all">全部资产</option>
              {assetTypes.map(asset => (
                <option key={asset} value={asset}>
                  {asset}
                </option>
              ))}
            </select>

            {/* Sort */}
            <select
              className="select select-bordered select-sm"
              value={sortBy}
              onChange={e => setSortBy(e.target.value as any)}
            >
              <option value="tvl">排序: TVL降序</option>
              <option value="apy">排序: APY降序</option>
              <option value="users">排序: 用户数降序</option>
            </select>

            {/* Search */}
            <input
              type="text"
              placeholder="🔍 搜索金库名称/地址..."
              className="input input-bordered input-sm flex-1 min-w-64"
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
            />
          </div>

          {/* Table */}
          <div className="overflow-x-auto" ref={listRef}>
            <table className="table table-zebra">
              <thead>
                <tr>
                  <th>
                    <input
                      type="checkbox"
                      className="checkbox checkbox-sm"
                      checked={
                        selectedVaults.size === filteredAndSortedVaults.length && filteredAndSortedVaults.length > 0
                      }
                      onChange={e => {
                        if (e.target.checked) {
                          setSelectedVaults(new Set(filteredAndSortedVaults.map(v => v.id)));
                        } else {
                          setSelectedVaults(new Set());
                        }
                      }}
                    />
                  </th>
                  <th>金库名称</th>
                  <th>资产</th>
                  <th>TVL</th>
                  <th>APY</th>
                  <th>用户</th>
                  <th>状态</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                {filteredAndSortedVaults.map(vault => {
                  const uniqueUsers = new Set(vault.deposits?.map(d => d.user?.address) || []).size;
                  return (
                    <tr
                      key={vault.id}
                      className={`enhanced-vault-row ${selectedVault?.id === vault.id ? "bg-primary/10" : ""}`}
                    >
                      <td>
                        <input
                          type="checkbox"
                          className="checkbox checkbox-sm"
                          checked={selectedVaults.has(vault.id)}
                          onChange={() => toggleVaultSelection(vault.id)}
                        />
                      </td>
                      <td>
                        <button onClick={() => setSelectedVault(vault)} className="font-semibold hover:text-primary">
                          {vault.name}
                        </button>
                      </td>
                      <td>
                        <span className="badge badge-outline">{vault.asset?.symbol || "N/A"}</span>
                      </td>
                      <td>${formatAssets(vault)}</td>
                      <td className="text-success font-semibold">8.5%</td>
                      <td>{uniqueUsers}</td>
                      <td>
                        {vault.isActive ? (
                          <span className="badge badge-success">🟢 活跃</span>
                        ) : (
                          <span className="badge badge-error">🔴 未激活</span>
                        )}
                      </td>
                      <td>
                        <div className="dropdown dropdown-end">
                          <label tabIndex={0} className="btn btn-ghost btn-xs">
                            管理 ▼
                          </label>
                          <ul
                            tabIndex={0}
                            className="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52"
                          >
                            <li>
                              <button onClick={() => setSelectedVault(vault)}>⚙️ 查看详情</button>
                            </li>
                            <li>
                              <Link href={`/admin/strategies`}>🎯 调整策略</Link>
                            </li>
                            <li>
                              <button>⏸️ 暂停金库</button>
                            </li>
                            <li>
                              <button>▶️ 重新激活</button>
                            </li>
                            <li className="divider"></li>
                            <li>
                              <button className="text-error">⚠️ 危险操作</button>
                            </li>
                          </ul>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>

            {filteredAndSortedVaults.length === 0 && (
              <div className="text-center py-8 opacity-70">
                <p>未找到匹配的金库</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default EnhancedAdminVaultsPage;
