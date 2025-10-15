"""
综合概览（Dashboard用）
GET /api/summary?pool=wBTC-USDC&refresh=false
"""
import sys
import os
from datetime import datetime
import logging

# 添加项目路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from api._utils import success_response, error_response, parse_query_params
from api._data_helper import get_pool_data
from analytics_layer.analytics_engine import StrategyAnalytics

logger = logging.getLogger(__name__)
analytics = StrategyAnalytics(initial_capital=100000.0)


def handler(event, context):
    """综合概览处理函数"""
    try:
        params = parse_query_params(event)

        pool_symbol = params.get('pool', 'wBTC-USDC')
        force_refresh = params.get('refresh', 'false').lower() == 'true'

        # 获取数据
        data = get_pool_data(pool_symbol, hours=8760, force_refresh=force_refresh)

        if not data['historical_data']:
            return error_response('No data available', status=404)

        # 计算净值
        curve_result = analytics.calculate_net_value_curve(
            data['historical_data'],
            data['strategy_allocations']
        )

        # 计算指标
        metrics = analytics.calculate_performance_metrics(
            curve_result['strategy_curve'],
            curve_result['timestamps'],
            period='ALL'
        )

        # 配置分析
        allocation_analysis = analytics.analyze_allocation_preference(
            data['strategy_allocations']
        )

        # 当前市场数据
        latest_market = data['historical_data'][-1]
        prev_24h = data['historical_data'][-25] if len(data['historical_data']) >= 25 else latest_market

        price_change_24h = 0
        if prev_24h['wbtc_price'] > 0:
            price_change_24h = (latest_market['wbtc_price'] - prev_24h['wbtc_price']) / prev_24h['wbtc_price']

        # 当前配置
        latest_allocation = data['strategy_allocations'][-1] if data['strategy_allocations'] else {
            'aave_wbtc_pool': 0.5,
            'uniswap_v3_lp': 0.5
        }

        summary = {
            'performance': {
                'current_nav': curve_result['strategy_curve'][-1],
                'initial_capital': analytics.initial_capital,
                'total_return': curve_result['strategy_final_return'],
                'total_return_pct': f"{curve_result['strategy_final_return']*100:.2f}%",
                'excess_return': curve_result['excess_return'],
                'excess_return_pct': f"{curve_result['excess_return']*100:.2f}%",
                'annualized_return': metrics['annualized_return'],
                'annualized_return_pct': f"{metrics['annualized_return']*100:.2f}%",
                'max_drawdown': metrics['max_drawdown'],
                'max_drawdown_pct': f"{metrics['max_drawdown']*100:.2f}%",
                'sharpe_ratio': metrics['sharpe_ratio'],
                'win_rate': metrics['win_rate'],
                'win_rate_pct': f"{metrics['win_rate']*100:.1f}%"
            },
            'allocation': {
                'current_aave': latest_allocation.get('aave_wbtc_pool', 0),
                'current_lp': latest_allocation.get('uniswap_v3_lp', 0),
                'avg_aave': allocation_analysis['avg_aave_allocation'],
                'avg_lp': allocation_analysis['avg_lp_allocation'],
                'preference': allocation_analysis['preference'],
                'rebalance_count': allocation_analysis['rebalance_count'],
                'allocation_volatility': allocation_analysis['allocation_volatility']
            },
            'market': {
                'current_price': latest_market['wbtc_price'],
                'price_change_24h': price_change_24h,
                'price_change_24h_pct': f"{price_change_24h*100:+.2f}%",
                'total_tvl': latest_market['tvl_usd'],
                'daily_volume': latest_market['volume_usd'],
                'aave_apy': latest_market['aave_wbtc_apy'] * 24 * 365 * 100,
                'lp_apy': latest_market['univ3_lp_apy'] * 24 * 365 * 100
            },
            'data_stats': {
                'total_snapshots': len(data['historical_data']),
                'strategy_points': len(data['strategy_allocations']),
                'start_date': metrics.get('start_date'),
                'end_date': metrics.get('end_date'),
                'data_coverage_days': len(data['historical_data']) / 24
            }
        }

        return success_response(summary, meta={
            'generated_at': datetime.now().isoformat()
        })

    except Exception as e:
        logger.error(f"Error in summary: {e}", exc_info=True)
        return error_response(str(e), status=500)
