"""
获取配置历史和偏好分析
GET /api/allocation_history?pool=wBTC-USDC&hours=720
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
    """获取配置历史处理函数"""
    try:
        params = parse_query_params(event)

        pool_symbol = params.get('pool', 'wBTC-USDC')
        hours = int(params.get('hours', 720))
        force_refresh = params.get('refresh', 'false').lower() == 'true'

        data = get_pool_data(pool_symbol, hours, force_refresh)

        if not data['strategy_allocations']:
            return error_response('No strategy allocation data', status=404)

        # 分析配置偏好
        analysis = analytics.analyze_allocation_preference(
            data['strategy_allocations']
        )

        return success_response(analysis, meta={
            'pool_symbol': pool_symbol,
            'generated_at': datetime.now().isoformat()
        })

    except Exception as e:
        logger.error(f"Error in allocation_history: {e}", exc_info=True)
        return error_response(str(e), status=500)
