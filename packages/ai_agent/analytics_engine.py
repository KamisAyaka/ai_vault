"""
DeFi策略量化分析引擎（可独立运行服务）
计算策略净值、收益率、回撤等核心指标
"""

import os
import logging
from datetime import datetime, timedelta
from typing import Dict, List

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv

# === 加载环境变量 ===
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
BACKEND_API_URL = os.getenv("BACKEND_API_URL", "http://localhost:8080")
ANALYTICS_API_PORT = int(os.getenv("ANALYTICS_API_PORT", 8001))

# === 日志配置 ===
logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(levelname)s: %(message)s")
logger = logging.getLogger("analytics_engine")


# ================= 核心分析类 =================

class StrategyAnalytics:
    """策略量化分析核心类"""

    def __init__(self, initial_capital: float = 100000.0):
        self.initial_capital = initial_capital

    def calculate_net_value_curve(
        self,
        historical_data: List[Dict],
        strategy_allocations: List[Dict]
    ) -> Dict:
        """计算策略净值曲线 vs 持有不动基准"""
        df = pd.DataFrame(historical_data)
        df["timestamp"] = pd.to_datetime(df["timestamp"])
        df = df.sort_values("timestamp").reset_index(drop=True)

        alloc_df = pd.DataFrame(strategy_allocations)
        alloc_df["timestamp"] = pd.to_datetime(alloc_df["timestamp"])

        df = pd.merge_asof(
            df.sort_values("timestamp"),
            alloc_df.sort_values("timestamp"),
            on="timestamp",
            direction="backward"
        ).fillna(method="ffill")

        strategy_nav = [self.initial_capital]
        baseline_nav = [self.initial_capital]

        initial_wbtc_amount = self.initial_capital / df.iloc[0]["wbtc_price"]
        baseline_wbtc_holdings = initial_wbtc_amount

        for i in range(1, len(df)):
            row = df.iloc[i]
            prev_row = df.iloc[i - 1]

            prev_nav = strategy_nav[-1]

            aave_alloc = row.get("aave_wbtc_pool", 0.5)
            lp_alloc = row.get("uniswap_v3_lp", 0.5)

            aave_value = prev_nav * aave_alloc
            lp_value = prev_nav * lp_alloc

            aave_return = aave_value * row["aave_wbtc_apy"]

            price_change_pct = (row["wbtc_price"] - prev_row["wbtc_price"]) / prev_row["wbtc_price"]
            fee_income = lp_value * row["univ3_lp_apy"]
            impermanent_loss_pct = self._calculate_impermanent_loss(price_change_pct)
            impermanent_loss = lp_value * impermanent_loss_pct

            lp_return = fee_income - impermanent_loss

            gas_cost = row.get("gas_cost_usd", 0)

            new_nav = prev_nav + aave_return + lp_return - gas_cost
            strategy_nav.append(new_nav)

            baseline_value = baseline_wbtc_holdings * row["wbtc_price"]
            baseline_nav.append(baseline_value)

        strategy_return = (strategy_nav[-1] - self.initial_capital) / self.initial_capital
        baseline_return = (baseline_nav[-1] - self.initial_capital) / self.initial_capital
        excess_return = strategy_return - baseline_return

        return {
            "strategy_curve": strategy_nav,
            "baseline_curve": baseline_nav,
            "timestamps": df["timestamp"].dt.strftime("%Y-%m-%d %H:%M:%S").tolist(),
            "excess_return": excess_return,
            "strategy_final_return": strategy_return,
            "baseline_final_return": baseline_return,
        }

    def _calculate_impermanent_loss(self, price_change_pct: float) -> float:
        """计算无常损失百分比"""
        price_ratio = 1 + price_change_pct
        if price_ratio <= 0:
            return 0
        il = 2 * np.sqrt(price_ratio) / (1 + price_ratio) - 1
        return abs(il)

    def calculate_performance_metrics(
        self,
        net_value_curve: List[float],
        timestamps: List[str],
        period: str = "ALL"
    ) -> Dict:
        """计算核心收益指标"""
        df = pd.DataFrame({
            "timestamp": pd.to_datetime(timestamps),
            "nav": net_value_curve,
        })

        if period != "ALL":
            end_time = df["timestamp"].max()
            if period == "1D":
                start_time = end_time - timedelta(days=1)
            elif period == "7D":
                start_time = end_time - timedelta(days=7)
            elif period == "30D":
                start_time = end_time - timedelta(days=30)
            df = df[df["timestamp"] >= start_time].reset_index(drop=True)

        if len(df) < 2:
            return self._empty_metrics()

        df["returns"] = df["nav"].pct_change().fillna(0)
        period_return = (df["nav"].iloc[-1] - df["nav"].iloc[0]) / df["nav"].iloc[0]

        hours = (df["timestamp"].iloc[-1] - df["timestamp"].iloc[0]).total_seconds() / 3600
        years = hours / (24 * 365)
        annualized_return = (1 + period_return) ** (1 / years) - 1 if years > 0 else 0

        df["cummax"] = df["nav"].cummax()
        df["drawdown"] = (df["nav"] - df["cummax"]) / df["cummax"]
        max_drawdown = df["drawdown"].min()

        volatility = df["returns"].std() * np.sqrt(24 * 365)

        risk_free_rate = 0.03
        excess_returns = annualized_return - risk_free_rate
        sharpe_ratio = excess_returns / volatility if volatility > 0 else 0

        win_rate = (df["returns"] > 0).sum() / len(df["returns"]) if len(df) > 0 else 0

        return {
            "annualized_return": float(annualized_return),
            "max_drawdown": float(max_drawdown),
            "sharpe_ratio": float(sharpe_ratio),
            "volatility": float(volatility),
            "win_rate": float(win_rate),
            "period_return": float(period_return),
            "period": period,
            "start_date": df["timestamp"].iloc[0].isoformat(),
            "end_date": df["timestamp"].iloc[-1].isoformat(),
        }

    def _empty_metrics(self) -> Dict:
        return {
            "annualized_return": 0.0,
            "max_drawdown": 0.0,
            "sharpe_ratio": 0.0,
            "volatility": 0.0,
            "win_rate": 0.0,
            "period_return": 0.0,
        }

    def analyze_allocation_preference(self, strategy_allocations: List[Dict]) -> Dict:
        """分析策略配置偏好和历史"""
        if not strategy_allocations:
            return {
                "avg_aave_allocation": 0.0,
                "avg_lp_allocation": 0.0,
                "preference": "balanced",
                "rebalance_count": 0,
                "allocation_history": []
            }

        df = pd.DataFrame(strategy_allocations)

        # 计算平均配置
        avg_aave = df.get("aave_wbtc_pool", pd.Series([0.5])).mean()
        avg_lp = df.get("uniswap_v3_lp", pd.Series([0.5])).mean()

        # 判断偏好
        if avg_aave > 0.6:
            preference = "aave_focused"
        elif avg_lp > 0.6:
            preference = "lp_focused"
        else:
            preference = "balanced"

        # 计算再平衡次数（配置变化超过5%视为再平衡）
        rebalance_count = 0
        if len(df) > 1:
            df["aave_change"] = df.get("aave_wbtc_pool", 0.5).diff().abs()
            rebalance_count = (df["aave_change"] > 0.05).sum()

        # 构建历史记录
        allocation_history = []
        for _, row in df.iterrows():
            allocation_history.append({
                "timestamp": row.get("timestamp"),
                "aave_wbtc_pool": row.get("aave_wbtc_pool", 0.5),
                "uniswap_v3_lp": row.get("uniswap_v3_lp", 0.5)
            })

        return {
            "avg_aave_allocation": float(avg_aave),
            "avg_lp_allocation": float(avg_lp),
            "preference": preference,
            "rebalance_count": int(rebalance_count),
            "allocation_history": allocation_history
        }

    def run_backtest_simulator(
        self,
        historical_data: List[Dict],
        user_allocations: List[Dict]
    ) -> Dict:
        """运行回测模拟器，使用用户自定义的配置策略"""
        return self.calculate_net_value_curve(historical_data, user_allocations)


# ================= FastAPI 封装层 =================

app = FastAPI(title="DeFi Strategy Analytics Engine", version="1.0")


class AnalyticsRequest(BaseModel):
    historical_data: List[Dict]
    strategy_allocations: List[Dict]
    period: str = "ALL"


@app.post("/analyze")
def analyze_strategy(req: AnalyticsRequest):
    try:
        engine = StrategyAnalytics()
        result = engine.calculate_net_value_curve(req.historical_data, req.strategy_allocations)
        metrics = engine.calculate_performance_metrics(result["strategy_curve"], result["timestamps"], req.period)

        return {
            "success": True,
            "analytics": result,
            "metrics": metrics,
        }
    except Exception as e:
        logger.exception("Analysis failed")
        raise HTTPException(status_code=500, detail=str(e))


# ================= 主入口 =================

if __name__ == "__main__":
    import uvicorn

    logger.info(f"✅ Analytics Engine running on port {ANALYTICS_API_PORT}")
    uvicorn.run("analytics_engine:app", host="0.0.0.0", port=ANALYTICS_API_PORT, reload=True)
