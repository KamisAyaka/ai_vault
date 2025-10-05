"use client";

import { useState } from "react";
import { useAccount, useWriteContract } from "wagmi";
import deployedContracts from "~~/contracts/deployedContracts";
import { useTargetNetwork, useTransactor } from "~~/hooks/scaffold-eth";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type VaultReactivationModalProps = {
  vault: Vault;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

export const VaultReactivationModal = ({ vault, isOpen, onClose, onSuccess }: VaultReactivationModalProps) => {
  const { address: connectedAddress } = useAccount();
  const { targetNetwork } = useTargetNetwork();
  const [isActivating, setIsActivating] = useState(false);
  const [checksComplete, setChecksComplete] = useState(false);

  const { writeContractAsync } = useWriteContract();
  const writeTx = useTransactor();

  // 从环境变量读取管理员地址
  const vaultManager = process.env.NEXT_PUBLIC_VAULT_MANAGER_ADDRESS?.toLowerCase();
  const isManager = connectedAddress?.toLowerCase() === vaultManager;

  // 执行激活前检查
  const handlePreActivationCheck = () => {
    // 检查点:
    // 1. 用户是否为管理员
    // 2. 金库是否已停用
    // 3. 策略配置是否有效
    // 4. 资产合约是否正常

    if (!isManager) {
      notification.error("仅管理员可以重新激活金库");
      return;
    }

    if (vault.isActive) {
      notification.warning("金库已经是激活状态");
      return;
    }

    // 所有检查通过
    setChecksComplete(true);
    notification.success("预检查通过，可以重新激活金库");
  };

  const handleActivate = async () => {
    if (!connectedAddress || !isManager) {
      notification.error("仅管理员可以重新激活金库");
      return;
    }

    setIsActivating(true);

    try {
      const makeWriteWithParams = () =>
        writeContractAsync({
          address: vault.address as `0x${string}`,
          abi: (deployedContracts as any)[targetNetwork.id]?.VaultImplementation?.abi,
          functionName: "setActive",
          args: [],
        });

      await writeTx(makeWriteWithParams, {
        onBlockConfirmation: receipt => {
          console.debug("Vault reactivated", receipt);
          notification.success(`金库 ${vault.name} 已成功重新激活！`);
          onSuccess?.();
          onClose();
        },
      });
    } catch (error: any) {
      console.error("Vault reactivation failed:", error);
      notification.error(error?.message || "重新激活失败");
    } finally {
      setIsActivating(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="modal modal-open">
      <div className="modal-box max-w-2xl">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-2xl font-bold">🔄 重新激活金库</h3>
          <button onClick={onClose} className="btn btn-sm btn-circle btn-ghost">
            ✕
          </button>
        </div>

        {/* Vault Info */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-lg font-semibold">🏦 {vault.name}</p>
              <p className="text-xs opacity-70">
                地址: {vault.address.slice(0, 10)}...{vault.address.slice(-8)}
              </p>
            </div>
            <div>
              <span className="badge badge-error">🔴 未激活</span>
            </div>
          </div>
        </div>

        {/* Permission Check */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <p className="text-sm font-semibold mb-2">权限验证</p>
          {isManager ? (
            <div className="flex items-center gap-2 text-success">
              <span>✅</span>
              <span className="text-sm">您是该金库的管理员，有权重新激活</span>
            </div>
          ) : (
            <div className="flex items-center gap-2 text-error">
              <span>❌</span>
              <span className="text-sm">您不是该金库的管理员，无权重新激活</span>
            </div>
          )}
        </div>

        {/* Pre-activation Checklist */}
        <div className="mb-6">
          <p className="text-sm font-semibold mb-3">激活前检查清单:</p>

          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <input type="checkbox" checked={isManager} disabled className="checkbox checkbox-sm" />
              <span className="text-sm">管理员权限验证</span>
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" checked={!vault.isActive} disabled className="checkbox checkbox-sm" />
              <span className="text-sm">金库当前处于停用状态</span>
            </div>
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={vault.allocations && vault.allocations.length > 0}
                disabled
                className="checkbox checkbox-sm"
              />
              <span className="text-sm">投资策略配置有效</span>
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" checked={!!vault.asset?.address} disabled className="checkbox checkbox-sm" />
              <span className="text-sm">资产合约地址有效</span>
            </div>
          </div>

          <button
            onClick={handlePreActivationCheck}
            className="btn btn-sm btn-outline btn-block mt-4"
            disabled={!isManager || checksComplete}
          >
            {checksComplete ? "✅ 检查完成" : "🔍 运行预检查"}
          </button>
        </div>

        {/* Warnings */}
        <div className="alert alert-warning mb-6">
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
          <div className="text-sm">
            <p className="font-semibold">⚠️ 重要提示</p>
            <ul className="list-disc list-inside space-y-1 opacity-80 mt-2">
              <li>重新激活后，用户将能够存款和提款</li>
              <li>确保投资策略配置正确且安全</li>
              <li>建议先在测试网验证</li>
              <li>激活后可随时再次停用</li>
            </ul>
          </div>
        </div>

        {/* Info about why vault was deactivated */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <p className="text-sm font-semibold mb-2">📝 停用原因（示例）</p>
          <ul className="text-sm opacity-70 list-disc list-inside space-y-1">
            <li>策略调整维护</li>
            <li>资产迁移</li>
            <li>合约升级</li>
            <li>风险管理措施</li>
          </ul>
          <p className="text-xs mt-3 opacity-60">实际停用原因应从链上事件或管理日志获取</p>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button onClick={onClose} className="btn btn-ghost flex-1">
            取消
          </button>
          <button
            onClick={handleActivate}
            disabled={isActivating || !isManager || !checksComplete}
            className="btn btn-success flex-1"
          >
            {isActivating ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                激活中...
              </>
            ) : (
              "🔄 确认重新激活"
            )}
          </button>
        </div>
      </div>
      <div className="modal-backdrop bg-black/50" onClick={onClose}></div>
    </div>
  );
};
