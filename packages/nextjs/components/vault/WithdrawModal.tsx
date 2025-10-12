"use client";

import { useEffect, useMemo, useState } from "react";
import { createPortal } from "react-dom";
import { formatUnits, parseUnits } from "viem";
import { useAccount, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { useTokenUsdPrices } from "~~/hooks/useTokenUsdPrices";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type WithdrawModalProps = {
  vault: Vault;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

type WithdrawMode = "assets" | "shares";

export const WithdrawModal = ({ vault, isOpen, onClose, onSuccess }: WithdrawModalProps) => {
  const t = useTranslations("withdrawModal");
  const [mode, setMode] = useState<WithdrawMode>("assets");
  const [amount, setAmount] = useState("");
  const [isWithdrawing, setIsWithdrawing] = useState(false);
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
    return () => {
      setIsMounted(false);
    };
  }, []);

  const { address: connectedAddress } = useAccount();

  const assetSymbol = vault.asset?.symbol?.toUpperCase() || "TOKEN";
  const assetDecimals = vault.asset?.decimals || 18;
  const { tokenPrices } = useTokenUsdPrices();

  const formatUsdValue = (value?: number | null, fractionDigits = 2) => {
    if (value === undefined || value === null || !Number.isFinite(value)) return null;
    return `$${value.toLocaleString(undefined, { maximumFractionDigits: fractionDigits })}`;
  };

  const assetUsdPrice = useMemo(() => {
    const upper = assetSymbol.toUpperCase();
    if (tokenPrices[upper]) return tokenPrices[upper];
    if (upper === "ETH" || upper === "WETH") return tokenPrices.WETH;
    if (["USDC", "USDT", "DAI", "USDP", "TUSD"].includes(upper)) return 1;
    return undefined;
  }, [assetSymbol, tokenPrices]);

  const { data: vaultContractInfo } = useDeployedContractInfo({
    contractName: "VaultImplementation",
  });

  const { writeContractAsync } = useWriteContract();
  const writeTx = useTransactor();

  // 计算用户持仓
  const userPosition = useMemo(() => {
    if (!connectedAddress || !vault.deposits) {
      return { shares: 0n, value: 0n, profit: 0n };
    }

    const lowercaseAddress = connectedAddress.toLowerCase();

    // 计算用户的份额
    const userShares = vault.deposits
      .filter(deposit => deposit.user?.address?.toLowerCase() === lowercaseAddress)
      .reduce<bigint>((sum, deposit) => {
        try {
          return sum + BigInt(deposit.userShares || "0");
        } catch {
          return sum;
        }
      }, 0n);

    // 计算当前价值
    const totalAssets = BigInt(vault.totalAssets || "0");
    const totalSupply = BigInt(vault.totalSupply || "0");
    const currentValue = totalSupply > 0n ? (totalAssets * userShares) / totalSupply : 0n;

    // 计算总存款
    const totalDeposited = vault.deposits
      .filter(deposit => deposit.user?.address?.toLowerCase() === lowercaseAddress)
      .reduce<bigint>((sum, deposit) => {
        try {
          return sum + BigInt(deposit.assets || "0");
        } catch {
          return sum;
        }
      }, 0n);

    // 计算总赎回
    const totalRedeemed = (vault.redeems || [])
      .filter(redeem => redeem.user?.address?.toLowerCase() === lowercaseAddress)
      .reduce<bigint>((sum, redeem) => {
        try {
          return sum + BigInt(redeem.assets || "0");
        } catch {
          return sum;
        }
      }, 0n);

    const profit = currentValue - (totalDeposited - totalRedeemed);

    return { shares: userShares, value: currentValue, profit };
  }, [connectedAddress, vault]);

  // 计算需要赎回的份额或将获得的资产
  const estimation = useMemo(() => {
    if (!amount || !vault.totalAssets || !vault.totalSupply) {
      return { shares: "0", assets: "0" };
    }

    try {
      const totalAssets = BigInt(vault.totalAssets);
      const totalSupply = BigInt(vault.totalSupply);

      if (totalSupply === 0n) {
        return { shares: "0", assets: "0" };
      }

      if (mode === "assets") {
        // 按资产数量取款，计算需要的份额
        const assetAmount = parseUnits(amount, assetDecimals);
        const requiredShares = (assetAmount * totalSupply) / totalAssets;
        return {
          shares: formatUnits(requiredShares, assetDecimals),
          assets: amount,
        };
      } else {
        // 按份额赎回，计算将获得的资产
        const shareAmount = parseUnits(amount, assetDecimals);
        const receivedAssets = (shareAmount * totalAssets) / totalSupply;
        return {
          shares: amount,
          assets: formatUnits(receivedAssets, assetDecimals),
        };
      }
    } catch {
      return { shares: "0", assets: "0" };
    }
  }, [amount, mode, vault.totalAssets, vault.totalSupply, assetDecimals]);

  // 计算汇率
  const exchangeRate = useMemo(() => {
    if (!vault.totalAssets || !vault.totalSupply) return "1";

    try {
      const totalAssets = BigInt(vault.totalAssets);
      const totalSupply = BigInt(vault.totalSupply);

      if (totalSupply === 0n) return "1";

      const rate = Number((totalAssets * 10000n) / totalSupply) / 10000;
      return rate.toFixed(4);
    } catch {
      return "1";
    }
  }, [vault.totalAssets, vault.totalSupply]);

  // 计算取款后剩余
  const remainingPosition = useMemo(() => {
    if (!amount) {
      return {
        shares: userPosition.shares,
        value: userPosition.value,
      };
    }

    try {
      if (mode === "assets") {
        const withdrawAmount = parseUnits(amount, assetDecimals);
        const requiredShares = parseUnits(estimation.shares, assetDecimals);
        return {
          shares: userPosition.shares - requiredShares,
          value: userPosition.value - withdrawAmount,
        };
      } else {
        const shareAmount = parseUnits(amount, assetDecimals);
        const receivedAssets = parseUnits(estimation.assets, assetDecimals);
        return {
          shares: userPosition.shares - shareAmount,
          value: userPosition.value - receivedAssets,
        };
      }
    } catch {
      return {
        shares: userPosition.shares,
        value: userPosition.value,
      };
    }
  }, [amount, mode, userPosition, estimation, assetDecimals]);

  const amountUsd = useMemo(() => {
    if (!assetUsdPrice || !amount) return null;
    if (mode === "assets") {
      const numeric = Number(amount);
      return Number.isFinite(numeric) ? numeric * assetUsdPrice : null;
    }
    const numeric = Number(estimation.assets);
    return Number.isFinite(numeric) ? numeric * assetUsdPrice : null;
  }, [amount, assetUsdPrice, estimation.assets, mode]);

  const estimationUsd = useMemo(() => {
    if (!assetUsdPrice) return null;
    const numeric = Number(estimation.assets);
    return Number.isFinite(numeric) ? numeric * assetUsdPrice : null;
  }, [assetUsdPrice, estimation.assets]);

  const remainingValueUsd = useMemo(() => {
    if (!assetUsdPrice) return null;
    const numeric = Number(formatUnits(remainingPosition.value, assetDecimals));
    return Number.isFinite(numeric) ? numeric * assetUsdPrice : null;
  }, [assetDecimals, assetUsdPrice, remainingPosition.value]);

  const userCurrentValueUsd = useMemo(() => {
    if (!assetUsdPrice) return null;
    const numeric = Number(formatUnits(userPosition.value, assetDecimals));
    return Number.isFinite(numeric) ? numeric * assetUsdPrice : null;
  }, [assetDecimals, assetUsdPrice, userPosition.value]);

  const userProfitUsd = useMemo(() => {
    if (!assetUsdPrice) return null;
    const numeric = Number(formatUnits(userPosition.profit, assetDecimals));
    return Number.isFinite(numeric) ? numeric * assetUsdPrice : null;
  }, [assetDecimals, assetUsdPrice, userPosition.profit]);
  const userProfitUsdDisplay = userProfitUsd !== null ? formatUsdValue(Math.abs(userProfitUsd)) : null;

  const handleMaxClick = () => {
    if (mode === "assets") {
      setAmount(formatUnits(userPosition.value, assetDecimals));
    } else {
      setAmount(formatUnits(userPosition.shares, assetDecimals));
    }
  };

  const handleWithdraw = async () => {
    if (!connectedAddress || !amount) return;

    if (!vaultContractInfo?.abi) {
      notification.error(t("messages.abiMissing"));
      return;
    }

    setIsWithdrawing(true);
    try {
      if (mode === "assets") {
        // 按资产数量取款
        const assetAmount = parseUnits(amount, assetDecimals);

        const makeWriteWithParams = () =>
          writeContractAsync({
            address: vault.address as `0x${string}`,
            abi: vaultContractInfo.abi,
            functionName: "withdraw",
            args: [assetAmount, connectedAddress, connectedAddress],
          });

        await writeTx(makeWriteWithParams, {
          onBlockConfirmation: receipt => {
            console.debug("Withdraw confirmed", receipt);
            notification.success(`${t("messages.withdrawSuccess")} ${amount} ${assetSymbol}!`);
            setAmount("");
            onSuccess?.();
            onClose();
          },
        });
      } else {
        // 按份额赎回
        const shareAmount = parseUnits(amount, assetDecimals);

        const makeWriteWithParams = () =>
          writeContractAsync({
            address: vault.address as `0x${string}`,
            abi: vaultContractInfo.abi,
            functionName: "redeem",
            args: [shareAmount, connectedAddress, connectedAddress],
          });

        await writeTx(makeWriteWithParams, {
          onBlockConfirmation: receipt => {
            console.debug("Redeem confirmed", receipt);
            notification.success(`${t("messages.redeemSuccess")} ${amount} v${assetSymbol}!`);
            setAmount("");
            onSuccess?.();
            onClose();
          },
        });
      }
    } catch (error: any) {
      console.error("Withdraw/Redeem failed:", error);
      notification.error(error?.message || t("messages.operationFailed"));
    } finally {
      setIsWithdrawing(false);
    }
  };

  const formatBalance = (balance: bigint) => {
    const formatted = formatUnits(balance, assetDecimals);
    const num = parseFloat(formatted);
    return num.toLocaleString(undefined, { maximumFractionDigits: 4 });
  };

  const isValidAmount = useMemo(() => {
    if (!amount) return false;
    try {
      const amountBigInt = parseUnits(amount, assetDecimals);
      if (mode === "assets") {
        return amountBigInt > 0n && amountBigInt <= userPosition.value;
      } else {
        return amountBigInt > 0n && amountBigInt <= userPosition.shares;
      }
    } catch {
      return false;
    }
  }, [amount, mode, userPosition, assetDecimals]);

  if (!isOpen || !isMounted) return null;

  const profitPercent = userPosition.value > 0n ? Number((userPosition.profit * 10000n) / userPosition.value) / 100 : 0;

  const modalInner = (
    <div className="space-y-6 px-5 py-5">
      <div className="space-y-3">
        <div>
          <p className="text-xs uppercase tracking-[0.35em] text-primary">Vault Actions</p>
          <h3 className="mt-1 text-2xl font-bold">📤 {t("title")}</h3>
          <p className="mt-1 text-xs opacity-70">
            {t("tabs.withdraw")} / {t("tabs.redeem")} v{assetSymbol}
          </p>
        </div>
        <div className="grid grid-cols-2 gap-1">
          <button
            className={`tab tab-lifted h-9 w-full ${mode === "assets" ? "tab-active" : ""}`}
            onClick={() => {
              setMode("assets");
              setAmount("");
            }}
          >
            {t("tabs.withdraw")}
          </button>
          <button
            className={`tab tab-lifted h-9 w-full ${mode === "shares" ? "tab-active" : ""}`}
            onClick={() => {
              setMode("shares");
              setAmount("");
            }}
          >
            {t("tabs.redeem")}
          </button>
        </div>
      </div>

      <div className="rounded-lg bg-base-200 p-4">
        <p className="mb-3 text-sm font-semibold">{t("position.title")}</p>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <div>
            <p className="mb-1 text-xs opacity-70">{t("position.shareBalance")}</p>
            <p className="font-semibold">
              {formatBalance(userPosition.shares)} v{assetSymbol}
            </p>
          </div>
          <div>
            <p className="mb-1 text-xs opacity-70">{t("position.currentValue")}</p>
            <p className="font-semibold">
              ~{formatBalance(userPosition.value)} {assetSymbol}
            </p>
            {formatUsdValue(userCurrentValueUsd) && (
              <p className="text-xs opacity-70">≈ {formatUsdValue(userCurrentValueUsd)} USDT</p>
            )}
          </div>
          <div>
            <p className="mb-1 text-xs opacity-70">{t("position.profit")}</p>
            <p className={`font-semibold ${userPosition.profit >= 0n ? "text-success" : "text-error"}`}>
              {userPosition.profit >= 0n ? "+" : ""}
              {formatBalance(userPosition.profit)} {assetSymbol}
              <span className="ml-1 text-xs">
                ({userPosition.profit >= 0n ? "+" : ""}
                {profitPercent.toFixed(2)}%)
              </span>
            </p>
            {userProfitUsdDisplay && (
              <p className={`text-xs mt-1 ${userPosition.profit >= 0n ? "text-success" : "text-error"}`}>
                {userPosition.profit >= 0n ? "+" : "-"}
                {userProfitUsdDisplay} USDT
              </p>
            )}
          </div>
        </div>
      </div>

      <div>
        <label className="label">
          <span className="label-text font-semibold">
            {mode === "assets" ? t("form.withdrawAmount") : t("form.redeemShares")}
          </span>
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
          <span className="btn btn-square join-item border-base-300 bg-base-200 no-animation flex-none h-10 w-[50px] min-h-0">
            {mode === "assets" ? assetSymbol : `v${assetSymbol}`}
          </span>
          <button onClick={handleMaxClick} className="btn btn-error join-item">
            {t("form.max")}
          </button>
        </div>
        {formatUsdValue(amountUsd) && amount && (
          <p className="mt-2 text-xs opacity-70">≈ {formatUsdValue(amountUsd)} USDT</p>
        )}
      </div>

      {amount && isValidAmount && (
        <div className="rounded-lg bg-error/10 p-4">
          {mode === "assets" ? (
            <>
              <p className="mb-2 text-sm font-semibold">{t("form.sharesNeeded")}</p>
              <p className="text-2xl font-bold text-error">
                ~{parseFloat(estimation.shares).toLocaleString(undefined, { maximumFractionDigits: 4 })} v{assetSymbol}
              </p>
              <p className="mt-1 text-xs opacity-70">
                (1 v{assetSymbol} = {exchangeRate} {assetSymbol})
              </p>
              {formatUsdValue(estimationUsd) && (
                <p className="text-xs opacity-70 mt-1">≈ {formatUsdValue(estimationUsd)} USDT</p>
              )}
            </>
          ) : (
            <>
              <p className="mb-2 text-sm font-semibold">{t("form.willReceive")}</p>
              <p className="text-2xl font-bold text-error">
                ~{parseFloat(estimation.assets).toLocaleString(undefined, { maximumFractionDigits: 4 })} {assetSymbol}
              </p>
              <p className="mt-1 text-xs opacity-70">
                (1 v{assetSymbol} = {exchangeRate} {assetSymbol})
              </p>
              {formatUsdValue(estimationUsd) && (
                <p className="text-xs opacity-70 mt-1">≈ {formatUsdValue(estimationUsd)} USDT</p>
              )}
            </>
          )}
        </div>
      )}

      {amount && isValidAmount && (
        <div className="rounded-lg bg-base-200 p-4">
          <p className="mb-3 text-sm font-semibold">{t("form.afterWithdraw")}</p>
          <ul className="space-y-2 text-sm">
            <li className="flex justify-between">
              <span className="opacity-70">{t("form.remainingShares")}:</span>
              <span className="font-semibold">
                {formatBalance(remainingPosition.shares)} v{assetSymbol}
              </span>
            </li>
            <li className="flex justify-between">
              <span className="opacity-70">{t("form.remainingValue")}:</span>
              <span className="font-semibold">
                ~{formatBalance(remainingPosition.value)} {assetSymbol}
              </span>
            </li>
          </ul>
          {formatUsdValue(remainingValueUsd) && (
            <p className="mt-2 text-xs opacity-70">≈ {formatUsdValue(remainingValueUsd)} USDT</p>
          )}
        </div>
      )}

      <div className="alert alert-info">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          className="h-5 w-5 shrink-0 stroke-current"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          ></path>
        </svg>
        <div className="text-xs">
          <p className="font-semibold">⏱️ {t("estimate.title")}</p>
          <p className="opacity-80">{t("estimate.value")}</p>
        </div>
      </div>

      <div className="flex flex-wrap justify-center gap-3">
        <button onClick={onClose} className="btn btn-ghost min-w-[120px]">
          {t("buttons.cancel")}
        </button>
        <button
          onClick={handleWithdraw}
          disabled={isWithdrawing || !isValidAmount || !connectedAddress}
          className="btn btn-error min-w-[140px]"
        >
          {isWithdrawing ? (
            <>
              <span className="loading loading-spinner loading-sm"></span>
              {t("buttons.processing")}
            </>
          ) : (
            `📤 ${mode === "assets" ? t("buttons.confirmWithdraw") : t("buttons.confirmRedeem")}`
          )}
        </button>
      </div>
    </div>
  );

  const modalContent = (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose}></div>
      <div
        className="relative z-10 w-full max-h-[90vh] max-w-4xl overflow-y-auto rounded-2xl border border-primary/40 bg-base-100 shadow-2xl"
        onClick={event => event.stopPropagation()}
      >
        <button onClick={onClose} className="btn btn-sm btn-circle btn-ghost absolute right-4 top-4 z-30">
          ✕
        </button>
        {modalInner}
      </div>
    </div>
  );

  return createPortal(modalContent, document.body);
};
