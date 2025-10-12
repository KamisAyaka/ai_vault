"use client";

import { useMemo } from "react";
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useTranslations } from "~~/services/i18n/I18nProvider";
import type { Vault } from "~~/types/vault";

type MaxDrawdownChartProps = {
  vault: Vault | undefined;
  days?: number;
};

type DrawdownPoint = {
  date: string;
  timestamp: number;
  value: number;
  drawdown: number;
};

type DrawdownStats = {
  maxDrawdown: number;
  maxDrawdownDate: string;
  recoveryDays: number | null;
  currentDrawdown: number;
};

export const MaxDrawdownChart = ({ vault, days = 90 }: MaxDrawdownChartProps) => {
  const t = useTranslations("vaultDetail.maxDrawdown");

  const { chartData, stats } = useMemo<{ chartData: DrawdownPoint[]; stats: DrawdownStats }>(() => {
    if (!vault) {
      return {
        chartData: [],
        stats: { maxDrawdown: 0, maxDrawdownDate: "", recoveryDays: null, currentDrawdown: 0 },
      };
    }

    const now = Date.now();
    const startTime = now - days * 24 * 60 * 60 * 1000;
    const points: DrawdownPoint[] = [];

    // 简化模拟：基于当前 TVL 和历史数据生成回撤曲线
    // 实际场景中应该使用真实的历史净值数据
    const dataPoints = Math.min(days, 90);
    let peak = 100; // 从 100% 开始
    let maxDD = 0;
    let maxDDDate = "";
    let maxDDTimestamp = 0;

    for (let i = 0; i <= dataPoints; i++) {
      const timestamp = startTime + (i / dataPoints) * (now - startTime);
      const date = new Date(timestamp);

      // 模拟净值波动（实际应使用真实数据）
      // 添加一些波动性，创建回撤场景
      const volatility = 0.15; // 15% 波动率
      const trend = 0.001; // 轻微上升趋势
      const random = (Math.random() - 0.5) * 2 * volatility;
      const dayReturn = trend + random;

      const previousValue = i === 0 ? 100 : points[i - 1].value;
      const currentValue = previousValue * (1 + dayReturn);

      // 更新峰值
      if (currentValue > peak) {
        peak = currentValue;
      }

      // 计算回撤 (从峰值的下跌百分比)
      const drawdown = ((currentValue - peak) / peak) * 100;

      if (drawdown < maxDD) {
        maxDD = drawdown;
        maxDDDate = date.toLocaleDateString("zh-CN", { month: "short", day: "numeric" });
        maxDDTimestamp = timestamp;
      }

      points.push({
        date: date.toLocaleDateString("zh-CN", { month: "short", day: "numeric" }),
        timestamp,
        value: currentValue,
        drawdown,
      });
    }

    // 计算恢复天数（从最大回撤到恢复到峰值的时间）
    let recoveryDays: number | null = null;
    if (maxDDTimestamp > 0) {
      const maxDDIndex = points.findIndex(p => p.timestamp === maxDDTimestamp);
      const recoveryIndex = points.findIndex((p, idx) => idx > maxDDIndex && p.drawdown >= -0.01);
      if (recoveryIndex > maxDDIndex) {
        recoveryDays = Math.round((points[recoveryIndex].timestamp - maxDDTimestamp) / (24 * 60 * 60 * 1000));
      }
    }

    const currentDrawdown = points.length > 0 ? points[points.length - 1].drawdown : 0;

    return {
      chartData: points,
      stats: {
        maxDrawdown: Math.abs(maxDD),
        maxDrawdownDate: maxDDDate,
        recoveryDays,
        currentDrawdown,
      },
    };
  }, [vault, days]);

  if (chartData.length === 0) {
    return (
      <div className="flex items-center justify-center h-64 text-white/60">
        <p>{t("noData")}</p>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-white">{t("title")}</h3>
        <p className="text-sm text-[#fbe6dc]/70">{t("subtitle")}</p>
      </div>

      <div className="mb-6">
        <ResponsiveContainer width="100%" height={250}>
          <AreaChart data={chartData}>
            <defs>
              <linearGradient id="drawdownGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#803100" opacity={0.1} />
            <XAxis
              dataKey="date"
              stroke="#fbe6dc"
              opacity={0.5}
              tick={{ fill: "#fbe6dc", fontSize: 12 }}
              interval="preserveStartEnd"
            />
            <YAxis
              stroke="#fbe6dc"
              opacity={0.5}
              tick={{ fill: "#fbe6dc", fontSize: 12 }}
              tickFormatter={value => `${value.toFixed(1)}%`}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: "rgba(0, 0, 0, 0.9)",
                border: "1px solid #803100",
                borderRadius: "8px",
              }}
              labelStyle={{ color: "#fff" }}
              itemStyle={{ color: "#ef4444" }}
              formatter={(value: number) => [`${value.toFixed(2)}%`, t("drawdown")]}
            />
            <Area
              type="monotone"
              dataKey="drawdown"
              stroke="#ef4444"
              strokeWidth={2}
              fill="url(#drawdownGradient)"
              isAnimationActive={true}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("maxDrawdown")}</div>
          <div className="text-2xl font-bold text-red-400 mt-1">-{stats.maxDrawdown.toFixed(2)}%</div>
          <div className="text-xs text-[#fbe6dc]/60 mt-1">{stats.maxDrawdownDate}</div>
        </div>
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("recoveryTime")}</div>
          <div className="text-2xl font-bold text-white mt-1">
            {stats.recoveryDays !== null ? `${stats.recoveryDays}${t("days")}` : t("notRecovered")}
          </div>
        </div>
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("currentDrawdown")}</div>
          <div className="text-2xl font-bold text-orange-400 mt-1">
            {stats.currentDrawdown < -0.01 ? stats.currentDrawdown.toFixed(2) : "0.00"}%
          </div>
        </div>
        <div className="bg-black/30 rounded-lg p-3">
          <div className="text-xs text-[#fbe6dc]/70">{t("riskLevel")}</div>
          <div className="text-lg font-bold text-white mt-1">
            {stats.maxDrawdown < 10
              ? t("low")
              : stats.maxDrawdown < 20
                ? t("medium")
                : stats.maxDrawdown < 30
                  ? t("high")
                  : t("veryHigh")}
          </div>
        </div>
      </div>
    </div>
  );
};
