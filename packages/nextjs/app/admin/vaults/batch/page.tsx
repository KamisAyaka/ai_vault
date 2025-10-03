"use client";

import { useRef } from "react";
import Link from "next/link";
import { BatchVaultCreation } from "~~/components/admin/BatchVaultCreation";
import { useGsapFadeReveal, useGsapHeroIntro } from "~~/hooks/useGsapAnimations";

const BatchVaultCreationPage = () => {
  const handleSuccess = () => {
    console.log("Batch vaults created successfully");
    // Could add router.push to redirect or refetch data
  };

  const heroRef = useRef<HTMLDivElement | null>(null);
  const infoRef = useRef<HTMLDivElement | null>(null);
  const guideRef = useRef<HTMLDivElement | null>(null);
  const addressRef = useRef<HTMLDivElement | null>(null);

  useGsapHeroIntro(heroRef);
  useGsapFadeReveal(infoRef, ".batch-alert-line");
  useGsapFadeReveal(guideRef, ".batch-guide-card");
  useGsapFadeReveal(addressRef, ".batch-address-card");

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex justify-between items-center mb-8" ref={heroRef}>
        <div>
          <h1 className="hero-heading text-4xl font-bold mb-2">🏗️ 批量创建金库</h1>
          <div className="hero-subheading text-sm breadcrumbs">
            <ul>
              <li>
                <Link href="/">Home</Link>
              </li>
              <li>
                <Link href="/admin/vaults">Admin</Link>
              </li>
              <li>Batch Vault Creation</li>
            </ul>
          </div>
        </div>

        <Link href="/admin/vaults/enhanced" className="hero-cta btn btn-outline">
          ← 返回管理后台
        </Link>
      </div>

      {/* Info Banner */}
      <div className="alert mb-8" ref={infoRef}>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          className="stroke-info shrink-0 w-6 h-6"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          ></path>
        </svg>
        <div className="batch-alert-line">
          <h3 className="font-bold">批量创建金库功能</h3>
          <div className="text-sm">通过表格或 CSV 文件一次性创建多个金库，节省时间和 Gas 费用</div>
        </div>
      </div>

      {/* Batch Creation Component */}
      <BatchVaultCreation onSuccess={handleSuccess} />

      {/* Usage Guide */}
      <div className="card bg-base-100 shadow-md mt-8" ref={guideRef}>
        <div className="card-body batch-guide-card">
          <h3 className="card-title">📖 使用指南</h3>

          <div className="space-y-4 mt-4">
            <div>
              <h4 className="font-semibold mb-2">1️⃣ 手动添加方式</h4>
              <ul className="list-disc list-inside text-sm opacity-80 space-y-1">
                <li>点击 {'"'}➕ 添加金库{'"'} 按钮添加新行</li>
                <li>填写每个金库的配置信息</li>
                <li>点击 {'"'}🚀 批量创建{'"'} 执行创建</li>
              </ul>
            </div>

            <div className="divider"></div>

            <div>
              <h4 className="font-semibold mb-2">2️⃣ CSV 导入方式</h4>
              <ul className="list-disc list-inside text-sm opacity-80 space-y-1">
                <li>准备 CSV 格式数据（逗号分隔）</li>
                <li>格式：name,assetAddress,assetSymbol,decimals,managementFeeBps</li>
                <li>示例：USDC Vault,0x1234...,USDC,6,100</li>
                <li>粘贴到文本框并点击 {'"'}📥 导入 CSV{'"'}</li>
              </ul>
            </div>

            <div className="divider"></div>

            <div>
              <h4 className="font-semibold mb-2">3️⃣ 字段说明</h4>
              <div className="overflow-x-auto">
                <table className="table table-sm">
                  <thead>
                    <tr>
                      <th>字段</th>
                      <th>说明</th>
                      <th>示例</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td className="font-semibold">name</td>
                      <td>金库名称</td>
                      <td>USDC Vault</td>
                    </tr>
                    <tr>
                      <td className="font-semibold">assetAddress</td>
                      <td>资产合约地址（ERC20）</td>
                      <td>0x1234567890123456789012345678901234567890</td>
                    </tr>
                    <tr>
                      <td className="font-semibold">assetSymbol</td>
                      <td>资产符号</td>
                      <td>USDC, WETH, DAI</td>
                    </tr>
                    <tr>
                      <td className="font-semibold">decimals</td>
                      <td>小数位数（1-18）</td>
                      <td>18 (ETH), 6 (USDC/USDT)</td>
                    </tr>
                    <tr>
                      <td className="font-semibold">managementFeeBps</td>
                      <td>管理费率（基点，100 = 1%）</td>
                      <td>100, 50</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div className="divider"></div>

            <div>
              <h4 className="font-semibold mb-2">⚠️ 注意事项</h4>
              <ul className="list-disc list-inside text-sm opacity-80 space-y-1">
                <li>确保资产合约地址有效且已部署在当前网络</li>
                <li>金库符号会自动添加 &quot;v&quot; 前缀（如 vUSDC）</li>
                <li>批量创建只需一笔交易，Gas 效率更高</li>
                <li>创建后无法修改金库资产，请仔细检查</li>
                <li>建议先在测试网验证配置</li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Common Asset Addresses */}
      <div className="card bg-base-100 shadow-md mt-8" ref={addressRef}>
        <div className="card-body batch-address-card">
          <h3 className="card-title">🔗 常用资产地址 (Mainnet)</h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
            <div className="bg-base-200 p-4 rounded-lg">
              <p className="font-semibold mb-2">💎 Stablecoins</p>
              <div className="space-y-1 text-sm font-mono">
                <div className="flex justify-between">
                  <span>USDC:</span>
                  <span className="opacity-70">0xA0b8...92Ca</span>
                </div>
                <div className="flex justify-between">
                  <span>USDT:</span>
                  <span className="opacity-70">0xdAC1...35EC</span>
                </div>
                <div className="flex justify-between">
                  <span>DAI:</span>
                  <span className="opacity-70">0x6B17...6EE0</span>
                </div>
              </div>
            </div>

            <div className="bg-base-200 p-4 rounded-lg">
              <p className="font-semibold mb-2">Ξ ETH & Wrapped</p>
              <div className="space-y-1 text-sm font-mono">
                <div className="flex justify-between">
                  <span>WETH:</span>
                  <span className="opacity-70">0xC02a...4d73</span>
                </div>
                <div className="flex justify-between">
                  <span>stETH:</span>
                  <span className="opacity-70">0xae7a...1652</span>
                </div>
              </div>
            </div>
          </div>

          <p className="text-xs opacity-70 mt-4">⚠️ 以上为主网地址示例，请根据实际部署网络使用正确的合约地址</p>
        </div>
      </div>
    </div>
  );
};

export default BatchVaultCreationPage;
