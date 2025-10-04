import { useMemo } from "react";
import { useScaffoldReadContract } from "./scaffold-eth";
import { useAccount } from "wagmi";

export type UserRole = "owner" | "manager" | "ai_agent" | "user";

type UseUserRoleOptions = {
  managerAddress?: string | null;
  aiAgentAddresses?: string[];
  factoryOwnerAddress?: string | null;
};

export const useUserRole = (vaultAddress?: string, options: UseUserRoleOptions = {}) => {
  const { address: connectedAddress } = useAccount();

  // 读取工厂合约所有者
  const { data: factoryOwner } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "owner",
  });

  const role = useMemo<UserRole>(() => {
    if (!connectedAddress) return "user";

    const lowerAddress = connectedAddress.toLowerCase();
    const factoryOwnerAddress = options.factoryOwnerAddress?.toLowerCase() ?? factoryOwner?.toLowerCase();
    const managerAddress = options.managerAddress?.toLowerCase();
    const aiAgentAddresses = options.aiAgentAddresses?.map(address => address.toLowerCase()) ?? [];

    // 检查是否为工厂所有者
    if (factoryOwnerAddress && factoryOwnerAddress === lowerAddress) {
      return "owner";
    }

    // 检查是否为金库管理员
    if (vaultAddress && managerAddress && managerAddress === lowerAddress) {
      return "manager";
    }

    // 检查是否为 AI 代理
    if (vaultAddress && aiAgentAddresses.includes(lowerAddress)) {
      return "ai_agent";
    }

    return "user";
  }, [
    connectedAddress,
    factoryOwner,
    options.factoryOwnerAddress,
    options.managerAddress,
    options.aiAgentAddresses,
    vaultAddress,
  ]);

  const permissions = useMemo(() => {
    return {
      // 工厂级权限
      canCreateVault: role === "owner",
      canManageFactory: role === "owner",

      // 金库级权限
      canManageVault: role === "owner" || role === "manager",
      canActivateVault: role === "owner" || role === "manager",
      canDeactivateVault: role === "owner" || role === "manager",
      canUpdateFees: role === "owner" || role === "manager",
      canSetManager: role === "owner",

      // 策略权限
      canUpdateStrategy: role === "owner" || role === "manager" || role === "ai_agent",
      canViewStrategies: role === "owner" || role === "manager" || role === "ai_agent",

      // AI 代理权限
      canManageAIAgents: role === "owner" || role === "manager",
      canExecuteAIStrategy: role === "ai_agent",

      // 用户权限
      canDeposit: true,
      canWithdraw: true,
      canViewVault: true,
    };
  }, [role]);

  const getRoleBadge = () => {
    switch (role) {
      case "owner":
        return { text: "👑 所有者", className: "badge-error" };
      case "manager":
        return { text: "🔧 管理员", className: "badge-warning" };
      case "ai_agent":
        return { text: "🤖 AI 代理", className: "badge-info" };
      default:
        return { text: "👤 用户", className: "badge-ghost" };
    }
  };

  const getRoleDescription = () => {
    switch (role) {
      case "owner":
        return "拥有所有权限，可以管理工厂和所有金库";
      case "manager":
        return "可以管理指定金库的配置和策略";
      case "ai_agent":
        return "可以执行自动化投资策略";
      default:
        return "可以存款、提款和查看金库信息";
    }
  };

  return {
    role,
    permissions,
    getRoleBadge,
    getRoleDescription,
    isOwner: role === "owner",
    isManager: role === "manager",
    isAIAgent: role === "ai_agent",
    isUser: role === "user",
  };
};
