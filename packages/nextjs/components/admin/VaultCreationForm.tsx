"use client";

import { useState } from "react";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import { notification } from "~~/utils/scaffold-eth";

interface VaultCreationFormProps {
  onVaultCreated?: () => void;
}

export const VaultCreationForm = ({ onVaultCreated }: VaultCreationFormProps) => {
  const [asset, setAsset] = useState("");
  const [vaultName, setVaultName] = useState("");
  const [vaultSymbol, setVaultSymbol] = useState("");
  const [fee, setFee] = useState("100"); // Default 1% (100 basis points)
  const [isCreating, setIsCreating] = useState(false);
  const [checkingVault, setCheckingVault] = useState(false);
  const t = useTranslations();

  const { writeContractAsync: createVaultAsync } = useScaffoldWriteContract("VaultFactory");

  // Check if vault already exists for this asset
  const { data: existingVault } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "getVault",
    args: [asset || "0x0000000000000000000000000000000000000000"],
  });

  const { data: hasVault } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "hasVault",
    args: [asset || "0x0000000000000000000000000000000000000000"],
  });

  const handleCheckVault = async () => {
    if (!asset) {
      notification.error(t("adminVaultCreation.messages.addressRequired"));
      return;
    }
    setCheckingVault(true);
    // The useScaffoldReadContract will automatically fetch
    setTimeout(() => setCheckingVault(false), 500);
  };

  const handleCreateVault = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!asset || !vaultName || !vaultSymbol || !fee) {
      notification.error(t("adminVaultCreation.messages.fillAllFields"));
      return;
    }

    if (hasVault) {
      notification.error(t("adminVaultCreation.messages.vaultExists"));
      return;
    }

    setIsCreating(true);

    try {
      await createVaultAsync({
        functionName: "createVault",
        args: [asset, vaultName, vaultSymbol, BigInt(fee)],
      });

      notification.success(t("adminVaultCreation.messages.createSuccess"));

      // Reset form
      setAsset("");
      setVaultName("");
      setVaultSymbol("");
      setFee("100");

      // Call the callback if provided
      onVaultCreated?.();
    } catch (error: any) {
      console.error("Failed to create vault:", error);
      notification.error(error?.message || t("adminVaultCreation.messages.createFailed"));
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <h2 className="card-title text-2xl mb-4">{t("adminVaultCreation.title")}</h2>

        <form onSubmit={handleCreateVault} className="space-y-4">
          {/* Asset Address */}
          <div className="form-control">
            <label className="label">
              <span className="label-text font-semibold">{t("adminVaultCreation.assetAddress.label")}</span>
              <span className="label-text-alt text-error">{t("adminVaultCreation.assetAddress.required")}</span>
            </label>
            <div className="join w-full">
              <input
                type="text"
                value={asset}
                onChange={e => setAsset(e.target.value)}
                placeholder={t("adminVaultCreation.assetAddress.placeholder")}
                className="input input-bordered join-item w-full"
                required
              />
              <button
                type="button"
                onClick={handleCheckVault}
                className="btn join-item"
                disabled={!asset || checkingVault}
              >
                {checkingVault ? t("adminVaultCreation.buttons.checking") : t("adminVaultCreation.buttons.check")}
              </button>
            </div>
            {asset && hasVault && existingVault && (
              <label className="label">
                <span className="label-text-alt text-warning">
                  {t("adminVaultCreation.messages.existsWarning")} {existingVault.toString().slice(0, 10)}...
                </span>
              </label>
            )}
            {asset && !hasVault && (
              <label className="label">
                <span className="label-text-alt text-success">{t("adminVaultCreation.messages.noExisting")}</span>
              </label>
            )}
          </div>

          {/* Vault Name */}
          <div className="form-control">
            <label className="label">
              <span className="label-text font-semibold">{t("adminVaultCreation.vaultName.label")}</span>
              <span className="label-text-alt text-error">{t("adminVaultCreation.assetAddress.required")}</span>
            </label>
            <input
              type="text"
              value={vaultName}
              onChange={e => setVaultName(e.target.value)}
              placeholder={t("adminVaultCreation.vaultName.placeholder")}
              className="input input-bordered w-full"
              required
            />
            <label className="label">
              <span className="label-text-alt">{t("adminVaultCreation.assetAddress.help")}</span>
            </label>
          </div>

          {/* Vault Symbol */}
          <div className="form-control">
            <label className="label">
              <span className="label-text font-semibold">{t("adminVaultCreation.vaultSymbol.label")}</span>
              <span className="label-text-alt text-error">{t("adminVaultCreation.assetAddress.required")}</span>
            </label>
            <input
              type="text"
              value={vaultSymbol}
              onChange={e => setVaultSymbol(e.target.value)}
              placeholder={t("adminVaultCreation.vaultSymbol.placeholder")}
              className="input input-bordered w-full"
              required
            />
            <label className="label">
              <span className="label-text-alt">{t("adminVaultCreation.vaultSymbol.help")}</span>
            </label>
          </div>

          {/* Management Fee */}
          <div className="form-control">
            <label className="label">
              <span className="label-text font-semibold">{t("adminVaultCreation.managementFee.label")}</span>
              <span className="label-text-alt">{fee ? `${(parseFloat(fee) / 100).toFixed(2)}%` : "0%"}</span>
            </label>
            <input
              type="number"
              value={fee}
              onChange={e => setFee(e.target.value)}
              placeholder="100"
              min="0"
              max="10000"
              className="input input-bordered w-full"
              required
            />
            <label className="label">
              <span className="label-text-alt">{t("adminVaultCreation.managementFee.help")}</span>
            </label>
          </div>

          {/* Submit Button */}
          <div className="card-actions justify-end mt-6">
            <button
              type="submit"
              disabled={isCreating || !asset || !vaultName || !vaultSymbol || !fee || hasVault}
              className="btn btn-primary btn-block"
            >
              {isCreating ? (
                <>
                  <span className="loading loading-spinner"></span>
                  {t("adminVaultCreation.buttons.creating")}
                </>
              ) : (
                t("adminVaultCreation.buttons.create")
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
