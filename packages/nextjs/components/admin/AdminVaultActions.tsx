"use client";

import { useMemo, useState } from "react";
import { isAddress } from "viem";
import { useAccount, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type AdminVaultActionsProps = {
  vault: Vault;
  onSuccess?: () => void;
};

export const AdminVaultActions = ({ vault, onSuccess }: AdminVaultActionsProps) => {
  const [isToggling, setIsToggling] = useState(false);
  const t = useTranslations();

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
      notification.info(t("adminVaultActions.messages.alreadyInactive"));
      return;
    }

    const confirmed = window.confirm(t("adminVaultActions.messages.confirmDeactivate", { vault: vault.name }));

    if (!confirmed) return;

    if (!isManager) {
      notification.error(t("adminVaultActions.messages.onlyManager"));
      return;
    }

    if (!vaultContractInfo?.abi) {
      notification.error(t("adminVaultActions.messages.abiMissing"));
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
          notification.success(t("adminVaultActions.messages.deactivateSuccess", { vault: vault.name }));
          onSuccess?.();
        },
      });
    } catch (error: any) {
      console.error("Failed to deactivate vault:", error);
      notification.error(error?.message || t("adminVaultActions.messages.deactivateFailed"));
    } finally {
      setIsToggling(false);
    }
  };

  return (
    <div className="card bg-base-200 shadow-md">
      <div className="card-body">
        <h3 className="card-title text-lg">{t("adminVaultActions.title")}</h3>

        <div className="space-y-4">
          {/* Vault Status */}
          <div className="flex justify-between items-center">
            <div>
              <p className="font-semibold">{t("adminVaultActions.status.label")}</p>
              <p className="text-sm opacity-70">
                {vault.isActive ? t("adminVaultActions.status.accepting") : t("adminVaultActions.status.disabled")}
              </p>
              {!isManager && <p className="text-xs text-warning mt-1">{t("adminVaultActions.connectWarning")}</p>}
            </div>
            <button
              onClick={handleDeactivateVault}
              disabled={isToggling || !vault.isActive || !isManager}
              className="btn btn-sm btn-error"
            >
              {isToggling ? (
                <>
                  <span className="loading loading-spinner loading-xs"></span>
                  {t("adminVaultActions.buttons.processing")}
                </>
              ) : vault.isActive ? (
                t("adminVaultActions.buttons.deactivate")
              ) : (
                t("adminVaultActions.buttons.alreadyInactive")
              )}
            </button>
          </div>

          {/* Manager Info */}
          <div className="divider my-2"></div>
          <div>
            <p className="font-semibold mb-2">{t("adminVaultActions.managerInfo.label")}</p>
            <div className="text-sm space-y-1">
              <p>
                <span className="opacity-70">{t("adminVaultActions.managerInfo.manager")}</span>{" "}
                <code className="bg-base-300 px-2 py-1 rounded">{formattedManager}</code>
              </p>
              <p>
                <span className="opacity-70">{t("adminVaultActions.managerInfo.owner")}</span>{" "}
                <code className="bg-base-300 px-2 py-1 rounded">{formattedOwner}</code>
              </p>
            </div>
          </div>

          {/* Allocation Summary */}
          {vault.allocations && vault.allocations.length > 0 && (
            <>
              <div className="divider my-2"></div>
              <div>
                <p className="font-semibold mb-2">{t("adminVaultActions.allocations")}</p>
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
