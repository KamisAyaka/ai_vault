"""
运行回测模拟器
POST /api/simulator
Body: {
    "pool_symbol": "wBTC-USDC",
    "user_allocations": [
        {
            "timestamp": "2024-01-01T00:00:00",
            "aave_wbtc_pool": 0.7,
            "uniswap_v3_lp": 0.3
        }
    ]
}
"""
import sys
import os
from datetime import datetime
import logging

# 添加项目路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from api._utils import success_response, error_response, parse_body
from api._data_helper import get_pool_data
from analytics_layer.analytics_engine import StrategyAnalytics

logger = logging.getLogger(__name__)
analytics = StrategyAnalytics(initial_capital=100000.0)


def handler(event, context):
    """运行模拟器处理函数"""
    try:
        body = parse_body(event)

        if not body or 'user_allocations' not in body:
            return error_response('Missing user_allocations in request body', status=400)

        pool_symbol = body.get('pool_symbol', 'wBTC-USDC')
        user_allocations = body['user_allocations']

        # 验证格式
        for alloc in user_allocations:
            required = ['timestamp', 'aave_wbtc_pool', 'uniswap_v3_lp']
            if not all(k in alloc for k in required):
                return error_response(f'Each allocation must have: {required}', status=400)

        # 获取历史数据
        data = get_pool_data(pool_symbol, hours=8760)

        # 运行用户策略
        user_result = analytics.run_backtest_simulator(
            data['historical_data'],
            user_allocations
        )

        # 运行AI策略（对比）
        ai_result = analytics.calculate_net_value_curve(
            data['historical_data'],
            data['strategy_allocations']
        )

        # 对比
        comparison = {
            'user_return': user_result['strategy_final_return'],
            'ai_return': ai_result['strategy_final_return'],
            'baseline_return': ai_result['baseline_final_return'],
            'user_vs_ai': user_result['strategy_final_return'] - ai_result['strategy_final_return'],
            'user_vs_baseline': user_result['excess_return'],
            'user_wins': user_result['strategy_final_return'] > ai_result['strategy_final_return']
        }

        return success_response({
            'user_strategy_curve': user_result['strategy_curve'],
            'ai_strategy_curve': ai_result['strategy_curve'],
            'baseline_curve': ai_result['baseline_curve'],
            'timestamps': ai_result['timestamps'],
            'comparison': comparison
        }, meta={
            'generated_at': datetime.now().isoformat()
        })

    except Exception as e:
        logger.error(f"Error in simulator: {e}", exc_info=True)
        return error_response(str(e), status=500)
