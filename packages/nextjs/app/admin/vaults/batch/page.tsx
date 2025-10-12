"use client";

import { useRef } from "react";
import Link from "next/link";
import { BatchVaultCreation } from "~~/components/admin/BatchVaultCreation";
import { useGsapFadeReveal, useGsapHeroIntro } from "~~/hooks/useGsapAnimations";
import { useTranslations } from "~~/services/i18n/I18nProvider";

const BatchVaultCreationPage = () => {
  const t = useTranslations("admin.batchVaultPage");

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
          <h1 className="hero-heading text-4xl font-bold mb-2">🏗️ {t("title")}</h1>
          <div className="hero-subheading text-sm breadcrumbs">
            <ul>
              <li>
                <Link href="/">{t("breadcrumbs.home")}</Link>
              </li>
              <li>
                <Link href="/admin/vaults">{t("breadcrumbs.admin")}</Link>
              </li>
              <li>{t("breadcrumbs.batch")}</li>
            </ul>
          </div>
        </div>

        <Link href="/admin/vaults/enhanced" className="hero-cta btn btn-outline">
          {t("backButton")}
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
          <h3 className="font-bold">{t("infoBanner.title")}</h3>
          <div className="text-sm">{t("infoBanner.description")}</div>
        </div>
      </div>

      {/* Batch Creation Component */}
      <BatchVaultCreation onSuccess={handleSuccess} />

      {/* Usage Guide */}
      <div className="card bg-base-100 shadow-md mt-8" ref={guideRef}>
        <div className="card-body batch-guide-card">
          <h3 className="card-title">{t("guide.title")}</h3>

          <div className="space-y-4 mt-4">
            <div>
              <h4 className="font-semibold mb-2">{t("guide.manual.title")}</h4>
              <ul className="list-disc list-inside text-sm opacity-80 space-y-1">
                <li>{t("guide.manual.step1")}</li>
                <li>{t("guide.manual.step2")}</li>
                <li>{t("guide.manual.step3")}</li>
              </ul>
            </div>

            <div className="divider"></div>

            <div>
              <h4 className="font-semibold mb-2">{t("guide.csv.title")}</h4>
              <ul className="list-disc list-inside text-sm opacity-80 space-y-1">
                <li>{t("guide.csv.step1")}</li>
                <li>{t("guide.csv.step2")}</li>
                <li>{t("guide.csv.step3")}</li>
                <li>{t("guide.csv.step4")}</li>
              </ul>
            </div>

            <div className="divider"></div>

            <div>
              <h4 className="font-semibold mb-2">{t("guide.fields.title")}</h4>
              <div className="overflow-x-auto">
                <table className="table table-sm">
                  <thead>
                    <tr>
                      <th>{t("admin.batchVaultCreation.table.headers.symbol")}</th>
                      <th>{t("admin.batchVaultCreation.table.headers.name")}</th>
                      <th>{t("guide.fields.exampleName")}</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td className="font-semibold">name</td>
                      <td>{t("guide.fields.name")}</td>
                      <td>{t("guide.fields.exampleName")}</td>
                    </tr>
                    <tr>
                      <td className="font-semibold">assetAddress</td>
                      <td>{t("guide.fields.assetAddress")}</td>
                      <td>0x1234567890123456789012345678901234567890</td>
                    </tr>
                    <tr>
                      <td className="font-semibold">assetSymbol</td>
                      <td>{t("guide.fields.assetSymbol")}</td>
                      <td>{t("guide.fields.exampleSymbol")}</td>
                    </tr>
                    <tr>
                      <td className="font-semibold">decimals</td>
                      <td>{t("guide.fields.decimals")}</td>
                      <td>{t("guide.fields.exampleDecimals")}</td>
                    </tr>
                    <tr>
                      <td className="font-semibold">managementFeeBps</td>
                      <td>{t("guide.fields.managementFeeBps")}</td>
                      <td>{t("guide.fields.exampleFee")}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div className="divider"></div>

            <div>
              <h4 className="font-semibold mb-2">{t("guide.warnings.title")}</h4>
              <ul className="list-disc list-inside text-sm opacity-80 space-y-1">
                <li>{t("guide.warnings.item1")}</li>
                <li>{t("guide.warnings.item2")}</li>
                <li>{t("guide.warnings.item3")}</li>
                <li>{t("guide.warnings.item4")}</li>
                <li>{t("guide.warnings.item5")}</li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Common Asset Addresses */}
      <div className="card bg-base-100 shadow-md mt-8" ref={addressRef}>
        <div className="card-body batch-address-card">
          <h3 className="card-title">{t("assets.title")}</h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
            <div className="bg-base-200 p-4 rounded-lg">
              <p className="font-semibold mb-2">{t("assets.stablecoins")}</p>
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
              <p className="font-semibold mb-2">{t("assets.eth")}</p>
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

          <p className="text-xs opacity-70 mt-4">{t("assets.warning")}</p>
        </div>
      </div>
    </div>
  );
};

export default BatchVaultCreationPage;
