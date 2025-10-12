"use client";

import { useMemo } from "react";
import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useStrategyPerformanceChart } from "~~/hooks/useStrategyPerformanceChart";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import type { Vault } from "~~/types/vault";

type StrategyPerformanceChartProps = {
  vault: Vault | undefined;
  days?: number;
};

export const StrategyPerformanceChart = ({ vault, days = 30 }: StrategyPerformanceChartProps) => {
  const t = useTranslations("vaultDetail.performanceChart");
  const { chartData, excessReturn, loading } = useStrategyPerformanceChart(vault, days);

  const maxValue = useMemo(() => {
    if (chartData.length === 0) return 0;
    return Math.max(...chartData.map(d => Math.max(d.strategyValue, d.holdValue)));
  }, [chartData]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <span className="loading loading-spinner loading-lg text-[#fbe6dc]" />
      </div>
    );
  }

  if (chartData.length === 0) {
    return (
      <div className="flex items-center justify-center h-64 text-white/60">
        <p>{t("noData")}</p>
      </div>
    );
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-4">
        <div>
          <h3 className="text-lg font-semibold text-white">{t("title")}</h3>
          <p className="text-sm text-[#fbe6dc]/70">{t("subtitle")}</p>
        </div>
        <div className="text-right">
          <div className="text-sm text-[#fbe6dc]/70">{t("excessReturn")}</div>
          <div className={`text-2xl font-bold ${excessReturn >= 0 ? "text-green-400" : "text-red-400"}`}>
            {excessReturn >= 0 ? "+" : ""}
            {excessReturn.toFixed(2)}%
          </div>
        </div>
      </div>

      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={chartData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#803100" opacity={0.2} />
          <XAxis dataKey="date" stroke="#fbe6dc" fontSize={12} />
          <YAxis
            stroke="#fbe6dc"
            fontSize={12}
            domain={[0, maxValue * 1.1]}
            tickFormatter={value => `$${value.toFixed(0)}`}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: "rgba(0, 0, 0, 0.8)",
              border: "1px solid #803100",
              borderRadius: "8px",
            }}
            labelStyle={{ color: "#fff" }}
            itemStyle={{ color: "#fbe6dc" }}
          />
          <Legend wrapperStyle={{ color: "#fbe6dc" }} />
          <Line
            type="monotone"
            dataKey="strategyValue"
            stroke="#803100"
            strokeWidth={2}
            name={t("strategy")}
            dot={false}
            activeDot={{ r: 4 }}
          />
          <Line
            type="monotone"
            dataKey="holdValue"
            stroke="#fbe6dc"
            strokeWidth={2}
            strokeDasharray="5 5"
            name={t("hold")}
            dot={false}
            activeDot={{ r: 4 }}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};
