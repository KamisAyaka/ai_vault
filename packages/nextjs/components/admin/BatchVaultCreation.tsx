"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

type VaultCreationData = {
  id: string;
  name: string;
  assetAddress: string;
  assetSymbol: string;
  decimals: number;
  managementFee: string; // basis points
  status: "pending" | "validating" | "creating" | "success" | "error";
  error?: string;
};

type BatchVaultCreationProps = {
  onSuccess?: () => void;
};

export const BatchVaultCreation = ({ onSuccess }: BatchVaultCreationProps) => {
  const { address: connectedAddress } = useAccount();
  const [vaults, setVaults] = useState<VaultCreationData[]>([
    { id: "1", name: "", assetAddress: "", assetSymbol: "", decimals: 18, managementFee: "100", status: "pending" },
  ]);
  const [isCreating, setIsCreating] = useState(false);
  const [csvInput, setCsvInput] = useState("");

  const { writeContractAsync: createVaultsBatchAsync } = useScaffoldWriteContract({
    contractName: "VaultFactory",
  });

  // 添加新行
  const addVaultRow = () => {
    setVaults([
      ...vaults,
      {
        id: Date.now().toString(),
        name: "",
        assetAddress: "",
        assetSymbol: "",
        decimals: 18,
        managementFee: "100",
        status: "pending",
      },
    ]);
  };

  // 删除行
  const removeVaultRow = (id: string) => {
    setVaults(vaults.filter(v => v.id !== id));
  };

  // 更新行数据
  const updateVault = (id: string, field: keyof VaultCreationData, value: any) => {
    setVaults(vaults.map(v => (v.id === id ? { ...v, [field]: value } : v)));
  };

  // 从CSV导入
  const importFromCSV = () => {
    if (!csvInput.trim()) {
      notification.error("请输入CSV数据");
      return;
    }

    try {
      const lines = csvInput.trim().split("\n");
      const newVaults: VaultCreationData[] = [];

      lines.forEach((line, index) => {
        // 跳过标题行
        if (index === 0 && line.toLowerCase().includes("name")) return;

        const [name, assetAddress, assetSymbol, decimals, feeBps] = line.split(",").map(s => s.trim());

        if (name && assetAddress) {
          newVaults.push({
            id: Date.now().toString() + index,
            name,
            assetAddress,
            assetSymbol: assetSymbol || "TOKEN",
            decimals: parseInt(decimals) || 18,
            managementFee: feeBps || "100",
            status: "pending",
          });
        }
      });

      if (newVaults.length > 0) {
        setVaults(newVaults);
        setCsvInput("");
        notification.success(`成功导入 ${newVaults.length} 个金库配置`);
      } else {
        notification.error("未找到有效的金库配置");
      }
    } catch (error) {
      console.error("CSV解析失败:", error);
      notification.error("CSV格式错误");
    }
  };

  // 验证单个金库
  const validateVault = (vault: VaultCreationData): boolean => {
    if (!vault.name.trim()) {
      updateVault(vault.id, "error", "金库名称不能为空");
      updateVault(vault.id, "status", "error");
      return false;
    }

    if (!vault.assetAddress.match(/^0x[a-fA-F0-9]{40}$/)) {
      updateVault(vault.id, "error", "无效的资产地址");
      updateVault(vault.id, "status", "error");
      return false;
    }

    if (vault.decimals < 1 || vault.decimals > 18) {
      updateVault(vault.id, "error", "Decimals 必须在 1-18 之间");
      updateVault(vault.id, "status", "error");
      return false;
    }

    const feeValue = Number(vault.managementFee);
    if (Number.isNaN(feeValue) || feeValue < 0 || feeValue > 10000) {
      updateVault(vault.id, "error", "管理费应在 0-10000 基点之间");
      updateVault(vault.id, "status", "error");
      return false;
    }

    return true;
  };

  // 批量创建金库
  const handleBatchCreate = async () => {
    if (!connectedAddress) {
      notification.error("请先连接钱包");
      return;
    }

    if (vaults.length === 0) {
      notification.error("请至少添加一个金库");
      return;
    }

    // 验证所有金库
    let allValid = true;
    for (const vault of vaults) {
      updateVault(vault.id, "status", "validating");
      if (!validateVault(vault)) {
        allValid = false;
      } else {
        updateVault(vault.id, "status", "pending");
      }
    }

    if (!allValid) {
      notification.error("部分金库配置无效，请检查");
      return;
    }

    setIsCreating(true);

    try {
      // 准备批量创建参数
      const assets = vaults.map(v => v.assetAddress as `0x${string}`);
      const names = vaults.map(v => v.name);
      const symbols = vaults.map(v => `v${v.assetSymbol}`);
      const fees = vaults.map(v => BigInt(Number(v.managementFee)));

      // 设置所有金库为创建中状态
      vaults.forEach(v => updateVault(v.id, "status", "creating"));

      // 调用批量创建合约
      await createVaultsBatchAsync(
        {
          functionName: "createVaultsBatch",
          args: [assets, names, symbols, fees],
        },
        {
          onBlockConfirmation: receipt => {
            console.debug("Batch vaults created", receipt);
            notification.success(`成功创建 ${vaults.length} 个金库！`);

            // 设置所有金库为成功状态
            vaults.forEach(v => updateVault(v.id, "status", "success"));

            // 延迟后清空表单
            setTimeout(() => {
              setVaults([
                {
                  id: Date.now().toString(),
                  name: "",
                  assetAddress: "",
                  assetSymbol: "",
                  decimals: 18,
                  managementFee: "100",
                  status: "pending",
                },
              ]);
              onSuccess?.();
            }, 2000);
          },
        },
      );
    } catch (error: any) {
      console.error("Batch vault creation failed:", error);
      notification.error(error?.message || "批量创建失败");

      // 设置所有金库为错误状态
      vaults.forEach(v => {
        updateVault(v.id, "status", "error");
        updateVault(v.id, "error", error?.message || "创建失败");
      });
    } finally {
      setIsCreating(false);
    }
  };

  const getStatusBadge = (status: VaultCreationData["status"]) => {
    switch (status) {
      case "pending":
        return <span className="badge badge-ghost">待处理</span>;
      case "validating":
        return <span className="badge badge-info">验证中...</span>;
      case "creating":
        return <span className="badge badge-warning">创建中...</span>;
      case "success":
        return <span className="badge badge-success">✅ 成功</span>;
      case "error":
        return <span className="badge badge-error">❌ 失败</span>;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* CSV Import Section */}
      <div className="card bg-base-100 shadow-md">
        <div className="card-body">
          <h3 className="card-title text-lg">📄 CSV 快速导入</h3>
          <p className="text-sm opacity-70 mb-2">格式: name,assetAddress,assetSymbol,decimals,managementFeeBps</p>
          <div className="form-control">
            <textarea
              className="textarea textarea-bordered h-24 font-mono text-xs"
              placeholder="USDC Vault,0x1234567890123456789012345678901234567890,USDC,6,100&#10;WETH Vault,0xabcdef0123456789abcdef0123456789abcdef01,WETH,18,50"
              value={csvInput}
              onChange={e => setCsvInput(e.target.value)}
            />
          </div>
          <div className="card-actions justify-end mt-2">
            <button onClick={importFromCSV} className="btn btn-sm btn-primary">
              📥 导入 CSV
            </button>
          </div>
        </div>
      </div>

      {/* Vault Table */}
      <div className="card bg-base-100 shadow-md">
        <div className="card-body">
          <h3 className="card-title text-lg mb-4">🏦 批量金库配置</h3>

          <div className="overflow-x-auto">
            <table className="table table-sm">
              <thead>
                <tr>
                  <th>状态</th>
                  <th>金库名称</th>
                  <th>资产地址</th>
                  <th>符号</th>
                  <th>Decimals</th>
                  <th>管理费率 (bps)</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                {vaults.map(vault => (
                  <tr key={vault.id} className={vault.status === "error" ? "bg-error/10" : ""}>
                    <td>{getStatusBadge(vault.status)}</td>
                    <td>
                      <input
                        type="text"
                        className="input input-xs input-bordered w-full"
                        placeholder="USDC Vault"
                        value={vault.name}
                        onChange={e => updateVault(vault.id, "name", e.target.value)}
                        disabled={isCreating}
                      />
                    </td>
                    <td>
                      <input
                        type="text"
                        className="input input-xs input-bordered w-full font-mono"
                        placeholder="0x..."
                        value={vault.assetAddress}
                        onChange={e => updateVault(vault.id, "assetAddress", e.target.value)}
                        disabled={isCreating}
                      />
                    </td>
                    <td>
                      <input
                        type="text"
                        className="input input-xs input-bordered w-20"
                        placeholder="USDC"
                        value={vault.assetSymbol}
                        onChange={e => updateVault(vault.id, "assetSymbol", e.target.value)}
                        disabled={isCreating}
                      />
                    </td>
                    <td>
                      <input
                        type="number"
                        className="input input-xs input-bordered w-16"
                        value={vault.decimals}
                        onChange={e => updateVault(vault.id, "decimals", parseInt(e.target.value) || 18)}
                        disabled={isCreating}
                        min="1"
                        max="18"
                      />
                    </td>
                    <td>
                      <input
                        type="number"
                        className="input input-xs input-bordered w-24"
                        placeholder="100"
                        value={vault.managementFee}
                        onChange={e => updateVault(vault.id, "managementFee", e.target.value)}
                        disabled={isCreating}
                        min="0"
                        max="10000"
                      />
                    </td>
                    <td>
                      <button
                        onClick={() => removeVaultRow(vault.id)}
                        className="btn btn-xs btn-ghost btn-circle"
                        disabled={isCreating || vaults.length === 1}
                      >
                        ✕
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Error Messages */}
          {vaults.some(v => v.error) && (
            <div className="alert alert-error mt-4">
              <div>
                <h4 className="font-bold">验证错误:</h4>
                <ul className="list-disc list-inside text-sm">
                  {vaults
                    .filter(v => v.error)
                    .map(v => (
                      <li key={v.id}>
                        {v.name || "未命名"}: {v.error}
                      </li>
                    ))}
                </ul>
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex justify-between items-center mt-4">
            <button onClick={addVaultRow} className="btn btn-sm btn-outline" disabled={isCreating}>
              ➕ 添加金库
            </button>

            <div className="flex gap-2">
              <div className="text-sm opacity-70 self-center">共 {vaults.length} 个金库</div>
              <button
                onClick={handleBatchCreate}
                disabled={isCreating || vaults.length === 0}
                className="btn btn-sm btn-primary"
              >
                {isCreating ? (
                  <>
                    <span className="loading loading-spinner loading-sm"></span>
                    创建中...
                  </>
                ) : (
                  `🚀 批量创建 ${vaults.length} 个金库`
                )}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Info Notice */}
      <div className="alert alert-info">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          className="stroke-current shrink-0 w-6 h-6"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          ></path>
        </svg>
        <div className="text-sm">
          <p className="font-semibold">💡 提示</p>
          <ul className="list-disc list-inside opacity-80 mt-1">
            <li>确保所有资产地址有效且已部署</li>
            <li>Decimals 通常为 18 (ETH/WETH), 6 (USDC/USDT), 18 (DAI)</li>
            <li>管理费采用基点表示，例如 100 = 1%</li>
            <li>批量创建使用单笔交易，节省 Gas 费用</li>
          </ul>
        </div>
      </div>
    </div>
  );
};
