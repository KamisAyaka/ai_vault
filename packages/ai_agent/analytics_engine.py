"""
DeFi策略量化分析引擎
计算策略净值、收益率、回撤等核心指标
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class StrategyAnalytics:
    """策略量化分析核心类"""
    
    def __init__(self, initial_capital: float = 100000.0):
        """
        Args:
            initial_capital: 初始资金量 (USDC)
        """
        self.initial_capital = initial_capital
        
    def calculate_net_value_curve(
        self, 
        historical_data: List[Dict],
        strategy_allocations: List[Dict]
    ) -> Dict:
        """
        计算策略净值曲线 vs 持有不动基准
        
        Args:
            historical_data: 历史价格和APY数据
                [{
                    'timestamp': '2024-01-01T00:00:00',
                    'wbtc_price': 45000.0,
                    'aave_wbtc_apy': 0.001,  # 小时APY
                    'univ3_lp_apy': 0.002,   # 小时APY (手续费收入)
                    'gas_cost_usd': 0.01
                }]
            strategy_allocations: AI策略的历史配置
                [{
                    'timestamp': '2024-01-01T00:00:00',
                    'aave_wbtc_pool': 0.6,
                    'uniswap_v3_lp': 0.4
                }]
        
        Returns:
            {
                'strategy_curve': [...],  # 策略净值序列
                'baseline_curve': [...],  # 基准净值序列
                'timestamps': [...],
                'excess_return': 0.15     # 超额收益
            }
        """
        df = pd.DataFrame(historical_data)
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        df = df.sort_values('timestamp').reset_index(drop=True)
        
        alloc_df = pd.DataFrame(strategy_allocations)
        alloc_df['timestamp'] = pd.to_datetime(alloc_df['timestamp'])
        
        # 合并配置到每个时间点
        df = pd.merge_asof(
            df.sort_values('timestamp'),
            alloc_df.sort_values('timestamp'),
            on='timestamp',
            direction='backward'
        ).fillna(method='ffill')
        
        # 初始化资产
        strategy_nav = [self.initial_capital]
        baseline_nav = [self.initial_capital]
        
        initial_wbtc_amount = self.initial_capital / df.iloc[0]['wbtc_price']
        baseline_wbtc_holdings = initial_wbtc_amount  # 持有不动策略
        
        for i in range(1, len(df)):
            row = df.iloc[i]
            prev_row = df.iloc[i-1]
            
            # === 策略净值计算 ===
            prev_nav = strategy_nav[-1]
            
            # 当前配置
            aave_alloc = row.get('aave_wbtc_pool', 0.5)
            lp_alloc = row.get('uniswap_v3_lp', 0.5)
            
            # 上一期各资产价值
            aave_value = prev_nav * aave_alloc
            lp_value = prev_nav * lp_alloc
            
            # Aave借贷收益（稳定，基于APY）
            aave_return = aave_value * row['aave_wbtc_apy']
            
            # UniV3 LP收益 = 手续费收入 - 无常损失
            price_change_pct = (row['wbtc_price'] - prev_row['wbtc_price']) / prev_row['wbtc_price']
            
            # 手续费收入
            fee_income = lp_value * row['univ3_lp_apy']
            
            # 无常损失简化计算 (实际需要根据价格区间计算)
            impermanent_loss_pct = self._calculate_impermanent_loss(price_change_pct)
            impermanent_loss = lp_value * impermanent_loss_pct
            
            lp_return = fee_income - impermanent_loss
            
            # Gas成本
            gas_cost = row.get('gas_cost_usd', 0)
            
            # 新净值
            new_nav = prev_nav + aave_return + lp_return - gas_cost
            strategy_nav.append(new_nav)
            
            # === 基准净值 (单纯持有wBTC) ===
            baseline_value = baseline_wbtc_holdings * row['wbtc_price']
            baseline_nav.append(baseline_value)
        
        # 计算超额收益
        strategy_return = (strategy_nav[-1] - self.initial_capital) / self.initial_capital
        baseline_return = (baseline_nav[-1] - self.initial_capital) / self.initial_capital
        excess_return = strategy_return - baseline_return
        
        return {
            'strategy_curve': strategy_nav,
            'baseline_curve': baseline_nav,
            'timestamps': df['timestamp'].dt.strftime('%Y-%m-%d %H:%M:%S').tolist(),
            'excess_return': excess_return,
            'strategy_final_return': strategy_return,
            'baseline_final_return': baseline_return
        }
    
    def _calculate_impermanent_loss(self, price_change_pct: float) -> float:
        """
        计算无常损失百分比
        IL = 2*sqrt(price_ratio) / (1 + price_ratio) - 1
        """
        price_ratio = 1 + price_change_pct
        if price_ratio <= 0:
            return 0  # 价格不能为负
        
        il = 2 * np.sqrt(price_ratio) / (1 + price_ratio) - 1
        return abs(il)  # 返回损失的绝对值
    
    def calculate_performance_metrics(
        self, 
        net_value_curve: List[float],
        timestamps: List[str],
        period: str = 'ALL'  # '1D', '7D', '30D', 'ALL'
    ) -> Dict:
        """
        计算核心收益指标
        
        Returns:
            {
                'annualized_return': 0.45,    # 年化收益率
                'max_drawdown': -0.12,        # 最大回撤
                'sharpe_ratio': 1.8,          # 夏普比率
                'volatility': 0.25,           # 波动率
                'win_rate': 0.65,             # 胜率
                'period_return': 0.08         # 周期收益率
            }
        """
        df = pd.DataFrame({
            'timestamp': pd.to_datetime(timestamps),
            'nav': net_value_curve
        })
        
        # 筛选时间周期
        if period != 'ALL':
            end_time = df['timestamp'].max()
            if period == '1D':
                start_time = end_time - timedelta(days=1)
            elif period == '7D':
                start_time = end_time - timedelta(days=7)
            elif period == '30D':
                start_time = end_time - timedelta(days=30)
            
            df = df[df['timestamp'] >= start_time].reset_index(drop=True)
        
        if len(df) < 2:
            return self._empty_metrics()
        
        # 计算收益率序列
        df['returns'] = df['nav'].pct_change().fillna(0)
        
        # 1. 周期收益率
        period_return = (df['nav'].iloc[-1] - df['nav'].iloc[0]) / df['nav'].iloc[0]
        
        # 2. 年化收益率
        hours = (df['timestamp'].iloc[-1] - df['timestamp'].iloc[0]).total_seconds() / 3600
        years = hours / (24 * 365)
        annualized_return = (1 + period_return) ** (1/years) - 1 if years > 0 else 0
        
        # 3. 最大回撤
        df['cummax'] = df['nav'].cummax()
        df['drawdown'] = (df['nav'] - df['cummax']) / df['cummax']
        max_drawdown = df['drawdown'].min()
        
        # 4. 波动率（年化）
        volatility = df['returns'].std() * np.sqrt(24 * 365)  # 假设小时数据
        
        # 5. 夏普比率（假设无风险利率3%）
        risk_free_rate = 0.03
        excess_returns = annualized_return - risk_free_rate
        sharpe_ratio = excess_returns / volatility if volatility > 0 else 0
        
        # 6. 胜率
        win_rate = (df['returns'] > 0).sum() / len(df['returns']) if len(df) > 0 else 0
        
        return {
            'annualized_return': float(annualized_return),
            'max_drawdown': float(max_drawdown),
            'sharpe_ratio': float(sharpe_ratio),
            'volatility': float(volatility),
            'win_rate': float(win_rate),
            'period_return': float(period_return),
            'period': period,
            'start_date': df['timestamp'].iloc[0].isoformat(),
            'end_date': df['timestamp'].iloc[-1].isoformat()
        }
    
    def _empty_metrics(self) -> Dict:
        """返回空指标"""
        return {
            'annualized_return': 0.0,
            'max_drawdown': 0.0,
            'sharpe_ratio': 0.0,
            'volatility': 0.0,
            'win_rate': 0.0,
            'period_return': 0.0
        }
    
    def analyze_allocation_preference(
        self, 
        strategy_allocations: List[Dict]
    ) -> Dict:
        """
        分析AI的流动性偏好
        
        Returns:
            {
                'avg_aave_allocation': 0.58,
                'avg_lp_allocation': 0.42,
                'allocation_volatility': 0.12,  # 配置变化频率
                'rebalance_count': 45,           # 再平衡次数
                'preference': 'conservative'     # 'conservative' | 'balanced' | 'aggressive'
            }
        """
        df = pd.DataFrame(strategy_allocations)
        
        avg_aave = df['aave_wbtc_pool'].mean()
        avg_lp = df['uniswap_v3_lp'].mean()
        
        # 配置变化的标准差
        alloc_volatility = df['aave_wbtc_pool'].std()
        
        # 再平衡次数（配置变化超过5%视为再平衡）
        df['aave_change'] = df['aave_wbtc_pool'].diff().abs()
        rebalance_count = (df['aave_change'] > 0.05).sum()
        
        # 判断偏好类型
        if avg_aave > 0.6:
            preference = 'conservative'  # 保守型，偏好稳定的Aave
        elif avg_aave < 0.4:
            preference = 'aggressive'    # 激进型，偏好高收益的LP
        else:
            preference = 'balanced'      # 平衡型
        
        return {
            'avg_aave_allocation': float(avg_aave),
            'avg_lp_allocation': float(avg_lp),
            'allocation_volatility': float(alloc_volatility),
            'rebalance_count': int(rebalance_count),
            'preference': preference,
            'allocation_history': df[['timestamp', 'aave_wbtc_pool', 'uniswap_v3_lp']].to_dict('records')
        }
    
    def run_backtest_simulator(
        self,
        historical_data: List[Dict],
        user_allocations: List[Dict],  # 用户自定义配置
    ) -> Dict:
        """
        运行用户自定义策略的回测模拟器
        
        Args:
            user_allocations: 用户输入的配置
                [{
                    'timestamp': '2024-01-01T00:00:00',
                    'aave_wbtc_pool': 0.7,
                    'uniswap_v3_lp': 0.3
                }]
        
        Returns:
            与 calculate_net_value_curve 相同格式的结果
        """
        return self.calculate_net_value_curve(historical_data, user_allocations)


# ===== 使用示例 =====
if __name__ == "__main__":
    # 模拟历史数据
    historical_data = [
        {
            'timestamp': '2024-01-01T00:00:00',
            'wbtc_price': 45000.0,
            'aave_wbtc_apy': 0.0001,
            'univ3_lp_apy': 0.0003,
            'gas_cost_usd': 0.05
        },
        {
            'timestamp': '2024-01-01T01:00:00',
            'wbtc_price': 45500.0,
            'aave_wbtc_apy': 0.0001,
            'univ3_lp_apy': 0.0004,
            'gas_cost_usd': 0.05
        }
    ]
    
    strategy_allocations = [
        {
            'timestamp': '2024-01-01T00:00:00',
            'aave_wbtc_pool': 0.6,
            'uniswap_v3_lp': 0.4
        }
    ]
    
    analytics = StrategyAnalytics(initial_capital=100000.0)
    
    # 计算净值曲线
    result = analytics.calculate_net_value_curve(historical_data, strategy_allocations)
    print("策略净值:", result['strategy_curve'])
    print("超额收益:", f"{result['excess_return']:.2%}")
    
    # 计算性能指标
    metrics = analytics.calculate_performance_metrics(
        result['strategy_curve'],
        result['timestamps'],
        period='ALL'
    )
    print("\n性能指标:", metrics)