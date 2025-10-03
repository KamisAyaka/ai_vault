"use client";

import { useState } from "react";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

export const VaultCreationForm = () => {
  const [asset, setAsset] = useState("");
  const [vaultName, setVaultName] = useState("");
  const [vaultSymbol, setVaultSymbol] = useState("");
  const [fee, setFee] = useState("100"); // Default 1% (100 basis points)
  const [isCreating, setIsCreating] = useState(false);
  const [checkingVault, setCheckingVault] = useState(false);

  const { writeContractAsync: createVaultAsync } = useScaffoldWriteContract("VaultFactory");

  // Check if vault already exists for this asset
  const { data: existingVault } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "getVault",
    args: asset ? [asset] : undefined,
  });

  const { data: hasVault } = useScaffoldReadContract({
    contractName: "VaultFactory",
    functionName: "hasVault",
    args: asset ? [asset] : undefined,
  });

  const handleCheckVault = async () => {
    if (!asset) {
      notification.error("Please enter an asset address");
      return;
    }
    setCheckingVault(true);
    // The useScaffoldReadContract will automatically fetch
    setTimeout(() => setCheckingVault(false), 500);
  };

  const handleCreateVault = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!asset || !vaultName || !vaultSymbol || !fee) {
      notification.error("Please fill in all fields");
      return;
    }

    if (hasVault) {
      notification.error("Vault already exists for this asset");
      return;
    }

    setIsCreating(true);

    try {
      await createVaultAsync({
        functionName: "createVault",
        args: [asset, vaultName, vaultSymbol, BigInt(fee)],
      });

      notification.success("Vault created successfully!");

      // Reset form
      setAsset("");
      setVaultName("");
      setVaultSymbol("");
      setFee("100");
    } catch (error: any) {
      console.error("Failed to create vault:", error);
      notification.error(error?.message || "Failed to create vault");
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <h2 className="card-title text-2xl mb-4">🏗️ Create New Vault</h2>

        <form onSubmit={handleCreateVault} className="space-y-4">
          {/* Asset Address */}
          <div className="form-control">
            <label className="label">
              <span className="label-text font-semibold">Asset Token Address</span>
              <span className="label-text-alt text-error">Required</span>
            </label>
            <div className="join w-full">
              <input
                type="text"
                value={asset}
                onChange={e => setAsset(e.target.value)}
                placeholder="0x..."
                className="input input-bordered join-item w-full"
                required
              />
              <button
                type="button"
                onClick={handleCheckVault}
                className="btn join-item"
                disabled={!asset || checkingVault}
              >
                {checkingVault ? "Checking..." : "Check"}
              </button>
            </div>
            {hasVault && existingVault && (
              <label className="label">
                <span className="label-text-alt text-warning">
                  ⚠️ Vault already exists at: {existingVault.toString().slice(0, 10)}...
                </span>
              </label>
            )}
            {asset && !hasVault && (
              <label className="label">
                <span className="label-text-alt text-success">✓ No existing vault for this asset</span>
              </label>
            )}
          </div>

          {/* Vault Name */}
          <div className="form-control">
            <label className="label">
              <span className="label-text font-semibold">Vault Name</span>
              <span className="label-text-alt text-error">Required</span>
            </label>
            <input
              type="text"
              value={vaultName}
              onChange={e => setVaultName(e.target.value)}
              placeholder="e.g., USDC Vault"
              className="input input-bordered w-full"
              required
            />
            <label className="label">
              <span className="label-text-alt">This will be the ERC-4626 vault name</span>
            </label>
          </div>

          {/* Vault Symbol */}
          <div className="form-control">
            <label className="label">
              <span className="label-text font-semibold">Vault Symbol</span>
              <span className="label-text-alt text-error">Required</span>
            </label>
            <input
              type="text"
              value={vaultSymbol}
              onChange={e => setVaultSymbol(e.target.value)}
              placeholder="e.g., vUSDC"
              className="input input-bordered w-full"
              required
            />
            <label className="label">
              <span className="label-text-alt">Token symbol for vault shares</span>
            </label>
          </div>

          {/* Management Fee */}
          <div className="form-control">
            <label className="label">
              <span className="label-text font-semibold">Management Fee (Basis Points)</span>
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
              <span className="label-text-alt">100 basis points = 1%, 10000 = 100%</span>
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
                  Creating Vault...
                </>
              ) : (
                "Create Vault"
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
