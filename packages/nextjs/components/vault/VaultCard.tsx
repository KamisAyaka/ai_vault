"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { DepositETHModal } from "./DepositETHModal";
import { DepositModal } from "./DepositModal";
import { MintETHModal } from "./MintETHModal";
import { MintModal } from "./MintModal";
import { WithdrawETHModal } from "./WithdrawETHModal";
import { WithdrawModal } from "./WithdrawModal";
import { formatUnits } from "viem";
import { Address } from "~~/components/scaffold-eth";
import { useVaultPerformance } from "~~/hooks/useVaultPerformance";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import type { Vault } from "~~/types/vault";

type VaultCardProps = {
  vault: Vault;
  userAddress?: string;
  onSuccess?: () => void;
};

export const VaultCard = ({ vault, userAddress, onSuccess }: VaultCardProps) => {
  const [isDepositModalOpen, setIsDepositModalOpen] = useState(false);
  const [isWithdrawModalOpen, setIsWithdrawModalOpen] = useState(false);
  const [isMintModalOpen, setIsMintModalOpen] = useState(false);
  const tCard = useTranslations("vaultCard");
  const tStatus = useTranslations("common.status");

  // 获取金库性能数据
  const { data: performanceData } = useVaultPerformance(1000);
  const vaultPerformance = useMemo(() => {
    return performanceData.find(p => p.vault.address.toLowerCase() === vault.address.toLowerCase());
  }, [performanceData, vault.address]);

  const assetSymbolFromMetadata = vault.asset?.symbol ?? "";
  const fallbackSymbol = () => {
    const upperName = vault.name.toUpperCase();
    if (upperName.includes("USDC")) return "USDC";
    if (upperName.includes("WETH") || upperName.includes("ETH")) return "WETH";
    if (upperName.includes("DAI")) return "DAI";
    if (upperName.includes("USDT")) return "USDT";
    return "TOKEN";
  };

  const assetSymbol = (assetSymbolFromMetadata || fallbackSymbol()).toUpperCase();
  const assetDecimals = vault.asset?.decimals ?? 18;

  const safeBigInt = (value?: string) => {
    try {
      return BigInt(value || "0");
    } catch {
      return 0n;
    }
  };

  const formatTokenAmount = (amount: bigint, decimals: number, fractionDigits = 2) => {
    try {
      const normalized = formatUnits(amount, decimals);
      const numericValue = Number.parseFloat(normalized);
      if (!Number.isFinite(numericValue)) {
        return normalized;
      }
      return numericValue.toLocaleString(undefined, {
        maximumFractionDigits: fractionDigits,
      });
    } catch {
      return "0";
    }
  };

  const allocations = vault.allocations ?? [];
  const deposits = vault.deposits ?? [];
  const totalAssetsBigInt = safeBigInt(vault.totalAssets);
  const totalSupplyBigInt = safeBigInt(vault.totalSupply);

  // 使用真实APY数据
  const apy = vaultPerformance?.currentAPY || 5.0;
  const managementFeeRate = vaultPerformance?.managementFeeRate || 0.01;
  const performanceFeeRate = vaultPerformance?.performanceFeeRate || 0.2;

  const getAssetEmoji = () => {
    if (assetSymbol === "USDC" || assetSymbol === "USDT") return "💵";
    if (assetSymbol === "WETH" || assetSymbol === "ETH") return "Ξ";
    if (assetSymbol === "DAI") return "💎";
    return "🪙";
  };

  const userShareData = () => {
    if (!userAddress) {
      return { shares: 0n, formattedShares: "0", formattedValue: "0" };
    }

    const lowercaseAddress = userAddress.toLowerCase();
    const userShares = deposits
      .filter(deposit => deposit.user?.address?.toLowerCase() === lowercaseAddress)
      .reduce<bigint>((sum, deposit) => sum + safeBigInt(deposit.userShares), 0n);

    if (userShares === 0n) {
      return { shares: 0n, formattedShares: "0", formattedValue: "0" };
    }

    const vaultTotalSupply = totalSupplyBigInt;
    const vaultTotalAssets = totalAssetsBigInt;
    const userAssetAmount = vaultTotalSupply > 0n ? (vaultTotalAssets * userShares) / vaultTotalSupply : 0n;

    return {
      shares: userShares,
      formattedShares: formatTokenAmount(userShares, assetDecimals, 4),
      formattedValue: formatTokenAmount(userAssetAmount, assetDecimals, 4),
    };
  };

  const { formattedShares, formattedValue } = userShareData();

  // 判断是否为 ETH 金库
  const isETHVault = assetSymbol === "WETH" || assetSymbol === "ETH";

  return (
    <>
      <div className="card bg-base-100 shadow-xl hover:shadow-2xl transition-shadow duration-300">
        <div className="card-body">
          {/* Header with asset name and status */}
          <div className="flex justify-between items-start mb-2">
            <h2 className="card-title text-xl">
              <span className="text-2xl mr-2">{getAssetEmoji()}</span>
              {vault.name}
            </h2>
            <div className={`badge ${vault.isActive ? "badge-success" : "badge-error"} gap-2`}>
              {vault.isActive ? `🟢 ${tStatus("active")}` : `🔴 ${tStatus("inactive")}`}
            </div>
          </div>

          {/* Vault address */}
          <div className="text-sm opacity-70 mb-3">
            <Address address={vault.address} size="sm" />
          </div>

          {/* Key metrics */}
          <div className="grid grid-cols-2 gap-3 mb-4">
            <div className="bg-base-200 p-3 rounded-lg">
              <div className="text-xs opacity-70 mb-1">{tCard("labels.tvl")}</div>
              <div className="font-bold text-lg">
                {formatTokenAmount(totalAssetsBigInt, assetDecimals)} {assetSymbol}
              </div>
            </div>
            <div className="bg-base-200 p-3 rounded-lg">
              <div className="text-xs opacity-70 mb-1">{tCard("labels.apy")}</div>
              <div className="font-bold text-lg text-success">{apy.toFixed(1)}%</div>
              <div className="text-xs opacity-60">{tCard("labels.netYield")}</div>
            </div>
          </div>

          {/* Fee information */}
          <div className="bg-primary/5 p-3 rounded-lg mb-4">
            <div className="text-xs font-semibold mb-2 opacity-70">💰 {tCard("labels.fees")}</div>
            <div className="flex justify-between text-xs">
              <span>{tCard("labels.managementFee")}:</span>
              <span>{(managementFeeRate * 100).toFixed(1)}%/y</span>
            </div>
            <div className="flex justify-between text-xs">
              <span>{tCard("labels.performanceFee")}:</span>
              <span>{(performanceFeeRate * 100).toFixed(0)}%</span>
            </div>
            {vaultPerformance && (
              <div className="flex justify-between text-xs mt-1 pt-1 border-t border-base-300">
                <span>{tCard("labels.totalFees")}:</span>
                <span className="font-semibold">
                  ${vaultPerformance.totalFeesPaid.toLocaleString(undefined, { maximumFractionDigits: 2 })}
                </span>
              </div>
            )}
          </div>

          {/* Investment strategies */}
          {allocations.length > 0 && (
            <div className="mb-4">
              <div className="text-sm font-semibold mb-2">{tCard("labels.strategies")}</div>
              <div className="space-y-1">
                {allocations.map((allocation, index) => {
                  const percentage = ((Number(allocation.allocation) / 1000) * 100).toFixed(1);
                  return (
                    <div key={index} className="flex justify-between text-sm">
                      <span className="opacity-80">• {allocation.adapterType}</span>
                      <span className="font-semibold">{percentage}%</span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* User position (if connected) */}
          {userAddress && deposits.length > 0 && formattedShares !== "0" && (
            <div className="bg-primary/10 p-3 rounded-lg mb-4">
              <div className="text-sm font-semibold mb-2">{tCard("labels.position")}</div>
              <div className="text-sm">
                <div>
                  {tCard("labels.shares")}:
                  <span className="font-bold">{formattedShares}</span>
                </div>
                <div className="opacity-70 text-xs mt-1">
                  ≈ {formattedValue} {assetSymbol}
                </div>
              </div>
            </div>
          )}
          {userAddress && formattedShares === "0" && (
            <div className="bg-base-200 p-3 rounded-lg mb-4 text-sm opacity-70">
              {tCard("messages.noPosition")}
            </div>
          )}

          {/* Action buttons */}
          <div className="card-actions justify-end mt-2 gap-1">
            {vault.isActive ? (
              <>
                <button
                  className="btn btn-primary btn-sm"
                  onClick={() => setIsDepositModalOpen(true)}
                  disabled={!vault.isActive}
                >
                  💵 {tCard("actions.deposit")}
                </button>
                <button
                  className="btn btn-accent btn-sm"
                  onClick={() => setIsMintModalOpen(true)}
                  disabled={!vault.isActive}
                >
                  🪙 {tCard("actions.mint")}
                </button>
                <button
                  className="btn btn-secondary btn-sm"
                  onClick={() => setIsWithdrawModalOpen(true)}
                  disabled={!vault.isActive}
                >
                  📤 {tCard("actions.withdraw")}
                </button>
              </>
            ) : (
              <Link href={`/vaults/${vault.id}`} className="btn btn-ghost btn-sm">
                {tCard("actions.view")}
              </Link>
            )}
            <Link href={`/vaults/${vault.id}`} className="btn btn-ghost btn-sm">
              📊 {tCard("actions.details")}
            </Link>
          </div>
        </div>
      </div>

      {/* Modals */}
      {isETHVault ? (
        <>
          <DepositETHModal
            vault={vault}
            isOpen={isDepositModalOpen}
            onClose={() => setIsDepositModalOpen(false)}
            onSuccess={onSuccess}
          />
          <MintETHModal
            vault={vault}
            isOpen={isMintModalOpen}
            onClose={() => setIsMintModalOpen(false)}
            onSuccess={onSuccess}
          />
          <WithdrawETHModal
            vault={vault}
            isOpen={isWithdrawModalOpen}
            onClose={() => setIsWithdrawModalOpen(false)}
            onSuccess={onSuccess}
          />
        </>
      ) : (
        <>
          <DepositModal
            vault={vault}
            isOpen={isDepositModalOpen}
            onClose={() => setIsDepositModalOpen(false)}
            onSuccess={onSuccess}
          />
          <MintModal
            vault={vault}
            isOpen={isMintModalOpen}
            onClose={() => setIsMintModalOpen(false)}
            onSuccess={onSuccess}
          />
          <WithdrawModal
            vault={vault}
            isOpen={isWithdrawModalOpen}
            onClose={() => setIsWithdrawModalOpen(false)}
            onSuccess={onSuccess}
          />
        </>
      )}
    </>
  );
};
