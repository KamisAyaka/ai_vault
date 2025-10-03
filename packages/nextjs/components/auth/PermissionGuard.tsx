"use client";

import { useAccount } from "wagmi";
import { useUserRole } from "~~/hooks/useUserRole";

type PermissionGuardProps = {
  children: React.ReactNode;
  requiredRole?: "owner" | "manager" | "ai_agent";
  vaultAddress?: string;
  fallback?: React.ReactNode;
  showMessage?: boolean;
  managerAddress?: string | null;
  factoryOwnerAddress?: string | null;
  aiAgentAddresses?: string[];
};

export const PermissionGuard = ({
  children,
  requiredRole,
  vaultAddress,
  fallback,
  showMessage = true,
  managerAddress,
  factoryOwnerAddress,
  aiAgentAddresses,
}: PermissionGuardProps) => {
  const { address: connectedAddress } = useAccount();
  const { role, getRoleBadge } = useUserRole(vaultAddress, {
    managerAddress,
    factoryOwnerAddress,
    aiAgentAddresses,
  });

  // 如果未连接钱包
  if (!connectedAddress) {
    if (fallback) return <>{fallback}</>;

    if (showMessage) {
      return (
        <div className="alert alert-warning">
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
          <span>请先连接钱包</span>
        </div>
      );
    }

    return null;
  }

  // 角色权限检查
  const hasPermission = () => {
    if (!requiredRole) return true;

    const roleHierarchy = {
      owner: 3,
      manager: 2,
      ai_agent: 1,
      user: 0,
    };

    return roleHierarchy[role] >= roleHierarchy[requiredRole];
  };

  if (!hasPermission()) {
    if (fallback) return <>{fallback}</>;

    if (showMessage) {
      const badge = getRoleBadge();
      return (
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
          <div>
            <h3 className="font-bold">权限不足</h3>
            <div className="text-sm">
              当前角色: <span className={`badge ${badge.className} badge-sm`}>{badge.text}</span>
              <br />
              需要角色: {requiredRole === "owner" && "👑 所有者"}
              {requiredRole === "manager" && "🔧 管理员"}
              {requiredRole === "ai_agent" && "🤖 AI 代理"}
            </div>
          </div>
        </div>
      );
    }

    return null;
  }

  return <>{children}</>;
};

// 快捷组件
export const OwnerOnly = ({ children, ...props }: Omit<PermissionGuardProps, "requiredRole">) => (
  <PermissionGuard requiredRole="owner" {...props}>
    {children}
  </PermissionGuard>
);

export const ManagerOnly = ({ children, ...props }: Omit<PermissionGuardProps, "requiredRole">) => (
  <PermissionGuard requiredRole="manager" {...props}>
    {children}
  </PermissionGuard>
);

export const AIAgentOnly = ({ children, ...props }: Omit<PermissionGuardProps, "requiredRole">) => (
  <PermissionGuard requiredRole="ai_agent" {...props}>
    {children}
  </PermissionGuard>
);
