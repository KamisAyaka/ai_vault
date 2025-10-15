"""
健康检查 API
GET /api/health
"""
import sys
import os
from datetime import datetime
import logging

# 添加项目路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from api._utils import success_response, error_response
from persistence_layer.database import DatabaseManager

logger = logging.getLogger(__name__)
db = DatabaseManager()


def handler(event, context):
    """健康检查处理函数"""
    try:
        # 测试数据库连接
        stats = db.get_database_stats()

        return success_response({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'service': 'DeFi Analytics API',
            'database': 'connected',
            'stats': stats
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}", exc_info=True)
        return error_response(str(e), status=500)
