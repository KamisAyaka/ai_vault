"""
获取策略净值曲线 vs 基准曲线
GET /api/net_value_curve?pool=wBTC-USDC&hours=720&refresh=false
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
    """获取净值曲线处理函数"""
    try:
        params = parse_query_params(event)

        pool_symbol = params.get('pool', 'wBTC-USDC')
        hours = int(params.get('hours', 720))
        force_refresh = params.get('refresh', 'false').lower() == 'true'

        # 获取数据
        data = get_pool_data(pool_symbol, hours, force_refresh)

        if not data['historical_data']:
            return error_response('No historical data available', status=404)

        # 计算净值曲线
        result = analytics.calculate_net_value_curve(
            data['historical_data'],
            data['strategy_allocations']
        )

        return success_response(result, meta={
            'pool_symbol': pool_symbol,
            'data_points': len(result['timestamps']),
            'generated_at': datetime.now().isoformat()
        })

    except Exception as e:
        logger.error(f"Error in net_value_curve: {e}", exc_info=True)
        return error_response(str(e), status=500)
