"use client";

import { useMemo, useState } from "react";
import { formatEther, parseEther } from "viem";
import { useAccount, useBalance, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import { useGlobalState } from "~~/services/store/store";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type DepositETHModalProps = {
  vault: Vault;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

export const DepositETHModal = ({ vault, isOpen, onClose, onSuccess }: DepositETHModalProps) => {
  const [amount, setAmount] = useState("");
  const [isDepositing, setIsDepositing] = useState(false);

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

  // 计算用户将获得的份额
  const estimatedShares = useMemo(() => {
    if (!amount || !vault.totalAssets || !vault.totalSupply) return "0";

    try {
      const amountBigInt = parseEther(amount);
      const totalAssets = safeBigInt(vault.totalAssets);
      const totalSupply = safeBigInt(vault.totalSupply);

      if (totalSupply === 0n || totalAssets === 0n) {
        return formatEther(amountBigInt);
      }

      const shares = (amountBigInt * totalSupply) / totalAssets;
      return formatEther(shares);
    } catch {
      return "0";
    }
  }, [amount, vault.totalAssets, vault.totalSupply]);

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

  // 计算 USD 估值 (假设 ETH = $3,246)
  const usdValue = useMemo(() => {
    if (!amount) return "0";
    try {
      const ethAmount = parseFloat(amount);
      const usdAmount = ethAmount * (nativePrice || 0);
      return usdAmount.toLocaleString(undefined, { maximumFractionDigits: 0 });
    } catch {
      return "0";
    }
  }, [amount, nativePrice]);

  const handleMaxClick = () => {
    if (ethBalance?.value) {
      // 保留一些 ETH 用于 Gas
      const gasReserve = parseEther("0.01");
      const maxAmount = ethBalance.value > gasReserve ? ethBalance.value - gasReserve : 0n;
      setAmount(formatEther(maxAmount));
    }
  };

  const handleDeposit = async () => {
    if (!connectedAddress || !amount) return;

    if (!vaultContractInfo?.abi) {
      notification.error("Vault contract ABI not available");
      return;
    }

    setIsDepositing(true);
    try {
      const amountBigInt = parseEther(amount);

      const makeWriteWithParams = () =>
        writeContractAsync({
          address: vault.address as `0x${string}`,
          abi: vaultContractInfo.abi,
          functionName: "depositETH",
          args: [connectedAddress],
          value: amountBigInt,
        });

      await writeTx(makeWriteWithParams, {
        onBlockConfirmation: receipt => {
          console.debug("ETH Deposit confirmed", receipt);
          notification.success(`成功存入 ${amount} ETH!`);
          setAmount("");
          onSuccess?.();
          onClose();
        },
      });
    } catch (error: any) {
      console.error("ETH Deposit failed:", error);
      notification.error(error?.message || "存款失败");
    } finally {
      setIsDepositing(false);
    }
  };

  const formatBalance = (balance: bigint | undefined) => {
    if (balance === undefined) return "0";
    const formatted = formatEther(balance);
    const num = parseFloat(formatted);
    return num.toLocaleString(undefined, { maximumFractionDigits: 4 });
  };

  const isValidAmount = useMemo(() => {
    if (!amount || !ethBalance?.value) return false;
    try {
      const amountBigInt = parseEther(amount);
      // 确保留够 Gas
      const gasReserve = parseEther("0.01");
      return amountBigInt > 0n && amountBigInt <= ethBalance.value - gasReserve;
    } catch {
      return false;
    }
  }, [amount, ethBalance]);

  if (!isOpen) return null;

  return (
    <div className="modal modal-open">
      <div className="modal-box max-w-2xl">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <h3 className="text-2xl font-bold">Ξ 存入 ETH 到 WETH 金库</h3>
          <button onClick={onClose} className="btn btn-sm btn-circle btn-ghost">
            ✕
          </button>
        </div>

        {/* Special Notice */}
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
            <p className="font-semibold">💡 特殊说明</p>
            <p className="opacity-80">您存入的 ETH 将自动转换为 WETH 并投资到各协议</p>
          </div>
        </div>

        {/* Vault Info */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-lg font-semibold">🏦 {vault.name}</p>
              <p className="text-xs opacity-70">
                地址: {vault.address.slice(0, 10)}...{vault.address.slice(-8)}
              </p>
            </div>
            <div className="text-right">
              <p className="text-sm opacity-70">当前 APY</p>
              <p className="text-xl font-bold text-success">9.2%</p>
            </div>
          </div>
          <div className="divider my-2"></div>
          <div className="flex justify-between text-sm">
            <span className="opacity-70">TVL</span>
            <span className="font-semibold">{formatBalance(safeBigInt(vault.totalAssets))} WETH</span>
          </div>
        </div>

        {/* Deposit Amount */}
        <div className="mb-6">
          <label className="label">
            <span className="label-text font-semibold">存款金额</span>
          </label>
          <div className="join w-full">
            <input
              type="number"
              step="any"
              value={amount}
              onChange={e => setAmount(e.target.value)}
              placeholder="0.00"
              className="input input-bordered join-item w-full text-lg"
            />
            <span className="btn btn-square join-item bg-base-200 border-base-300 no-animation">Ξ ETH</span>
            <button onClick={handleMaxClick} className="btn btn-primary join-item">
              最大
            </button>
          </div>
          <label className="label">
            <span className="label-text-alt">可用余额: {formatBalance(ethBalance?.value)} ETH</span>
            {amount && <span className="label-text-alt opacity-70">≈ ${usdValue} USD</span>}
          </label>
        </div>

        {/* Estimated Shares */}
        {amount && isValidAmount && (
          <div className="bg-primary/10 p-4 rounded-lg mb-6">
            <p className="text-sm font-semibold mb-2">您将获得</p>
            <p className="text-2xl font-bold text-primary">
              ~{parseFloat(estimatedShares).toLocaleString(undefined, { maximumFractionDigits: 4 })} vWETH
            </p>
            <p className="text-xs opacity-70 mt-1">(自动转换: ETH → WETH → vWETH)</p>
            <p className="text-xs opacity-70 mt-1">
              (当前汇率: 1 ETH = {(1 / parseFloat(exchangeRate)).toFixed(4)} vWETH)
            </p>
          </div>
        )}

        {/* No Approval Needed */}
        <div className="bg-success/10 p-4 rounded-lg mb-6 border border-success/20">
          <div className="flex items-center gap-2">
            <span className="text-success text-2xl">✨</span>
            <div>
              <p className="text-sm font-semibold text-success">无需授权</p>
              <p className="text-xs opacity-70">ETH 直接存入，无需代币授权流程</p>
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
              <li>资金将自动分配到各 DeFi 协议</li>
              <li>预计需要 1-2 个区块确认</li>
              <li>已为您保留 0.01 ETH 作为 Gas 费用</li>
              <li>管理费: 1.00% (从收益中扣除)</li>
            </ul>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button onClick={onClose} className="btn btn-ghost flex-1">
            取消
          </button>
          <button
            onClick={handleDeposit}
            disabled={isDepositing || !isValidAmount || !connectedAddress}
            className="btn btn-primary flex-1"
          >
            {isDepositing ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                存款中...
              </>
            ) : (
              "Ξ 确认存款 ETH"
            )}
          </button>
        </div>
      </div>
      <div className="modal-backdrop bg-black/50" onClick={onClose}></div>
    </div>
  );
};
