"use client";

import { useMemo, useState } from "react";
import { formatUnits, parseUnits } from "viem";
import { useAccount, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useTransactor } from "~~/hooks/scaffold-eth";
import type { Vault } from "~~/types/vault";
import { notification } from "~~/utils/scaffold-eth";

type WithdrawETHModalProps = {
  vault: Vault;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
};

type WithdrawMode = "assets" | "shares";

export const WithdrawETHModal = ({ vault, isOpen, onClose, onSuccess }: WithdrawETHModalProps) => {
  const [mode, setMode] = useState<WithdrawMode>("assets");
  const [amount, setAmount] = useState("");
  const [isWithdrawing, setIsWithdrawing] = useState(false);

  const { address: connectedAddress } = useAccount();

  const assetDecimals = 18; // ETH always uses 18 decimals

  const { data: vaultContractInfo } = useDeployedContractInfo({
    contractName: "VaultSharesETH",
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
      notification.error("Vault contract ABI not available");
      return;
    }

    setIsWithdrawing(true);
    try {
      if (mode === "assets") {
        // 按资产数量取款 - 使用 withdrawETH
        const assetAmount = parseUnits(amount, assetDecimals);

        const makeWriteWithParams = () =>
          writeContractAsync({
            address: vault.address as `0x${string}`,
            abi: vaultContractInfo.abi,
            functionName: "withdrawETH",
            args: [assetAmount, connectedAddress, connectedAddress],
          });

        await writeTx(makeWriteWithParams, {
          onBlockConfirmation: receipt => {
            console.debug("Withdraw ETH confirmed", receipt);
            notification.success(`成功取款 ${amount} ETH!`);
            setAmount("");
            onSuccess?.();
            onClose();
          },
        });
      } else {
        // 按份额赎回 - 使用 redeemETH
        const shareAmount = parseUnits(amount, assetDecimals);

        const makeWriteWithParams = () =>
          writeContractAsync({
            address: vault.address as `0x${string}`,
            abi: vaultContractInfo.abi,
            functionName: "redeemETH",
            args: [shareAmount, connectedAddress, connectedAddress],
          });

        await writeTx(makeWriteWithParams, {
          onBlockConfirmation: receipt => {
            console.debug("Redeem ETH confirmed", receipt);
            notification.success(`成功赎回 ${amount} vETH!`);
            setAmount("");
            onSuccess?.();
            onClose();
          },
        });
      }
    } catch (error: any) {
      console.error("Withdraw/Redeem ETH failed:", error);
      notification.error(error?.message || "ETH取款操作失败");
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

  if (!isOpen) return null;

  const profitPercent = userPosition.value > 0n ? Number((userPosition.profit * 10000n) / userPosition.value) / 100 : 0;

  return (
    <div className="modal modal-open">
      <div className="modal-box max-w-2xl">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <div className="flex items-center gap-3">
            <div className="text-3xl">Ξ</div>
            <div>
              <h3 className="text-2xl font-bold">📤 ETH 金库取款</h3>
              <p className="text-sm opacity-70">{vault.name}</p>
            </div>
          </div>
          <button onClick={onClose} className="btn btn-sm btn-circle btn-ghost">
            ✕
          </button>
        </div>

        {/* Mode Toggle */}
        <div className="tabs tabs-boxed mb-6">
          <button
            className={`tab flex-1 ${mode === "assets" ? "tab-active" : ""}`}
            onClick={() => {
              setMode("assets");
              setAmount("");
            }}
          >
            按ETH取款
          </button>
          <button
            className={`tab flex-1 ${mode === "shares" ? "tab-active" : ""}`}
            onClick={() => {
              setMode("shares");
              setAmount("");
            }}
          >
            按份额赎回
          </button>
        </div>

        {/* User Position */}
        <div className="bg-base-200 p-4 rounded-lg mb-6">
          <p className="text-sm font-semibold mb-3">您的持仓</p>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <p className="text-xs opacity-70 mb-1">份额余额</p>
              <p className="font-semibold">{formatBalance(userPosition.shares)} vETH</p>
            </div>
            <div>
              <p className="text-xs opacity-70 mb-1">当前价值</p>
              <p className="font-semibold">~{formatBalance(userPosition.value)} ETH</p>
            </div>
            <div>
              <p className="text-xs opacity-70 mb-1">收益</p>
              <p className={`font-semibold ${userPosition.profit >= 0n ? "text-success" : "text-error"}`}>
                {userPosition.profit >= 0n ? "+" : ""}
                {formatBalance(userPosition.profit)} ETH
                <span className="text-xs ml-1">
                  ({userPosition.profit >= 0n ? "+" : ""}
                  {profitPercent.toFixed(2)}%)
                </span>
              </p>
            </div>
          </div>
        </div>

        {/* Withdraw Amount */}
        <div className="mb-6">
          <label className="label">
            <span className="label-text font-semibold">{mode === "assets" ? "取款金额" : "赎回份额"}</span>
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
            <span className="btn btn-square join-item bg-base-200 border-base-300 no-animation">
              {mode === "assets" ? "ETH" : "vETH"}
            </span>
            <button onClick={handleMaxClick} className="btn btn-error join-item">
              最大
            </button>
          </div>
        </div>

        {/* Estimation */}
        {amount && isValidAmount && (
          <div className="bg-error/10 p-4 rounded-lg mb-6">
            {mode === "assets" ? (
              <>
                <p className="text-sm font-semibold mb-2">需要赎回的份额</p>
                <p className="text-2xl font-bold text-error">
                  ~{parseFloat(estimation.shares).toLocaleString(undefined, { maximumFractionDigits: 4 })} vETH
                </p>
                <p className="text-xs opacity-70 mt-1">(当前汇率: 1 vETH = {exchangeRate} ETH)</p>
              </>
            ) : (
              <>
                <p className="text-sm font-semibold mb-2">您将获得</p>
                <p className="text-2xl font-bold text-error">
                  ~{parseFloat(estimation.assets).toLocaleString(undefined, { maximumFractionDigits: 4 })} ETH
                </p>
                <p className="text-xs opacity-70 mt-1">(当前汇率: 1 vETH = {exchangeRate} ETH)</p>
              </>
            )}
          </div>
        )}

        {/* Remaining Position */}
        {amount && isValidAmount && (
          <div className="bg-base-200 p-4 rounded-lg mb-6">
            <p className="text-sm font-semibold mb-3">取款后剩余</p>
            <ul className="space-y-2 text-sm">
              <li className="flex justify-between">
                <span className="opacity-70">剩余份额:</span>
                <span className="font-semibold">{formatBalance(remainingPosition.shares)} vETH</span>
              </li>
              <li className="flex justify-between">
                <span className="opacity-70">剩余价值:</span>
                <span className="font-semibold">~{formatBalance(remainingPosition.value)} ETH</span>
              </li>
            </ul>
          </div>
        )}

        {/* ETH-specific Processing Time */}
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
          <div className="text-xs">
            <p className="font-semibold">⏱️ ETH 处理时间</p>
            <p className="opacity-80">ETH金库需要从DeFi协议中撤出流动性，预计 2-5 分钟</p>
            <p className="opacity-80">取款将以原生ETH形式发送到您的钱包</p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button onClick={onClose} className="btn btn-ghost flex-1">
            取消
          </button>
          <button
            onClick={handleWithdraw}
            disabled={isWithdrawing || !isValidAmount || !connectedAddress}
            className="btn btn-error flex-1"
          >
            {isWithdrawing ? (
              <>
                <span className="loading loading-spinner loading-sm"></span>
                处理中...
              </>
            ) : (
              `📤 确认${mode === "assets" ? "ETH取款" : "份额赎回"}`
            )}
          </button>
        </div>
      </div>
      <div className="modal-backdrop bg-black/50" onClick={onClose}></div>
    </div>
  );
};
