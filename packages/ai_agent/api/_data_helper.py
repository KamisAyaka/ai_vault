"""
数据获取辅助函数
"""
import sys
import os
from datetime import datetime
from typing import Dict
import logging

# 添加项目根目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from persistence_layer.database import DatabaseManager

logger = logging.getLogger(__name__)

# 初始化数据库管理器
db = DatabaseManager()

# 全局缓存
_cache = {
    'last_fetch': None,
    'data': {}
}


def get_pool_data(pool_symbol='wBTC-USDC', hours=720, force_refresh=False):
    """
    获取池子数据（带缓存）

    Args:
        pool_symbol: 池子符号
        hours: 获取最近N小时数据
        force_refresh: 强制刷新

    Returns:
        {
            'historical_data': [...],
            'strategy_allocations': [...]
        }
    """
    global _cache

    cache_key = f"{pool_symbol}_{hours}"

    # 检查缓存（5分钟有效期）
    if not force_refresh and _cache.get('last_fetch'):
        age = (datetime.now() - _cache['last_fetch']).total_seconds()
        if age < 300 and _cache.get('data', {}).get(cache_key):
            logger.info(f"✅ 使用缓存数据 (age: {age:.0f}s)")
            return _cache['data'][cache_key]

    # 从数据库获取
    logger.info(f"📊 从数据库获取数据: {pool_symbol}, {hours}小时")

    historical_data = db.get_pool_snapshots(pool_symbol, hours)
    strategy_allocations = db.get_strategy_executions(pool_symbol, hours)

    # 如果没有策略数据，使用默认配置
    if not strategy_allocations and historical_data:
        logger.warning("⚠️  没有策略执行记录，使用默认50-50配置")
        strategy_allocations = [{
            'timestamp': historical_data[0]['timestamp'],
            'aave_wbtc_pool': 0.5,
            'uniswap_v3_lp': 0.5
        }]

    result = {
        'historical_data': historical_data,
        'strategy_allocations': strategy_allocations
    }

    # 更新缓存
    _cache['data'][cache_key] = result
    _cache['last_fetch'] = datetime.now()

    logger.info(f"✅ 数据获取完成: {len(historical_data)} 快照, {len(strategy_allocations)} 策略点")

    return result
