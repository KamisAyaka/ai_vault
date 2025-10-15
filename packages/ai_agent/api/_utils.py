"""
Vercel Serverless Functions 通用工具函数
"""
import json
import logging
from datetime import datetime
from typing import Dict, Any

logger = logging.getLogger(__name__)


def json_response(data: Any, status: int = 200) -> Dict:
    """
    创建 JSON 响应

    Args:
        data: 响应数据
        status: HTTP 状态码

    Returns:
        Vercel 响应格式
    """
    return {
        'statusCode': status,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        },
        'body': json.dumps(data, ensure_ascii=False, default=str)
    }


def success_response(data: Any, meta: Dict = None) -> Dict:
    """成功响应"""
    response_data = {
        'success': True,
        'data': data
    }
    if meta:
        response_data['meta'] = meta
    return json_response(response_data)


def error_response(error: str, status: int = 500) -> Dict:
    """错误响应"""
    return json_response({
        'success': False,
        'error': error
    }, status=status)


def parse_query_params(event: Dict) -> Dict:
    """
    解析查询参数

    Args:
        event: Vercel 事件对象

    Returns:
        查询参数字典
    """
    return event.get('queryStringParameters', {}) or {}


def parse_body(event: Dict) -> Dict:
    """
    解析请求体

    Args:
        event: Vercel 事件对象

    Returns:
        请求体字典
    """
    body = event.get('body', '{}')
    if isinstance(body, str):
        try:
            return json.loads(body)
        except json.JSONDecodeError:
            return {}
    return body
