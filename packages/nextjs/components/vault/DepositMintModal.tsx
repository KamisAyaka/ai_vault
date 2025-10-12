"use client";

import { useEffect, useMemo, useState } from "react";
import { createPortal } from "react-dom";
import { erc20Abi, formatEther, formatUnits, isAddress, parseEther, parseUnits } from "viem";
import { useAccount, useBalance, usePublicClient, useReadContract, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { useGlobalState } from "~~/services/store/store";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type DepositMintModalProps = {
  vault: Vault;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

type Mode = "deposit" | "mint";

const safeBigInt = (value?: string) => {
  try {
    return BigInt(value || "0");
  } catch {
    return 0n;
  }
};

const formatTokenAmount = (raw: bigint | undefined, decimals: number, fractionDigits = 4) => {
  if (raw === undefined) return "0";
  try {
    const formatted = formatUnits(raw, decimals);
    const numeric = Number.parseFloat(formatted);
    if (!Number.isFinite(numeric)) {
      return formatted;
    }
    return numeric.toLocaleString(undefined, { maximumFractionDigits: fractionDigits });
  } catch {
    return "0";
  }
};

const formatNumericString = (value: string, fractionDigits = 4) => {
  const numeric = Number.parseFloat(value);
  if (!Number.isFinite(numeric)) {
    return value;
  }
  return numeric.toLocaleString(undefined, { maximumFractionDigits: fractionDigits });
};

export const DepositMintModal = ({ vault, isOpen, onClose, onSuccess }: DepositMintModalProps) => {
  const [mode, setMode] = useState<Mode>("deposit");
  const [amountInput, setAmountInput] = useState("");
  const [shareInput, setShareInput] = useState("");
  const [isProcessing, setIsProcessing] = useState(false);
  const [isApproving, setIsApproving] = useState(false);
  const [isMounted, setIsMounted] = useState(false);

  const { address: connectedAddress } = useAccount();
  const nativePrice = useGlobalState(state => state.nativeCurrency.price) || 0;

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
  const isETHVault = assetSymbol === "WETH" || assetSymbol === "ETH";
  const displayAssetSymbol = isETHVault ? "ETH" : assetSymbol;

  const totalAssets = safeBigInt(vault.totalAssets);
  const totalSupply = safeBigInt(vault.totalSupply);

  const isSupportedAsset = isAddress(vault.asset?.address || "");

  const publicClient = usePublicClient();
  const { writeContractAsync: writeTokenAsync } = useWriteContract();
  const { writeContractAsync } = useWriteContract();
  const writeTx = useTransactor();

  const { data: vaultImplInfo } = useDeployedContractInfo({
    contractName: "VaultImplementation",
  });
  const { data: vaultEthInfo } = useDeployedContractInfo({
    contractName: "VaultSharesETH",
  });

  const { data: erc20Balance, refetch: refetchErc20Balance } = useReadContract({
    abi: erc20Abi,
    address: isSupportedAsset && !isETHVault ? (vault.asset?.address as `0x${string}`) : undefined,
    functionName: "balanceOf",
    args: connectedAddress && isSupportedAsset ? [connectedAddress] : undefined,
    query: {
      enabled: Boolean(connectedAddress && isSupportedAsset && !isETHVault),
    },
  });

  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    abi: erc20Abi,
    address: isSupportedAsset && !isETHVault ? (vault.asset?.address as `0x${string}`) : undefined,
    functionName: "allowance",
    args: connectedAddress && isSupportedAsset ? [connectedAddress, vault.address as `0x${string}`] : undefined,
    query: {
      enabled: Boolean(connectedAddress && isSupportedAsset && !isETHVault),
    },
  });

  const { data: ethBalance, refetch: refetchEthBalance } = useBalance({
    address: connectedAddress,
  });

  const exchangeRate = useMemo(() => {
    if (totalSupply === 0n) return "1";
    try {
      const rate = Number((totalAssets * 10000n) / totalSupply) / 10000;
      return rate.toFixed(4);
    } catch {
      return "1";
    }
  }, [totalAssets, totalSupply]);

  const exchangeRateNumber = useMemo(() => {
    const numeric = Number.parseFloat(exchangeRate);
    if (!Number.isFinite(numeric) || numeric <= 0) {
      return 1;
    }
    return numeric;
  }, [exchangeRate]);

  const estimatedShares = useMemo(() => {
    if (!amountInput) return "0";
    try {
      const amountBigInt = isETHVault ? parseEther(amountInput) : parseUnits(amountInput, assetDecimals);
      if (totalSupply === 0n || totalAssets === 0n) {
        return formatUnits(amountBigInt, assetDecimals);
      }
      const shares = (amountBigInt * totalSupply) / totalAssets;
      return formatUnits(shares, assetDecimals);
    } catch {
      return "0";
    }
  }, [amountInput, assetDecimals, totalAssets, totalSupply, isETHVault]);

  const requiredAssetsForShares = useMemo(() => {
    if (!shareInput) return "0";
    try {
      const sharesBigInt = isETHVault ? parseEther(shareInput) : parseUnits(shareInput, assetDecimals);
      if (totalSupply === 0n) {
        return formatUnits(sharesBigInt, assetDecimals);
      }
      const assets = (sharesBigInt * totalAssets) / totalSupply;
      return formatUnits(assets, assetDecimals);
    } catch {
      return "0";
    }
  }, [shareInput, assetDecimals, totalAssets, totalSupply, isETHVault]);

  const usdPreviewForAmount = useMemo(() => {
    if (!amountInput || !isETHVault) return "-";
    try {
      const value = Number.parseFloat(amountInput);
      if (!Number.isFinite(value) || value <= 0) return "-";
      return (value * nativePrice).toLocaleString(undefined, { maximumFractionDigits: 0 });
    } catch {
      return "-";
    }
  }, [amountInput, isETHVault, nativePrice]);

  const usdPreviewForShares = useMemo(() => {
    if (!requiredAssetsForShares || !isETHVault) return "-";
    try {
      const value = Number.parseFloat(requiredAssetsForShares);
      if (!Number.isFinite(value) || value <= 0) return "-";
      return (value * nativePrice).toLocaleString(undefined, { maximumFractionDigits: 0 });
    } catch {
      return "-";
    }
  }, [requiredAssetsForShares, isETHVault, nativePrice]);

  const requiredAssetBigInt = useMemo(() => {
    const targetAmount = mode === "deposit" ? amountInput : requiredAssetsForShares;
    if (!targetAmount) return 0n;
    try {
      return isETHVault ? parseEther(targetAmount) : parseUnits(targetAmount, assetDecimals);
    } catch {
      return 0n;
    }
  }, [mode, amountInput, requiredAssetsForShares, assetDecimals, isETHVault]);

  const needsApproval = useMemo(() => {
    if (isETHVault || !isSupportedAsset) return false;
    if (!requiredAssetBigInt || requiredAssetBigInt === 0n) return false;
    if (allowance === undefined) return false;
    try {
      return allowance < requiredAssetBigInt;
    } catch {
      return false;
    }
  }, [allowance, isETHVault, isSupportedAsset, requiredAssetBigInt]);

  const isValidDepositAmount = useMemo(() => {
    if (!amountInput) return false;
    try {
      const amountBigInt = isETHVault ? parseEther(amountInput) : parseUnits(amountInput, assetDecimals);
      if (amountBigInt <= 0n) return false;
      if (isETHVault) {
        if (!ethBalance?.value) return false;
        const gasReserve = parseEther("0.01");
        return amountBigInt <= (ethBalance.value > gasReserve ? ethBalance.value - gasReserve : 0n);
      }
      if (erc20Balance === undefined) return false;
      return amountBigInt <= erc20Balance;
    } catch {
      return false;
    }
  }, [amountInput, assetDecimals, erc20Balance, ethBalance, isETHVault]);

  const isValidShareAmount = useMemo(() => {
    if (!shareInput) return false;
    try {
      const assetsBigInt = requiredAssetBigInt;
      if (assetsBigInt <= 0n) return false;
      if (isETHVault) {
        if (!ethBalance?.value) return false;
        const gasReserve = parseEther("0.01");
        return assetsBigInt <= (ethBalance.value > gasReserve ? ethBalance.value - gasReserve : 0n);
      }
      if (erc20Balance === undefined) return false;
      return assetsBigInt <= erc20Balance;
    } catch {
      return false;
    }
  }, [shareInput, erc20Balance, ethBalance, isETHVault, requiredAssetBigInt]);

  const resetState = () => {
    setAmountInput("");
    setShareInput("");
    setMode("deposit");
    setIsProcessing(false);
    setIsApproving(false);
  };

  useEffect(() => {
    if (!isOpen) {
      resetState();
    }
  }, [isOpen]);

  useEffect(() => {
    setIsMounted(true);
  }, []);

  const handleApprove = async () => {
    if (!connectedAddress || !isSupportedAsset || isETHVault) return;
    if (!vault.asset?.address || requiredAssetBigInt === 0n) return;

    setIsApproving(true);
    try {
      const hash = await writeTokenAsync({
        abi: erc20Abi,
        address: vault.asset.address as `0x${string}`,
        functionName: "approve",
        args: [vault.address as `0x${string}`, requiredAssetBigInt],
      });

      if (publicClient) {
        await publicClient.waitForTransactionReceipt({ hash });
      }

      notification.success(`已授权 ${formatUnits(requiredAssetBigInt, assetDecimals)} ${assetSymbol}`);
      refetchAllowance?.();
      refetchErc20Balance?.();
      onSuccess?.();
      onClose();
    } catch (error: any) {
      console.error("Approval failed", error);
      notification.error(error?.message || "授权失败");
    } finally {
      setIsApproving(false);
    }
  };

  const handleDeposit = async () => {
    if (!connectedAddress || !isValidDepositAmount) return;

    const depositAmountDisplay = amountInput;
    setIsProcessing(true);
    try {
      if (isETHVault) {
        if (!vaultEthInfo?.abi) {
          notification.error("缺少金库合约 ABI");
          return;
        }

        const value = parseEther(amountInput);

        const makeWriteWithParams = () =>
          writeContractAsync({
            address: vault.address as `0x${string}`,
            abi: vaultEthInfo.abi,
            functionName: "depositETH",
            args: [connectedAddress],
            value,
          });

        await writeTx(makeWriteWithParams, {
          onTransactionSubmitted: () => {
            onClose();
          },
          onBlockConfirmation: receipt => {
            console.debug("Deposit ETH confirmed", receipt);
            notification.success(`成功存入 ${depositAmountDisplay} ETH`);
            refetchEthBalance?.();
            onSuccess?.();
          },
        });
      } else {
        if (!vaultImplInfo?.abi) {
          notification.error("缺少金库合约 ABI");
          return;
        }

        const amountBigInt = parseUnits(amountInput, assetDecimals);

        const makeWriteWithParams = () =>
          writeContractAsync({
            address: vault.address as `0x${string}`,
            abi: vaultImplInfo.abi,
            functionName: "deposit",
            args: [amountBigInt, connectedAddress],
          });

        await writeTx(makeWriteWithParams, {
          onTransactionSubmitted: () => {
            onClose();
          },
          onBlockConfirmation: receipt => {
            console.debug("Deposit confirmed", receipt);
            notification.success(`成功存入 ${depositAmountDisplay} ${assetSymbol}`);
            refetchErc20Balance?.();
            refetchAllowance?.();
            onSuccess?.();
          },
        });
      }
    } catch (error: any) {
      console.error("Deposit failed", error);
      notification.error(error?.message || "存入失败");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleMint = async () => {
    if (!connectedAddress || !isValidShareAmount) return;

    const shareAmountDisplay = shareInput;
    setIsProcessing(true);
    try {
      if (isETHVault) {
        if (!vaultEthInfo?.abi) {
          notification.error("缺少金库合约 ABI");
          return;
        }

        const sharesBigInt = parseEther(shareInput);
        const value = requiredAssetBigInt;

        const makeWriteWithParams = () =>
          writeContractAsync({
            address: vault.address as `0x${string}`,
            abi: vaultEthInfo.abi,
            functionName: "mintETH",
            args: [sharesBigInt, connectedAddress],
            value,
          });

        await writeTx(makeWriteWithParams, {
          onTransactionSubmitted: () => {
            onClose();
          },
          onBlockConfirmation: receipt => {
            console.debug("Mint ETH confirmed", receipt);
            notification.success(`成功铸造 ${shareAmountDisplay} v${displayAssetSymbol}`);
            refetchEthBalance?.();
            onSuccess?.();
          },
        });
      } else {
        if (!vaultImplInfo?.abi) {
          notification.error("缺少金库合约 ABI");
          return;
        }

        const sharesBigInt = parseUnits(shareInput, assetDecimals);

        const makeWriteWithParams = () =>
          writeContractAsync({
            address: vault.address as `0x${string}`,
            abi: vaultImplInfo.abi,
            functionName: "mint",
            args: [sharesBigInt, connectedAddress],
          });

        await writeTx(makeWriteWithParams, {
          onTransactionSubmitted: () => {
            onClose();
          },
          onBlockConfirmation: receipt => {
            console.debug("Mint confirmed", receipt);
            notification.success(`成功铸造 ${shareAmountDisplay} v${assetSymbol}`);
            refetchErc20Balance?.();
            refetchAllowance?.();
            onSuccess?.();
          },
        });
      }
    } catch (error: any) {
      console.error("Mint failed", error);
      notification.error(error?.message || "铸造失败");
    } finally {
      setIsProcessing(false);
    }
  };

  const handleMaxClick = () => {
    if (mode === "deposit") {
      if (isETHVault) {
        if (!ethBalance?.value) return;
        const gasReserve = parseEther("0.01");
        const maxAmount = ethBalance.value > gasReserve ? ethBalance.value - gasReserve : 0n;
        setAmountInput(formatEther(maxAmount));
      } else {
        if (erc20Balance === undefined) return;
        setAmountInput(formatUnits(erc20Balance, assetDecimals));
      }
    } else {
      if (isETHVault) {
        if (!ethBalance?.value) return;
        const gasReserve = parseEther("0.01");
        const spendable = ethBalance.value > gasReserve ? ethBalance.value - gasReserve : 0n;
        if (totalAssets === 0n || totalSupply === 0n) {
          setShareInput(formatEther(spendable));
        } else {
          const maxShares = (spendable * totalSupply) / totalAssets;
          setShareInput(formatEther(maxShares));
        }
      } else {
        if (erc20Balance === undefined) return;
        if (totalAssets === 0n || totalSupply === 0n) {
          setShareInput(formatUnits(erc20Balance, assetDecimals));
        } else {
          const maxShares = (erc20Balance * totalSupply) / totalAssets;
          setShareInput(formatUnits(maxShares, assetDecimals));
        }
      }
    }
  };

  const handleClose = () => {
    onClose();
  };

  if (!isOpen || !isMounted) return null;

  const formattedUserBalance = `${isETHVault ? formatTokenAmount(ethBalance?.value, 18) : formatTokenAmount(erc20Balance, assetDecimals)} ${displayAssetSymbol}`;
  const formattedAllowance = isETHVault ? "无需授权" : `${formatTokenAmount(allowance, assetDecimals)} ${assetSymbol}`;
  const formattedTotalAssets = `${formatTokenAmount(totalAssets, assetDecimals)} ${assetSymbol}`;
  const formattedTotalSupply = `${formatTokenAmount(totalSupply, assetDecimals, 4)} v${assetSymbol}`;

  const renderSummaryPanel = (primaryValue: string, previewLabel: string, previewValue: string) => (
    <div className="grid gap-3 text-sm md:grid-cols-2">
      <div className="rounded-xl border border-base-200/60 bg-base-200/30 p-3">
        <p className="text-xs uppercase tracking-widest text-primary">交易概要</p>
        <div className="mt-2 space-y-1.5">
          <div className="flex items-center justify-between">
            <span className="opacity-70">操作金额</span>
            <span className="font-semibold">{primaryValue}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="opacity-70">{previewLabel}</span>
            <span className="font-semibold">{previewValue}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="opacity-70">账户余额</span>
            <span className="font-semibold">{formattedUserBalance}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="opacity-70">授权额度</span>
            <span className={`font-semibold ${needsApproval ? "text-warning" : ""}`}>{formattedAllowance}</span>
          </div>
        </div>
      </div>

      <div className="rounded-xl border border-base-200/60 bg-base-200/30 p-3">
        <p className="text-xs uppercase tracking-widest text-primary">金库概览</p>
        <div className="mt-2 space-y-1.5">
          <div className="flex items-center justify-between">
            <span className="opacity-70">当前 TVL</span>
            <span className="font-semibold">{formattedTotalAssets}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="opacity-70">总份额</span>
            <span className="font-semibold">{formattedTotalSupply}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="opacity-70">兑换比率</span>
            <span className="font-semibold">
              1 v{assetSymbol} ≈ {exchangeRateNumber.toFixed(4)} {displayAssetSymbol}
            </span>
          </div>
          {isETHVault && nativePrice > 0 && (
            <div className="flex items-center justify-between">
              <span className="opacity-70">ETH 估值</span>
              <span className="font-semibold">
                ${nativePrice.toLocaleString(undefined, { maximumFractionDigits: 0 })}
              </span>
            </div>
          )}
        </div>
      </div>
    </div>
  );

  const depositContent = (
    <div className="space-y-4">
      <section className="rounded-xl border border-base-200 bg-base-100 p-4 shadow-sm">
        <label className="label px-0 pt-0">
          <span className="label-text text-xs uppercase tracking-widest text-primary">输入金额</span>
        </label>
        <div className="join w-full">
          <input
            type="number"
            step="any"
            value={amountInput}
            onChange={e => setAmountInput(e.target.value)}
            placeholder="0.00"
            className="input input-bordered join-item flex-1 min-w-0 text-lg"
          />
          <span className="btn btn-square join-item bg-base-200 border-base-300 no-animation flex-none h-10 w-[50px] min-h-0">
            {displayAssetSymbol}
          </span>
          <button onClick={handleMaxClick} className="btn btn-primary join-item">
            最大
          </button>
        </div>
        <p className="mt-2 text-xs opacity-70">可用余额 {formattedUserBalance}</p>
      </section>

      <section className="grid gap-3 md:grid-cols-2">
        <div className="rounded-xl border border-primary/30 bg-primary/10 p-3">
          <p className="text-xs uppercase tracking-widest text-primary">预计份额</p>
          <p className="mt-2 text-2xl font-semibold text-primary">
            {amountInput && isValidDepositAmount ? `~${formatNumericString(estimatedShares)}` : "—"} v{assetSymbol}
          </p>
          <p className="mt-2 text-sm opacity-70">
            当前比率 1 {displayAssetSymbol} ≈ {(1 / exchangeRateNumber).toFixed(4)} v{assetSymbol}
          </p>
          {isETHVault && usdPreviewForAmount !== "-" && (
            <p className="text-xs opacity-70">≈ ${usdPreviewForAmount} USD</p>
          )}
        </div>
        <div className="rounded-xl border border-base-200 p-3">
          <p className="text-xs uppercase tracking-widest text-primary">注意事项</p>
          <ul className="mt-2 space-y-1 text-sm opacity-80">
            <li>· 存入资产将自动部署至多策略组合</li>
            <li>· 预计 1-2 个区块完成确认</li>
            <li>· 需保留少量 {displayAssetSymbol} 用于 Gas</li>
          </ul>
        </div>
      </section>

      {renderSummaryPanel(
        amountInput ? `${amountInput} ${displayAssetSymbol}` : "—",
        "预计获得",
        amountInput && isValidDepositAmount ? `~${formatNumericString(estimatedShares)} v${assetSymbol}` : "—",
      )}

      <div className="flex flex-wrap justify-center gap-3 pt-1">
        <button onClick={handleClose} className="btn btn-ghost min-w-[120px]">
          取消
        </button>
        {needsApproval ? (
          <button
            onClick={handleApprove}
            disabled={isApproving || !isValidDepositAmount}
            className="btn btn-primary min-w-[140px]"
          >
            {isApproving ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                授权中...
              </>
            ) : (
              `🔓 授权 ${assetSymbol}`
            )}
          </button>
        ) : (
          <button
            onClick={handleDeposit}
            disabled={isProcessing || !isValidDepositAmount || !connectedAddress}
            className="btn btn-primary min-w-[140px]"
          >
            {isProcessing ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                处理中...
              </>
            ) : (
              "💰 确认存入"
            )}
          </button>
        )}
      </div>
    </div>
  );

  const mintContent = (
    <div className="space-y-4">
      <section className="space-y-4">
        <div className="rounded-xl border border-base-200 bg-base-100 p-4 shadow-sm">
          <label className="label px-0 pt-0">
            <span className="label-text text-xs uppercase tracking-widest text-primary">输入份额</span>
          </label>
          <div className="join w-full">
            <input
              type="number"
              step="any"
              value={shareInput}
              onChange={e => setShareInput(e.target.value)}
              placeholder="0.00"
              className="input input-bordered join-item flex-1 min-w-0 text-lg"
            />
            <span className="btn btn-square join-item bg-base-200 border-base-300 no-animation flex-none h-10 w-[50px] min-h-0">
              v{assetSymbol}
            </span>
            <button onClick={handleMaxClick} className="btn btn-primary join-item">
              最大
            </button>
          </div>
          <p className="mt-2 text-xs opacity-70">可用余额 {formattedUserBalance}</p>
        </div>

        <div className="grid gap-3 md:grid-cols-2">
          <div className="rounded-xl border border-primary/30 bg-primary/10 p-3">
            <p className="text-xs uppercase tracking-widest text-primary">预计支付</p>
            <p className="mt-2 text-2xl font-semibold text-primary">
              {shareInput && isValidShareAmount ? `~${formatNumericString(requiredAssetsForShares)}` : "—"}{" "}
              {displayAssetSymbol}
            </p>
            <p className="mt-2 text-sm opacity-70">
              当前比率 1 v{assetSymbol} ≈ {exchangeRateNumber.toFixed(4)} {displayAssetSymbol}
            </p>
            {isETHVault && usdPreviewForShares !== "-" && (
              <p className="text-xs opacity-70">≈ ${usdPreviewForShares} USD</p>
            )}
          </div>
          <div className="rounded-xl border border-base-200 p-3">
            <p className="text-xs uppercase tracking-widest text-primary">操作说明</p>
            <ul className="mt-2 space-y-1 text-sm opacity-80">
              <li>· 按当前汇率一次性铸造所需份额</li>
              <li>· 实际消耗资产以链上结算为准</li>
              <li>· 网络拥堵可能导致 Gas 成本波动</li>
            </ul>
          </div>
        </div>
      </section>

      {renderSummaryPanel(
        shareInput ? `${shareInput} v${assetSymbol}` : "—",
        "预计支付",
        shareInput && isValidShareAmount
          ? `~${formatNumericString(requiredAssetsForShares)} ${displayAssetSymbol}`
          : "—",
      )}

      <div className="flex flex-wrap justify-center gap-3 pt-1">
        <button onClick={handleClose} className="btn btn-ghost min-w-[120px]">
          取消
        </button>
        {needsApproval ? (
          <button
            onClick={handleApprove}
            disabled={isApproving || !isValidShareAmount}
            className="btn btn-primary min-w-[140px]"
          >
            {isApproving ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                授权中...
              </>
            ) : (
              `🔓 授权 ${assetSymbol}`
            )}
          </button>
        ) : (
          <button
            onClick={handleMint}
            disabled={isProcessing || !isValidShareAmount || !connectedAddress}
            className="btn btn-primary min-w-[140px]"
          >
            {isProcessing ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                处理中...
              </>
            ) : (
              "🪙 确认铸造"
            )}
          </button>
        )}
      </div>
    </div>
  );

  const modalContent = (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={handleClose}></div>
      <div
        className="relative z-10 w-full max-w-4xl max-h-[90vh] overflow-y-auto rounded-2xl border border-primary/40 bg-base-100 shadow-2xl"
        onClick={event => event.stopPropagation()}
      >
        <button onClick={handleClose} className="btn btn-sm btn-circle btn-ghost absolute right-4 top-4 z-30">
          ✕
        </button>
        <div className="px-5 py-5 space-y-4">
          <div className="space-y-3">
            <div>
              <p className="text-xs uppercase tracking-[0.35em] text-primary">Vault Actions</p>
              <h3 className="mt-1 text-2xl font-bold">💰 金库存入操作</h3>
              <p className="mt-1 text-xs opacity-70">选择直接存入资产或按目标份额铸造 v{assetSymbol}。</p>
            </div>
            <div className="grid grid-cols-2 gap-1">
              <button
                className={`tab tab-lifted h-9 w-full ${mode === "deposit" ? "tab-active" : ""}`}
                onClick={() => {
                  setMode("deposit");
                  setShareInput("");
                }}
              >
                存入
              </button>
              <button
                className={`tab tab-lifted h-9 w-full ${mode === "mint" ? "tab-active" : ""}`}
                onClick={() => {
                  setMode("mint");
                  setAmountInput("");
                }}
              >
                按份额铸造
              </button>
            </div>
          </div>

          <div>{mode === "deposit" ? depositContent : mintContent}</div>
        </div>
      </div>
    </div>
  );

  return createPortal(modalContent, document.body);
};
