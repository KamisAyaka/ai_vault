"use client";

import { useMemo, useState } from "react";
import { formatEther, parseEther } from "viem";
import { useAccount, useBalance, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { useGlobalState } from "~~/services/store/store";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type MintETHModalProps = {
  vault: Vault;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

export const MintETHModal = ({ vault, isOpen, onClose, onSuccess }: MintETHModalProps) => {
  const [shares, setShares] = useState("");
  const [isMinting, setIsMinting] = useState(false);

  const { address: connectedAddress } = useAccount();
  const nativePrice = useGlobalState(state => state.nativeCurrency.price) || 0;

  const { data: vaultContractInfo } = useDeployedContractInfo({
    contractName: "VaultSharesETH",
  });

  const { writeContractAsync } = useWriteContract();
  const writeTx = useTransactor();

  // 获取用户 ETH 余额
  const { data: ethBalance } = useBalance({
    address: connectedAddress,
  });

  const safeBigInt = (value?: string) => {
    try {
      return BigInt(value || "0");
    } catch {
      return 0n;
    }
  };

  // 计算需要支付的 ETH 数量
  const requiredETH = useMemo(() => {
    if (!shares || !vault.totalAssets || !vault.totalSupply) return "0";

    try {
      const sharesBigInt = parseEther(shares);
      const totalAssets = safeBigInt(vault.totalAssets);
      const totalSupply = safeBigInt(vault.totalSupply);

      if (totalSupply === 0n) {
        return formatEther(sharesBigInt);
      }

      const eth = (sharesBigInt * totalAssets) / totalSupply;
      return formatEther(eth);
    } catch {
      return "0";
    }
  }, [shares, vault.totalAssets, vault.totalSupply]);

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

  // 计算 USD 估值
  const usdValue = useMemo(() => {
    if (!requiredETH) return "0";
    try {
      const ethAmount = parseFloat(requiredETH);
      const usdAmount = ethAmount * (nativePrice || 0);
      return usdAmount.toLocaleString(undefined, { maximumFractionDigits: 0 });
    } catch {
      return "0";
    }
  }, [requiredETH, nativePrice]);

  const handleMaxClick = () => {
    if (ethBalance?.value && vault.totalAssets && vault.totalSupply) {
      const gasReserve = parseEther("0.01");
      const maxETH = ethBalance.value > gasReserve ? ethBalance.value - gasReserve : 0n;

      const totalAssets = safeBigInt(vault.totalAssets);
      const totalSupply = safeBigInt(vault.totalSupply);

      if (totalSupply === 0n) {
        setShares(formatEther(maxETH));
      } else {
        const maxShares = (maxETH * totalSupply) / totalAssets;
        setShares(formatEther(maxShares));
      }
    }
  };

  const handleMint = async () => {
    if (!connectedAddress || !shares) return;

    if (!vaultContractInfo?.abi) {
      notification.error("Vault contract ABI not available");
      return;
    }

    setIsMinting(true);
    try {
      const sharesBigInt = parseEther(shares);
      const ethAmount = parseEther(requiredETH);

      const makeWriteWithParams = () =>
        writeContractAsync({
          address: vault.address as `0x${string}`,
          abi: vaultContractInfo.abi,
          functionName: "mintETH",
          args: [sharesBigInt, connectedAddress],
          value: ethAmount,
        });

      await writeTx(makeWriteWithParams, {
        onBlockConfirmation: receipt => {
          console.debug("MintETH confirmed", receipt);
          notification.success(`成功铸造 ${shares} vWETH!`);
          setShares("");
          onSuccess?.();
          onClose();
        },
      });
    } catch (error: any) {
      console.error("MintETH failed:", error);
      notification.error(error?.message || "铸造失败");
    } finally {
      setIsMinting(false);
    }
  };

  const formatBalance = (balance: bigint | undefined) => {
    if (balance === undefined) return "0";
    const formatted = formatEther(balance);
    const num = parseFloat(formatted);
    return num.toLocaleString(undefined, { maximumFractionDigits: 4 });
  };

  const isValidShares = useMemo(() => {
    if (!shares || !ethBalance?.value) return false;
    try {
      const ethAmount = parseEther(requiredETH);
      const gasReserve = parseEther("0.01");
      return ethAmount > 0n && ethAmount <= ethBalance.value - gasReserve;
    } catch {
      return false;
    }
  }, [shares, requiredETH, ethBalance]);

  if (!isOpen) return null;

  return (
    <div className="modal modal-open">
      <div className="modal-box max-w-2xl">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-2xl font-bold">Ξ 按份额购买 WETH 金库代币</h3>
          <button onClick={onClose} className="btn btn-sm btn-circle btn-ghost">
            ✕
          </button>
        </div>

        {/* Vault Info */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-lg font-semibold">🏦 {vault.name}</p>
              <p className="text-xs opacity-70">当前汇率: 1 vWETH = {exchangeRate} ETH</p>
            </div>
            <div className="text-right">
              <p className="text-sm opacity-70">总份额</p>
              <p className="text-lg font-bold">{formatBalance(safeBigInt(vault.totalSupply))} vWETH</p>
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
            <span className="btn btn-square join-item bg-base-200 border-base-300 no-animation">vWETH</span>
            <button onClick={handleMaxClick} className="btn btn-primary join-item">
              最大
            </button>
          </div>
        </div>

        {/* Required ETH */}
        {shares && isValidShares && (
          <div className="bg-primary/10 p-4 rounded-lg mb-6">
            <p className="text-sm font-semibold mb-2">需要支付</p>
            <p className="text-2xl font-bold text-primary">
              ~{parseFloat(requiredETH).toLocaleString(undefined, { maximumFractionDigits: 4 })} ETH
            </p>
            <p className="text-xs opacity-70 mt-1">≈ ${usdValue} USD</p>
          </div>
        )}

        {/* Balance Display */}
        <label className="label">
          <span className="label-text-alt">可用余额: {formatBalance(ethBalance?.value)} ETH</span>
        </label>

        {/* No Approval Needed */}
        <div className="bg-success/10 p-4 rounded-lg mb-6 border border-success/20">
          <div className="flex items-center gap-2">
            <span className="text-success text-2xl">✨</span>
            <div>
              <p className="text-sm font-semibold text-success">无需授权</p>
              <p className="text-xs opacity-70">ETH 直接支付，无需代币授权流程</p>
            </div>
          </div>
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
            <p className="font-semibold mb-1">⚠️ 重要提示</p>
            <ul className="list-disc list-inside space-y-1 opacity-80">
              <li>ETH 将自动转换为 WETH 后投资</li>
              <li>精确控制持仓份额数量</li>
              <li>已为您保留 0.01 ETH 作为 Gas 费用</li>
              <li>份额价格随市场实时波动</li>
            </ul>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button onClick={onClose} className="btn btn-ghost flex-1">
            取消
          </button>
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
              "Ξ 确认购买 ETH"
            )}
          </button>
        </div>
      </div>
      <div className="modal-backdrop bg-black/50" onClick={onClose}></div>
    </div>
  );
};
