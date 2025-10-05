"use client";

import { useMemo, useState } from "react";
import { isAddress } from "viem";
import { useAccount, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type AdminVaultActionsProps = {
  vault: Vault;
  onSuccess?: () => void;
};

export const AdminVaultActions = ({ vault, onSuccess }: AdminVaultActionsProps) => {
  const [isToggling, setIsToggling] = useState(false);

  const { address: connectedAddress } = useAccount();

  const managerAddress = vault.manager?.address ?? "";
  const normalizedManager = managerAddress.toLowerCase();
  const isManager = connectedAddress && managerAddress ? connectedAddress.toLowerCase() === normalizedManager : false;

  const { data: vaultContractInfo } = useDeployedContractInfo({
    contractName: "VaultImplementation",
  });

  const { writeContractAsync } = useWriteContract();
  const writeTx = useTransactor();

  const formattedManager = useMemo(() => {
    if (!managerAddress || !isAddress(managerAddress as `0x${string}`)) return "Unavailable";
    return `${managerAddress.slice(0, 6)}…${managerAddress.slice(-4)}`;
  }, [managerAddress]);

  const formattedOwner = useMemo(() => {
    const owner = vault.manager?.owner ?? "";
    if (!owner || !isAddress(owner as `0x${string}`)) return "Unavailable";
    return `${owner.slice(0, 6)}…${owner.slice(-4)}`;
  }, [vault.manager?.owner]);

  const handleDeactivateVault = async () => {
    if (!vault.isActive) {
      notification.info("Vault is already inactive.");
      return;
    }

    const confirmed = window.confirm(
      `Deactivate "${vault.name}"?\n\nThis prevents new deposits but allows existing users to withdraw.`,
    );

    if (!confirmed) return;

    if (!isManager) {
      notification.error("Only the vault manager can deactivate this vault.");
      return;
    }

    if (!vaultContractInfo?.abi) {
      notification.error("Vault contract ABI not available");
      return;
    }

    setIsToggling(true);

    try {
      const makeWriteWithParams = () =>
        writeContractAsync({
          address: vault.address as `0x${string}`,
          abi: vaultContractInfo.abi,
          functionName: "setNotActive",
        });

      await writeTx(makeWriteWithParams, {
        onBlockConfirmation: () => {
          notification.success(`Vault "${vault.name}" deactivated.`);
          onSuccess?.();
        },
      });
    } catch (error: any) {
      console.error("Failed to deactivate vault:", error);
      notification.error(error?.message || "Failed to deactivate vault");
    } finally {
      setIsToggling(false);
    }
  };

  return (
    <div className="card bg-base-200 shadow-md">
      <div className="card-body">
        <h3 className="card-title text-lg">🔧 Admin Actions</h3>

        <div className="space-y-4">
          {/* Vault Status */}
          <div className="flex justify-between items-center">
            <div>
              <p className="font-semibold">Vault Status</p>
              <p className="text-sm opacity-70">
                {vault.isActive ? "Currently accepting deposits" : "Deposits disabled"}
              </p>
              {!isManager && (
                <p className="text-xs text-warning mt-1">
                  Connect with the vault manager wallet to perform admin actions.
                </p>
              )}
            </div>
            <button
              onClick={handleDeactivateVault}
              disabled={isToggling || !vault.isActive || !isManager}
              className="btn btn-sm btn-error"
            >
              {isToggling ? (
                <>
                  <span className="loading loading-spinner loading-xs"></span>
                  Processing...
                </>
              ) : vault.isActive ? (
                "Deactivate Vault"
              ) : (
                "Already Inactive"
              )}
            </button>
          </div>

          {/* Manager Info */}
          <div className="divider my-2"></div>
          <div>
            <p className="font-semibold mb-2">Manager Information</p>
            <div className="text-sm space-y-1">
              <p>
                <span className="opacity-70">Manager:</span>{" "}
                <code className="bg-base-300 px-2 py-1 rounded">{formattedManager}</code>
              </p>
              <p>
                <span className="opacity-70">Owner:</span>{" "}
                <code className="bg-base-300 px-2 py-1 rounded">{formattedOwner}</code>
              </p>
            </div>
          </div>

          {/* Allocation Summary */}
          {vault.allocations && vault.allocations.length > 0 && (
            <>
              <div className="divider my-2"></div>
              <div>
                <p className="font-semibold mb-2">Investment Allocations</p>
                <div className="space-y-1">
                  {vault.allocations.map((allocation, index) => (
                    <div key={index} className="flex justify-between text-sm bg-base-300 p-2 rounded">
                      <span>{allocation.adapterType}</span>
                      <span className="font-semibold">
                        {((Number(allocation.allocation) / 1000) * 100).toFixed(1)}%
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
};
