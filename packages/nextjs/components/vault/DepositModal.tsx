"use client";

import { useEffect, useMemo, useState } from "react";
import { erc20Abi, formatUnits, isAddress, parseUnits } from "viem";
import { useAccount, usePublicClient, useReadContract, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type DepositModalProps = {
  vault: Vault;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

export const DepositModal = ({ vault, isOpen, onClose, onSuccess }: DepositModalProps) => {
  const t = useTranslations("depositModal");
  const [amount, setAmount] = useState("");
  const [isDepositing, setIsDepositing] = useState(false);
  const [needsApproval, setNeedsApproval] = useState(false);
  const [isApproving, setIsApproving] = useState(false);

  const { address: connectedAddress } = useAccount();

  const assetAddress = vault.asset?.address || "";
  const assetSymbol = vault.asset?.symbol?.toUpperCase() || "TOKEN";
  const assetDecimals = vault.asset?.decimals || 18;
  const isSupportedAsset = isAddress(assetAddress);

  const publicClient = usePublicClient();

  const { data: userBalance, refetch: refetchUserBalance } = useReadContract({
    abi: erc20Abi,
    address: isSupportedAsset ? (assetAddress as `0x${string}`) : undefined,
    functionName: "balanceOf",
    args: connectedAddress && isSupportedAsset ? [connectedAddress] : undefined,
    query: {
      enabled: Boolean(connectedAddress && isSupportedAsset),
    },
  });

  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    abi: erc20Abi,
    address: isSupportedAsset ? (assetAddress as `0x${string}`) : undefined,
    functionName: "allowance",
    args: connectedAddress && isSupportedAsset ? [connectedAddress, vault.address as `0x${string}`] : undefined,
    query: {
      enabled: Boolean(connectedAddress && isSupportedAsset),
    },
  });

  const { writeContractAsync: writeTokenAsync } = useWriteContract();

  const { data: vaultContractInfo } = useDeployedContractInfo({
    contractName: "VaultImplementation",
  });

  const { writeContractAsync } = useWriteContract();
  const writeTx = useTransactor();

  const safeBigInt = (value?: string) => {
    try {
      return BigInt(value || "0");
    } catch {
      return 0n;
    }
  };

  // 计算用户将获得的份额
  const estimatedShares = useMemo(() => {
    if (!amount || !vault.totalAssets || !vault.totalSupply) return "0";

    try {
      const amountBigInt = parseUnits(amount, assetDecimals);
      const totalAssets = safeBigInt(vault.totalAssets);
      const totalSupply = safeBigInt(vault.totalSupply);

      if (totalSupply === 0n || totalAssets === 0n) {
        return formatUnits(amountBigInt, assetDecimals);
      }

      const shares = (amountBigInt * totalSupply) / totalAssets;
      return formatUnits(shares, assetDecimals);
    } catch {
      return "0";
    }
  }, [amount, vault.totalAssets, vault.totalSupply, assetDecimals]);

  // 计算汇率
  const exchangeRate = useMemo(() => {
    if (!vault.totalAssets || !vault.totalSupply) return "1";

    try {
      const totalAssets = safeBigInt(vault.totalAssets);
      const totalSupply = safeBigInt(vault.totalSupply);

      if (totalSupply === 0n) return "1";

      const rate = Number((totalAssets * 10000n) / totalSupply) / 10000;
      return rate.toFixed(4);
    } catch {
      return "1";
    }
  }, [vault.totalAssets, vault.totalSupply]);

  // 检查是否需要授权
  useEffect(() => {
    if (!amount || !allowance || !isSupportedAsset) {
      setNeedsApproval(false);
      return;
    }

    try {
      const amountBigInt = parseUnits(amount, assetDecimals);
      setNeedsApproval(allowance < amountBigInt);
    } catch {
      setNeedsApproval(false);
    }
  }, [amount, allowance, assetDecimals, isSupportedAsset]);

  const handleMaxClick = () => {
    if (userBalance !== undefined) {
      setAmount(formatUnits(userBalance, assetDecimals));
    }
  };

  const handleApprove = async () => {
    if (!connectedAddress || !amount) return;

    setIsApproving(true);
    try {
      if (!isSupportedAsset) {
        notification.error(t("messages.unrecognizedAsset"));
        return;
      }

      const amountBigInt = parseUnits(amount, assetDecimals);

      const hash = await writeTokenAsync({
        abi: erc20Abi,
        address: assetAddress as `0x${string}`,
        functionName: "approve",
        args: [vault.address as `0x${string}`, amountBigInt],
      });

      if (publicClient) {
        await publicClient.waitForTransactionReceipt({ hash });
      }

      notification.success(`${t("messages.approved")} ${amount} ${assetSymbol}`);
      refetchAllowance();
      refetchUserBalance();
    } catch (error: any) {
      console.error("Approval failed:", error);
      notification.error(error?.message || t("messages.approvalFailed"));
    } finally {
      setIsApproving(false);
    }
  };

  const handleDeposit = async () => {
    if (!connectedAddress || !amount) return;

    if (!vaultContractInfo?.abi) {
      notification.error(t("messages.abiUnavailable"));
      return;
    }

    setIsDepositing(true);
    try {
      const depositAmountDisplay = amount;
      const amountBigInt = parseUnits(amount, assetDecimals);

      const makeWriteWithParams = () =>
        writeContractAsync({
          address: vault.address as `0x${string}`,
          abi: vaultContractInfo.abi,
          functionName: "deposit",
          args: [amountBigInt, connectedAddress],
        });

      await writeTx(makeWriteWithParams, {
        onTransactionSubmitted: () => {
          setAmount("");
          onClose();
        },
        onBlockConfirmation: receipt => {
          console.debug("Deposit confirmed", receipt);
          notification.success(`${t("messages.depositSuccess")} ${depositAmountDisplay} ${assetSymbol}!`);
          refetchUserBalance();
          refetchAllowance();
          onSuccess?.();
        },
      });
    } catch (error: any) {
      console.error("Deposit failed:", error);
      notification.error(error?.message || t("messages.depositFailed"));
    } finally {
      setIsDepositing(false);
    }
  };

  const formatBalance = (balance: bigint | undefined) => {
    if (balance === undefined) return "0";
    const formatted = formatUnits(balance, assetDecimals);
    const num = parseFloat(formatted);
    return num.toLocaleString(undefined, { maximumFractionDigits: 2 });
  };

  const formattedAllowance = formatBalance(allowance);

  const isValidAmount = useMemo(() => {
    if (!amount || !isSupportedAsset) return false;
    try {
      const amountBigInt = parseUnits(amount, assetDecimals);
      return amountBigInt > 0n && (!userBalance || amountBigInt <= userBalance);
    } catch {
      return false;
    }
  }, [amount, userBalance, assetDecimals, isSupportedAsset]);

  if (!isOpen) return null;

  return (
    <div className="modal modal-open">
      <div className="modal-box max-w-2xl">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-2xl font-bold">💰 {t("title")}</h3>
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
                {t("vaultInfo.address")} {vault.address.slice(0, 10)}...{vault.address.slice(-8)}
              </p>
            </div>
            <div className="text-right">
              <p className="text-sm opacity-70">{t("vaultInfo.currentApy")}</p>
              <p className="text-xl font-bold text-success">8.5%</p>
            </div>
          </div>
          <div className="divider my-2"></div>
          <div className="flex justify-between text-sm">
            <span className="opacity-70">{t("vaultInfo.tvl")}</span>
            <span className="font-semibold">
              {formatBalance(safeBigInt(vault.totalAssets))} {assetSymbol}
            </span>
          </div>
        </div>

        {/* Deposit Amount */}
        <div className="mb-6">
          <label className="label">
            <span className="label-text font-semibold">{t("form.depositAmount")}</span>
          </label>
          <div className="join w-full">
            <input
              type="number"
              step="any"
              value={amount}
              onChange={e => setAmount(e.target.value)}
              placeholder="0.00"
              className="input input-bordered join-item flex-1 min-w-0 text-lg"
            />
            <span className="btn btn-square join-item bg-base-200 border-base-300 no-animation flex-none h-10 w-[50px] min-h-0">
              {assetSymbol}
            </span>
            <button onClick={handleMaxClick} className="btn btn-primary join-item">
              {t("form.max")}
            </button>
          </div>
          <label className="label">
            <span className="label-text-alt">
              {t("form.availableBalance")} {formatBalance(userBalance)} {assetSymbol}
            </span>
          </label>
        </div>

        {/* Estimated Shares */}
        {amount && isValidAmount && (
          <div className="bg-primary/10 p-4 rounded-lg mb-6">
            <p className="text-sm font-semibold mb-2">{t("form.willReceive")}</p>
            <p className="text-2xl font-bold text-primary">
              ~{parseFloat(estimatedShares).toLocaleString(undefined, { maximumFractionDigits: 4 })} v{assetSymbol}
            </p>
            <p className="text-xs opacity-70 mt-1">
              ({t("form.exchangeRate")} 1 {assetSymbol} = {(1 / parseFloat(exchangeRate)).toFixed(4)} v{assetSymbol})
            </p>
          </div>
        )}

        {/* Approval Status */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <p className="text-sm font-semibold mb-2">{t("approval.title")}</p>
          {!isSupportedAsset ? (
            <div className="flex items-center gap-2 text-warning">
              <span>⚠️</span>
              <span className="text-sm">{t("approval.unrecognizedAsset")}</span>
            </div>
          ) : allowance && allowance > 0n ? (
            <div className="flex items-center gap-2">
              <span className="text-success">✅</span>
              <span className="text-sm">
                {t("approval.approved")} {formattedAllowance} {assetSymbol}
              </span>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <span className="text-warning">⚠️</span>
              <span className="text-sm">{t("approval.needApproval")}</span>
            </div>
          )}
          {needsApproval && isSupportedAsset && (
            <p className="text-xs text-warning mt-2">{t("approval.insufficientAllowance")}</p>
          )}
        </div>

        {/* Important Notes */}
        <div className="alert alert-warning mb-6">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="stroke-current shrink-0 h-5 w-5"
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
          <div className="text-xs">
            <p className="font-semibold mb-1">{t("warnings.title")}</p>
            <ul className="list-disc list-inside space-y-1 opacity-80">
              <li>{t("warnings.autoAllocation")}</li>
              <li>{t("warnings.blockConfirmation")}</li>
              <li>{t("warnings.managementFee")}</li>
            </ul>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button onClick={onClose} className="btn btn-ghost flex-1">
            {t("buttons.cancel")}
          </button>
          {needsApproval ? (
            <button onClick={handleApprove} disabled={isApproving || !isValidAmount} className="btn btn-primary flex-1">
              {isApproving ? (
                <>
                  <span className="loading loading-spinner loading-sm"></span>
                  {t("buttons.approving")}
                </>
              ) : (
                `🔓 ${t("buttons.approve")} ${assetSymbol}`
              )}
            </button>
          ) : (
            <button
              onClick={handleDeposit}
              disabled={isDepositing || !isValidAmount || !connectedAddress}
              className="btn btn-primary flex-1"
            >
              {isDepositing ? (
                <>
                  <span className="loading loading-spinner loading-sm"></span>
                  {t("buttons.depositing")}
                </>
              ) : (
                `💰 ${t("buttons.confirmDeposit")}`
              )}
            </button>
          )}
        </div>
      </div>
      <div className="modal-backdrop bg-black/50" onClick={onClose}></div>
    </div>
  );
};
