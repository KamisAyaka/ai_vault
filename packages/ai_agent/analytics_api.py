from flask import Flask, jsonify, request
from flask_cors import CORS
import logging
from datetime import datetime
import os
from dotenv import load_dotenv
import sys
import os
from database import DatabaseManager
from analytics_engine import StrategyAnalytics

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
current_dir = os.path.dirname(os.path.abspath(__file__))
packages_dir = os.path.dirname(os.path.dirname(current_dir))
project_root = os.path.dirname(packages_dir)
sys.path.insert(0, project_root)


load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # 允许前端跨域访问

# 初始化服务
db = DatabaseManager()
analytics = StrategyAnalytics(initial_capital=100000.0)

# 全局缓存
_cache = {
    'last_fetch': None,
    'data': {}
}


def get_pool_data(pool_symbol='wBTC-USDC', hours=720, force_refresh=False):
    """
    获取池子数据（带5分钟缓存）
    
    Args:
        pool_symbol: 池子符号
        hours: 获取最近N小时数据
        force_refresh: 强制刷新缓存
    """
    global _cache
    
    cache_key = f"{pool_symbol}_{hours}"
    
    # 检查缓存（5分钟有效期）
    if not force_refresh and _cache.get('last_fetch'):
        age = (datetime.now() - _cache['last_fetch']).total_seconds()
        if age < 300 and cache_key in _cache.get('data', {}):
            logger.info(f"✅ Using cache (age: {age:.0f}s)")
            return _cache['data'][cache_key]
    
    # 从数据库获取
    logger.info(f"📊 Fetching from database: {pool_symbol}, {hours}h")
    
    historical_data = db.get_pool_snapshots(pool_symbol, hours)
    strategy_allocations = db.get_strategy_executions(pool_symbol, hours)
    
    # 如果没有策略数据，使用默认50-50配置
    if not strategy_allocations and historical_data:
        logger.warning("⚠️  No strategy data found, using 50-50 default")
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
    if _cache.get('data') is None:
        _cache['data'] = {}
    _cache['data'][cache_key] = result
    _cache['last_fetch'] = datetime.now()
    
    logger.info(f"✅ Data loaded: {len(historical_data)} snapshots, {len(strategy_allocations)} strategies")
    return result


# ==================== API 端点 ====================

@app.route('/api/v1/analytics/health', methods=['GET'])
def health_check():
    """
    健康检查
    GET /api/v1/analytics/health
    """
    try:
        stats = db.get_database_stats()
        
        return jsonify({
            'success': True,
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'service': 'DeFi Analytics API (Flask)',
            'database': 'connected',
            'stats': stats
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'status': 'unhealthy',
            'error': str(e)
        }), 500


@app.route('/api/v1/analytics/summary', methods=['GET'])
def get_summary():
    """
    获取综合概览（Dashboard 主要数据）
    GET /api/v1/analytics/summary?pool=wBTC-USDC&refresh=false
    
    返回：
        - 性能指标（净值、收益率、回撤等）
        - 当前配置
        - 市场数据
    """
    try:
        pool_symbol = request.args.get('pool', 'wBTC-USDC')
        force_refresh = request.args.get('refresh', 'false').lower() == 'true'
        
        # 获取数据
        data = get_pool_data(pool_symbol, hours=8760, force_refresh=force_refresh)
        
        if not data['historical_data']:
            return jsonify({
                'success': False,
                'error': 'No historical data available'
            }), 404
        
        # 计算净值曲线
        curve_result = analytics.calculate_net_value_curve(
            data['historical_data'],
            data['strategy_allocations']
        )
        
        # 计算性能指标
        metrics = analytics.calculate_performance_metrics(
            curve_result['strategy_curve'],
            curve_result['timestamps'],
            period='ALL'
        )
        
        # 分析配置偏好
        allocation_analysis = analytics.analyze_allocation_preference(
            data['strategy_allocations']
        )
        
        # 当前市场数据
        latest_market = data['historical_data'][-1]
        prev_24h = data['historical_data'][-25] if len(data['historical_data']) >= 25 else latest_market
        
        price_change_24h = 0
        if prev_24h.get('wbtc_price', 0) > 0:
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
                'win_rate_pct': f"{metrics['win_rate']*100:.1f}%",
                'volatility': metrics['volatility']
            },
            'allocation': {
                'current_aave': latest_allocation.get('aave_wbtc_pool', 0),
                'current_lp': latest_allocation.get('uniswap_v3_lp', 0),
                'avg_aave': allocation_analysis['avg_aave_allocation'],
                'avg_lp': allocation_analysis['avg_lp_allocation'],
                'preference': allocation_analysis['preference'],
                'rebalance_count': allocation_analysis['rebalance_count']
            },
            'market': {
                'current_price': latest_market['wbtc_price'],
                'price_change_24h': price_change_24h,
                'price_change_24h_pct': f"{price_change_24h*100:+.2f}%",
                'total_tvl': latest_market.get('tvl_usd', 0),
                'daily_volume': latest_market.get('volume_usd', 0),
                'aave_apy': latest_market.get('aave_wbtc_apy', 0) * 24 * 365 * 100,
                'lp_apy': latest_market.get('univ3_lp_apy', 0) * 24 * 365 * 100
            },
            'data_stats': {
                'total_snapshots': len(data['historical_data']),
                'strategy_points': len(data['strategy_allocations']),
                'start_date': metrics.get('start_date'),
                'end_date': metrics.get('end_date')
            }
        }
        
        return jsonify({
            'success': True,
            'data': summary,
            'generated_at': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"❌ Error in summary: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/analytics/net-value-curve', methods=['GET'])
def get_net_value_curve():
    """
    获取净值曲线数据
    GET /api/v1/analytics/net-value-curve?pool=wBTC-USDC&hours=720
    
    返回：
        - strategy_curve: AI策略净值
        - baseline_curve: 持有不动净值
        - timestamps: 时间点
        - excess_return: 超额收益
    """
    try:
        pool_symbol = request.args.get('pool', 'wBTC-USDC')
        hours = int(request.args.get('hours', 720))
        force_refresh = request.args.get('refresh', 'false').lower() == 'true'
        
        data = get_pool_data(pool_symbol, hours, force_refresh)
        
        if not data['historical_data']:
            return jsonify({
                'success': False,
                'error': 'No historical data available'
            }), 404
        
        result = analytics.calculate_net_value_curve(
            data['historical_data'],
            data['strategy_allocations']
        )
        
        return jsonify({
            'success': True,
            'data': result,
            'meta': {
                'pool_symbol': pool_symbol,
                'data_points': len(result['timestamps']),
                'generated_at': datetime.now().isoformat()
            }
        })
        
    except Exception as e:
        logger.error(f"❌ Error in net_value_curve: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/analytics/performance', methods=['GET'])
def get_performance_metrics():
    """
    获取性能指标
    GET /api/v1/analytics/performance?period=7D
    
    period: 1D, 7D, 30D, ALL
    """
    try:
        pool_symbol = request.args.get('pool', 'wBTC-USDC')
        period = request.args.get('period', 'ALL').upper()
        force_refresh = request.args.get('refresh', 'false').lower() == 'true'
        
        if period not in ['1D', '7D', '30D', 'ALL']:
            return jsonify({
                'success': False,
                'error': 'Invalid period. Must be: 1D, 7D, 30D, or ALL'
            }), 400
        
        # 检查缓存
        if not force_refresh:
            cached = db.get_cached_metrics(pool_symbol, period, max_age_minutes=15)
            if cached:
                return jsonify({
                    'success': True,
                    'data': cached['metrics'],
                    'cached': True,
                    'calculated_at': cached['calculated_at']
                })
        
        # 获取数据
        hours = 8760 if period == 'ALL' else 720
        data = get_pool_data(pool_symbol, hours, force_refresh)
        
        if not data['historical_data']:
            return jsonify({
                'success': False,
                'error': 'Insufficient data'
            }), 404
        
        # 计算净值
        curve_result = analytics.calculate_net_value_curve(
            data['historical_data'],
            data['strategy_allocations']
        )
        
        # 计算指标
        metrics = analytics.calculate_performance_metrics(
            curve_result['strategy_curve'],
            curve_result['timestamps'],
            period=period
        )
        
        # 添加超额收益
        metrics['excess_return'] = curve_result['excess_return']
        
        # 缓存结果
        db.cache_performance_metrics(pool_symbol, period, metrics)
        
        return jsonify({
            'success': True,
            'data': metrics,
            'cached': False,
            'generated_at': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"❌ Error in performance: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/analytics/allocation-history', methods=['GET'])
def get_allocation_history():
    """
    获取配置历史和AI偏好分析
    GET /api/v1/analytics/allocation-history?pool=wBTC-USDC
    """
    try:
        pool_symbol = request.args.get('pool', 'wBTC-USDC')
        hours = int(request.args.get('hours', 720))
        force_refresh = request.args.get('refresh', 'false').lower() == 'true'
        
        data = get_pool_data(pool_symbol, hours, force_refresh)
        
        if not data['strategy_allocations']:
            return jsonify({
                'success': False,
                'error': 'No strategy allocation data'
            }), 404
        
        analysis = analytics.analyze_allocation_preference(
            data['strategy_allocations']
        )
        
        return jsonify({
            'success': True,
            'data': analysis,
            'meta': {
                'pool_symbol': pool_symbol,
                'generated_at': datetime.now().isoformat()
            }
        })
        
    except Exception as e:
        logger.error(f"❌ Error in allocation_history: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/analytics/simulator', methods=['POST'])
def run_simulator():
    """
    运行回测模拟器
    POST /api/v1/analytics/simulator
    
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
    try:
        body = request.get_json()
        
        if not body or 'user_allocations' not in body:
            return jsonify({
                'success': False,
                'error': 'Missing user_allocations in request body'
            }), 400
        
        pool_symbol = body.get('pool_symbol', 'wBTC-USDC')
        user_allocations = body['user_allocations']
        
        # 验证格式
        for alloc in user_allocations:
            required = ['timestamp', 'aave_wbtc_pool', 'uniswap_v3_lp']
            if not all(k in alloc for k in required):
                return jsonify({
                    'success': False,
                    'error': f'Each allocation must have: {required}'
                }), 400
        
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
        
        # 对比分析
        comparison = {
            'user_return': user_result['strategy_final_return'],
            'ai_return': ai_result['strategy_final_return'],
            'baseline_return': ai_result['baseline_final_return'],
            'user_vs_ai': user_result['strategy_final_return'] - ai_result['strategy_final_return'],
            'user_vs_baseline': user_result['excess_return'],
            'user_wins': user_result['strategy_final_return'] > ai_result['strategy_final_return']
        }
        
        return jsonify({
            'success': True,
            'data': {
                'user_strategy_curve': user_result['strategy_curve'],
                'ai_strategy_curve': ai_result['strategy_curve'],
                'baseline_curve': ai_result['baseline_curve'],
                'timestamps': ai_result['timestamps'],
                'comparison': comparison
            },
            'generated_at': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"❌ Error in simulator: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/api/v1/analytics/refresh-cache', methods=['POST'])
def refresh_cache():
    """
    强制刷新缓存
    POST /api/v1/analytics/refresh-cache
    """
    try:
        global _cache
        _cache = {'last_fetch': None, 'data': {}}
        
        return jsonify({
            'success': True,
            'message': 'Cache cleared successfully',
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


# ==================== 错误处理 ====================

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'success': False,
        'error': 'Endpoint not found',
        'available_endpoints': [
            'GET  /api/v1/analytics/health',
            'GET  /api/v1/analytics/summary',
            'GET  /api/v1/analytics/net-value-curve',
            'GET  /api/v1/analytics/performance',
            'GET  /api/v1/analytics/allocation-history',
            'POST /api/v1/analytics/simulator',
            'POST /api/v1/analytics/refresh-cache'
        ]
    }), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal error: {error}", exc_info=True)
    return jsonify({
        'success': False,
        'error': 'Internal server error'
    }), 500


# ==================== 主程序 ====================

if __name__ == '__main__':
    port = int(os.getenv('ANALYTICS_API_PORT', 8001))
    debug = os.getenv('FLASK_DEBUG', 'true').lower() == 'true'
    
    print("\n" + "="*70)
    print("🚀 DeFi Analytics API Server Starting...")
    print("="*70)
    print(f"📡 Port: {port}")
    print(f"🔗 Base URL: http://localhost:{port}")
    print(f"🐛 Debug Mode: {debug}")
    print("="*70)
    print("\n📚 Available Endpoints:")
    print(f"  GET  http://localhost:{port}/api/v1/analytics/health")
    print(f"  GET  http://localhost:{port}/api/v1/analytics/summary")
    print(f"  GET  http://localhost:{port}/api/v1/analytics/net-value-curve")
    print(f"  GET  http://localhost:{port}/api/v1/analytics/performance?period=ALL")
    print(f"  GET  http://localhost:{port}/api/v1/analytics/allocation-history")
    print(f"  POST http://localhost:{port}/api/v1/analytics/simulator")
    print(f"  POST http://localhost:{port}/api/v1/analytics/refresh-cache")
    print("="*70 + "\n")
    
    # 预热：检查数据库连接
    try:
        stats = db.get_database_stats()
        print("✅ Database connection successful")
        print(f"📊 Database stats: {stats}\n")
    except Exception as e:
        print(f"⚠️  Database connection warning: {e}\n")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug
    )