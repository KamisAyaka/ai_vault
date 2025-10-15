"""
获取性能指标
GET /api/performance?pool=wBTC-USDC&period=ALL&refresh=false
"""
import sys
import os
from datetime import datetime
import logging

# 添加项目路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from api._utils import success_response, error_response, parse_query_params
from api._data_helper import get_pool_data, db
from analytics_layer.analytics_engine import StrategyAnalytics

logger = logging.getLogger(__name__)
analytics = StrategyAnalytics(initial_capital=100000.0)


def handler(event, context):
    """获取性能指标处理函数"""
    try:
        params = parse_query_params(event)

        pool_symbol = params.get('pool', 'wBTC-USDC')
        period = params.get('period', 'ALL').upper()
        force_refresh = params.get('refresh', 'false').lower() == 'true'

        if period not in ['1D', '7D', '30D', 'ALL']:
            return error_response('Invalid period. Must be: 1D, 7D, 30D, or ALL', status=400)

        # 检查缓存
        if not force_refresh:
            cached = db.get_cached_metrics(pool_symbol, period, max_age_minutes=15)
            if cached:
                return success_response(cached['metrics'], meta={
                    'cached': True,
                    'calculated_at': cached['calculated_at']
                })

        # 获取数据（ALL需要更长的时间范围）
        hours = 8760 if period == 'ALL' else 720
        data = get_pool_data(pool_symbol, hours, force_refresh)

        if not data['historical_data']:
            return error_response('Insufficient data', status=404)

        # 计算净值曲线
        curve_result = analytics.calculate_net_value_curve(
            data['historical_data'],
            data['strategy_allocations']
        )

        # 计算性能指标
        metrics = analytics.calculate_performance_metrics(
            curve_result['strategy_curve'],
            curve_result['timestamps'],
            period=period
        )

        # 添加超额收益
        metrics['excess_return'] = curve_result['excess_return']

        # 缓存结果
        db.cache_performance_metrics(pool_symbol, period, metrics)

        return success_response(metrics, meta={
            'cached': False,
            'generated_at': datetime.now().isoformat()
        })

    except Exception as e:
        logger.error(f"Error in performance_metrics: {e}", exc_info=True)
        return error_response(str(e), status=500)
