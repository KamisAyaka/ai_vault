"use client";

import { useMemo } from "react";
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import type { Vault } from "~~/types/vault";

type LiquidityPreferenceChartProps = {
  vault: Vault | undefined;
};

const COLORS = ["#803100", "#fbe6dc", "#a04000", "#d9c4b8", "#602400"];

export const LiquidityPreferenceChart = ({ vault }: LiquidityPreferenceChartProps) => {
  const t = useTranslations("vaultDetail.liquidityPreference");

  const chartData = useMemo(() => {
    if (!vault?.allocations || vault.allocations.length === 0) return [];

    return vault.allocations.map(allocation => ({
      name: allocation.adapterType,
      value: Number(allocation.allocation) / 10, // 转换为百分比
      percentage: (Number(allocation.allocation) / 1000) * 100,
    }));
  }, [vault?.allocations]);

  if (chartData.length === 0) {
    return (
      <div className="flex items-center justify-center h-64 text-white/60">
        <p>{t("noData")}</p>
      </div>
    );
  }

  const totalAllocation = chartData.reduce((sum, item) => sum + item.value, 0);

  return (
    <div>
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-white">{t("title")}</h3>
        <p className="text-sm text-[#fbe6dc]/70">{t("subtitle")}</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div>
          <ResponsiveContainer width="100%" height={250}>
            <PieChart>
              <Pie
                data={chartData}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => {
                  const labelName = typeof name === "string" ? name : String(name ?? "");
                  const percentage = Number(percent ?? 0) * 100;

                  return `${labelName} ${percentage.toFixed(1)}%`;
                }}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {chartData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{
                  backgroundColor: "rgba(0, 0, 0, 0.8)",
                  border: "1px solid #803100",
                  borderRadius: "8px",
                }}
                labelStyle={{ color: "#fff" }}
                itemStyle={{ color: "#fbe6dc" }}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div className="space-y-3">
          <div className="flex items-center justify-between text-sm">
            <span className="text-[#fbe6dc]/70">{t("totalAllocation")}</span>
            <span className="font-semibold text-white">{totalAllocation.toFixed(1)}%</span>
          </div>
          <div className="divider my-1"></div>
          {chartData.map((item, index) => (
            <div key={item.name} className="flex items-center gap-3">
              <div className="w-4 h-4 rounded" style={{ backgroundColor: COLORS[index % COLORS.length] }}></div>
              <div className="flex-1">
                <div className="flex justify-between items-center">
                  <span className="font-semibold text-white text-sm">{item.name}</span>
                  <span className="text-[#fbe6dc] text-sm">{item.percentage.toFixed(1)}%</span>
                </div>
                <progress
                  className="progress progress-primary w-full h-1 mt-1"
                  value={item.percentage}
                  max={100}
                  style={{
                    ["--progress-color" as string]: COLORS[index % COLORS.length],
                  }}
                ></progress>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="mt-6 grid grid-cols-3 gap-4 text-center">
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("protocolCount")}</div>
          <div className="text-2xl font-bold text-white mt-1">{chartData.length}</div>
        </div>
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("topProtocol")}</div>
          <div className="text-lg font-bold text-white mt-1">{chartData.length > 0 ? chartData[0].name : "-"}</div>
        </div>
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("diversification")}</div>
          <div className="text-2xl font-bold text-white mt-1">
            {chartData.length > 0 ? (chartData[0].percentage < 50 ? t("balanced") : t("concentrated")) : "-"}
          </div>
        </div>
      </div>
    </div>
  );
};
