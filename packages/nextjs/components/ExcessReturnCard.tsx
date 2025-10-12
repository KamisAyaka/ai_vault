"use client";

import { useState } from "react";
import { useStrategyPerformanceChart } from "~~/hooks/useStrategyPerformanceChart";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import type { Vault } from "~~/types/vault";

type ExcessReturnCardProps = {
  vault: Vault | undefined;
};

type Period = "1d" | "7d" | "30d" | "all";

const PERIOD_DAYS: Record<Period, number> = {
  "1d": 1,
  "7d": 7,
  "30d": 30,
  all: 365, // 默认显示最长1年
};

export const ExcessReturnCard = ({ vault }: ExcessReturnCardProps) => {
  const t = useTranslations("vaultDetail.excessReturn");
  const tCommon = useTranslations("common.timeRanges");
  const [selectedPeriod, setSelectedPeriod] = useState<Period>("30d");

  const days = PERIOD_DAYS[selectedPeriod];
  const { excessReturn, loading } = useStrategyPerformanceChart(vault, days);

  if (loading) {
    return (
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <div className="flex items-center justify-center h-32">
            <span className="loading loading-spinner loading-md text-[#fbe6dc]" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="card bg-base-100 shadow-xl">
      <div className="card-body">
        <div className="mb-4">
          <div className="flex justify-between items-center mb-2">
            <h3 className="text-lg font-semibold text-white mr-[-30px] leading-none">{t("title")}</h3>
            <div className="btn-group btn-group-sm">
              {(["1d", "7d", "30d", "all"] as Period[]).map(period => (
                <button
                  key={period}
                  className={`btn btn-xs ${selectedPeriod === period ? "bg-[#803100] text-white" : "bg-black/40 text-[#fbe6dc] border-[#803100]/30"}`}
                  onClick={() => setSelectedPeriod(period)}
                >
                  {period === "1d" && tCommon("1d")}
                  {period === "7d" && tCommon("7d")}
                  {period === "30d" && tCommon("30d")}
                  {period === "all" && tCommon("all")}
                </button>
              ))}
            </div>
          </div>
          <p className="text-sm text-[#fbe6dc]/70 text-center">{t("subtitle")}</p>
        </div>

        <div className="text-center">
          <div className="text-sm text-[#fbe6dc]/70 mb-2">{t("value")}</div>
          <div className={`text-5xl font-bold ${excessReturn >= 0 ? "text-green-400" : "text-red-400"}`}>
            {excessReturn >= 0 ? "+" : ""}
            {excessReturn.toFixed(2)}%
          </div>
          <div className="text-xs text-[#fbe6dc]/60 mt-2">
            {t("period")}: {selectedPeriod === "1d" && t("1day")}
            {selectedPeriod === "7d" && t("7days")}
            {selectedPeriod === "30d" && t("30days")}
            {selectedPeriod === "all" && t("allTime")}
          </div>
        </div>

        <div className="divider my-2"></div>

        <div className="grid grid-cols-2 gap-4 text-sm">
          <div className="text-center p-2 rounded bg-black/30">
            <div className="text-[#fbe6dc]/70">{t("strategyPerformance")}</div>
            <div className="text-lg font-semibold text-white mt-1">
              {excessReturn >= 0 ? "↗" : "↘"} {t("outperforming")}
            </div>
          </div>
          <div className="text-center p-2 rounded bg-black/30">
            <div className="text-[#fbe6dc]/70">{t("benchmark")}</div>
            <div className="text-lg font-semibold text-white mt-1">{t("holdStrategy")}</div>
          </div>
        </div>
      </div>
    </div>
  );
};
