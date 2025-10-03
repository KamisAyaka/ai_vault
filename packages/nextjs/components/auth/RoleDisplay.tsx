"use client";

import { useAccount } from "wagmi";
import { Address } from "~~/components/scaffold-eth";
import { useUserRole } from "~~/hooks/useUserRole";

type RoleDisplayProps = {
  vaultAddress?: string;
  showPermissions?: boolean;
  managerAddress?: string | null;
  factoryOwnerAddress?: string | null;
  aiAgentAddresses?: string[];
};

export const RoleDisplay = ({
  vaultAddress,
  showPermissions = false,
  managerAddress,
  factoryOwnerAddress,
  aiAgentAddresses,
}: RoleDisplayProps) => {
  const { address: connectedAddress } = useAccount();
  const { permissions, getRoleBadge, getRoleDescription } = useUserRole(vaultAddress, {
    managerAddress,
    factoryOwnerAddress,
    aiAgentAddresses,
  });

  if (!connectedAddress) {
    return (
      <div className="card bg-base-200 p-4">
        <p className="text-sm opacity-70">未连接钱包</p>
      </div>
    );
  }

  const badge = getRoleBadge();

  return (
    <div className="card bg-base-100 shadow-md">
      <div className="card-body">
        <div className="flex justify-between items-start mb-3">
          <div>
            <h3 className="font-semibold mb-1">当前角色</h3>
            <span className={`badge ${badge.className}`}>{badge.text}</span>
          </div>
          <div className="text-right">
            <p className="text-xs opacity-70 mb-1">当前地址</p>
            <Address address={connectedAddress} size="sm" />
          </div>
        </div>

        <p className="text-sm opacity-70 mb-3">{getRoleDescription()}</p>

        {showPermissions && (
          <>
            <div className="divider my-2"></div>
            <div>
              <p className="text-sm font-semibold mb-2">权限列表:</p>
              <div className="grid grid-cols-2 gap-2 text-xs">
                {permissions.canManageFactory && (
                  <div className="flex items-center gap-1">
                    <span className="text-success">✓</span>
                    <span>管理工厂</span>
                  </div>
                )}
                {permissions.canCreateVault && (
                  <div className="flex items-center gap-1">
                    <span className="text-success">✓</span>
                    <span>创建金库</span>
                  </div>
                )}
                {permissions.canManageVault && (
                  <div className="flex items-center gap-1">
                    <span className="text-success">✓</span>
                    <span>管理金库</span>
                  </div>
                )}
                {permissions.canUpdateStrategy && (
                  <div className="flex items-center gap-1">
                    <span className="text-success">✓</span>
                    <span>更新策略</span>
                  </div>
                )}
                {permissions.canActivateVault && (
                  <div className="flex items-center gap-1">
                    <span className="text-success">✓</span>
                    <span>激活金库</span>
                  </div>
                )}
                {permissions.canDeactivateVault && (
                  <div className="flex items-center gap-1">
                    <span className="text-success">✓</span>
                    <span>停用金库</span>
                  </div>
                )}
                {permissions.canExecuteAIStrategy && (
                  <div className="flex items-center gap-1">
                    <span className="text-success">✓</span>
                    <span>执行 AI 策略</span>
                  </div>
                )}
                {permissions.canManageAIAgents && (
                  <div className="flex items-center gap-1">
                    <span className="text-success">✓</span>
                    <span>管理 AI 代理</span>
                  </div>
                )}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};
