"use client";

import { useEffect, useMemo, useState } from "react";
import { erc20Abi, formatUnits, isAddress, parseUnits } from "viem";
import { useAccount, usePublicClient, useReadContract, useWriteContract } from "wagmi";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type MintModalProps = {
  vault: Vault;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

export const MintModal = ({ vault, isOpen, onClose, onSuccess }: MintModalProps) => {
  const [shares, setShares] = useState("");
  const [isMinting, setIsMinting] = useState(false);
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

  // Mint 合约
  const { writeContractAsync: mintAsync } = useScaffoldWriteContract({
    contractName: "VaultImplementation",
  });

  const safeBigInt = (value?: string) => {
    try {
      return BigInt(value || "0");
    } catch {
      return 0n;
    }
  };

  // 计算需要支付的资产数量
  const requiredAssets = useMemo(() => {
    if (!shares || !vault.totalAssets || !vault.totalSupply) return "0";

    try {
      const sharesBigInt = parseUnits(shares, assetDecimals);
      const totalAssets = safeBigInt(vault.totalAssets);
      const totalSupply = safeBigInt(vault.totalSupply);

      if (totalSupply === 0n) {
        // 如果是第一次铸造，1:1 比例
        return formatUnits(sharesBigInt, assetDecimals);
      }

      // assets = shares * totalAssets / totalSupply
      const assets = (sharesBigInt * totalAssets) / totalSupply;
      return formatUnits(assets, assetDecimals);
    } catch {
      return "0";
    }
  }, [shares, vault.totalAssets, vault.totalSupply, assetDecimals]);

  const formattedRequiredAssets = useMemo(() => {
    const numeric = Number(requiredAssets);
    if (!Number.isFinite(numeric)) {
      return requiredAssets;
    }
    return numeric.toLocaleString(undefined, { maximumFractionDigits: 4 });
  }, [requiredAssets]);

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
    if (!requiredAssets || !allowance || requiredAssets === "0" || !isSupportedAsset) {
      setNeedsApproval(false);
      return;
    }

    try {
      const requiredAssetsBigInt = parseUnits(requiredAssets, assetDecimals);
      setNeedsApproval(allowance < requiredAssetsBigInt);
    } catch {
      setNeedsApproval(false);
    }
  }, [requiredAssets, allowance, assetDecimals, isSupportedAsset]);

  const handleMaxClick = () => {
    if (userBalance !== undefined && vault.totalAssets && vault.totalSupply) {
      const totalAssets = safeBigInt(vault.totalAssets);
      const totalSupply = safeBigInt(vault.totalSupply);

      if (totalSupply === 0n) {
        setShares(formatUnits(userBalance, assetDecimals));
      } else {
        // maxShares = userBalance * totalSupply / totalAssets
        const maxShares = (userBalance * totalSupply) / totalAssets;
        setShares(formatUnits(maxShares, assetDecimals));
      }
    }
  };

  const handleApprove = async () => {
    if (!connectedAddress || !requiredAssets) return;

    setIsApproving(true);
    try {
      if (!isSupportedAsset) {
        notification.error("无法识别的资产地址");
        return;
      }

      const requiredAssetsBigInt = parseUnits(requiredAssets, assetDecimals);

      const hash = await writeTokenAsync({
        abi: erc20Abi,
        address: assetAddress as `0x${string}`,
        functionName: "approve",
        args: [vault.address as `0x${string}`, requiredAssetsBigInt],
      });

      if (publicClient) {
        await publicClient.waitForTransactionReceipt({ hash });
      }

      notification.success(`已授权 ${requiredAssets} ${assetSymbol}`);
      refetchAllowance();
      refetchUserBalance();
    } catch (error: any) {
      console.error("Approval failed:", error);
      notification.error(error?.message || "授权失败");
    } finally {
      setIsApproving(false);
    }
  };

  const handleMint = async () => {
    if (!connectedAddress || !shares) return;

    setIsMinting(true);
    try {
      const sharesBigInt = parseUnits(shares, assetDecimals);

      await mintAsync(
        {
          address: vault.address as `0x${string}`,
          functionName: "mint",
          args: [sharesBigInt, connectedAddress],
        },
        {
          onBlockConfirmation: receipt => {
            console.debug("Mint confirmed", receipt);
            notification.success(`成功铸造 ${shares} v${assetSymbol}!`);
            setShares("");
            refetchUserBalance();
            refetchAllowance();
            onSuccess?.();
            onClose();
          },
        },
      );
    } catch (error: any) {
      console.error("Mint failed:", error);
      notification.error(error?.message || "铸造失败");
    } finally {
      setIsMinting(false);
    }
  };

  const formatBalance = (balance: bigint | undefined) => {
    if (balance === undefined) return "0";
    const formatted = formatUnits(balance, assetDecimals);
    const num = parseFloat(formatted);
    return num.toLocaleString(undefined, { maximumFractionDigits: 2 });
  };

  const isValidShares = useMemo(() => {
    if (!shares || !isSupportedAsset) return false;
    try {
      const sharesBigInt = parseUnits(shares, assetDecimals);
      const requiredAssetsBigInt = parseUnits(requiredAssets, assetDecimals);
      return sharesBigInt > 0n && (!userBalance || requiredAssetsBigInt <= userBalance);
    } catch {
      return false;
    }
  }, [shares, requiredAssets, userBalance, assetDecimals, isSupportedAsset]);

  if (!isOpen) return null;

  return (
    <div className="modal modal-open">
      <div className="modal-box max-w-2xl">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-2xl font-bold">📈 按份额购买金库代币</h3>
          <button onClick={onClose} className="btn btn-sm btn-circle btn-ghost">
            ✕
          </button>
        </div>

        {/* Info Notice */}
        <div className="alert alert-info mb-6">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            className="stroke-current shrink-0 w-5 h-5"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            ></path>
          </svg>
          <div className="text-sm">
            <p className="font-semibold">💡 说明</p>
            <p className="opacity-80">直接指定想要获得的份额数量，系统计算需要的资产</p>
          </div>
        </div>

        {/* Vault Info */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-lg font-semibold">🏦 {vault.name}</p>
              <p className="text-xs opacity-70">
                当前汇率: 1 v{assetSymbol} = {exchangeRate} {assetSymbol}
              </p>
            </div>
            <div className="text-right">
              <p className="text-sm opacity-70">总份额</p>
              <p className="text-lg font-bold">
                {formatBalance(safeBigInt(vault.totalSupply))} v{assetSymbol}
              </p>
            </div>
          </div>
        </div>

        {/* Shares Input */}
        <div className="mb-6">
          <label className="label">
            <span className="label-text font-semibold">购买份额</span>
          </label>
          <div className="join w-full">
            <input
              type="number"
              step="any"
              value={shares}
              onChange={e => setShares(e.target.value)}
              placeholder="0.00"
              className="input input-bordered join-item w-full text-lg"
            />
            <span className="btn btn-square join-item bg-base-200 border-base-300 no-animation">v{assetSymbol}</span>
            <button onClick={handleMaxClick} className="btn btn-primary join-item">
              最大
            </button>
          </div>
        </div>

        {/* Required Assets */}
        {shares && isValidShares && (
          <div className="bg-primary/10 p-4 rounded-lg mb-6">
            <p className="text-sm font-semibold mb-2">需要支付</p>
            <p className="text-2xl font-bold text-primary">
              ~{formattedRequiredAssets} {assetSymbol}
            </p>
            <p className="text-xs opacity-70 mt-1">
              (当前汇率: 1 v{assetSymbol} = {exchangeRate} {assetSymbol})
            </p>
          </div>
        )}

        {/* Balance Display */}
        <label className="label">
          <span className="label-text-alt">
            可用余额: {formatBalance(userBalance)} {assetSymbol}
          </span>
        </label>

        {/* Approval Status */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <p className="text-sm font-semibold mb-2">授权状态</p>
          {!isSupportedAsset ? (
            <div className="flex items-center gap-2 text-warning">
              <span>⚠️</span>
              <span className="text-sm">无法识别资产合约地址</span>
            </div>
          ) : allowance && allowance > 0n ? (
            <div className="flex items-center gap-2">
              {needsApproval ? (
                <>
                  <span className="text-warning">⚠️</span>
                  <span className="text-sm">
                    需要授权 {formattedRequiredAssets} {assetSymbol}
                  </span>
                </>
              ) : (
                <>
                  <span className="text-success">✅</span>
                  <span className="text-sm">已授权，可以铸造</span>
                </>
              )}
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <span className="text-warning">⚠️</span>
              <span className="text-sm">需要授权才能铸造</span>
            </div>
          )}
          {needsApproval && isSupportedAsset && (
            <p className="text-xs text-warning mt-2">当前授权额度不足，需要增加授权</p>
          )}
        </div>

        {/* Advantages */}
        <div className="alert mb-6">
          <div className="text-xs">
            <p className="font-semibold mb-1">✨ 优势</p>
            <ul className="list-disc list-inside space-y-1 opacity-80">
              <li>精确控制持仓份额</li>
              <li>适合定投策略</li>
              <li>份额价格可能实时波动</li>
            </ul>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button onClick={onClose} className="btn btn-ghost flex-1">
            取消
          </button>
          {needsApproval ? (
            <button onClick={handleApprove} disabled={isApproving || !isValidShares} className="btn btn-primary flex-1">
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
              disabled={isMinting || !isValidShares || !connectedAddress}
              className="btn btn-primary flex-1"
            >
              {isMinting ? (
                <>
                  <span className="loading loading-spinner loading-sm"></span>
                  铸造中...
                </>
              ) : (
                "📈 确认购买"
              )}
            </button>
          )}
        </div>
      </div>
      <div className="modal-backdrop bg-black/50" onClick={onClose}></div>
    </div>
  );
};
