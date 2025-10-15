"""
数据库操作封装 - Supabase 版本
"""
import os
from typing import List, Dict, Optional
import logging
from datetime import datetime, timedelta
import json
from dotenv import load_dotenv
from supabase import create_client, Client

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
load_dotenv()

# Supabase 配置
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("SUPABASE_URL and SUPABASE_KEY environment variables must be set!")

# 创建全局 Supabase 客户端
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


class DatabaseManager:
    """数据库操作类"""
    
    @staticmethod
    def insert_pool_snapshots(snapshots: List[Dict]) -> int:
        """
        批量插入池子快照

        Args:
            snapshots: 快照数据列表

        Returns:
            插入的记录数
        """
        if not snapshots:
            return 0

        try:
            # 准备数据
            data = [
                {
                    'pool_symbol': s.get('pool_symbol'),
                    'timestamp': s.get('timestamp'),
                    'wbtc_price': float(s.get('wbtc_price', 0)),
                    'volume_usd': float(s.get('volume_usd', 0)),
                    'liquidity': float(s.get('liquidity', 0)),
                    'tvl_usd': float(s.get('tvl_usd', 0)),
                    'aave_wbtc_apy': float(s.get('aave_wbtc_apy', 0)),
                    'univ3_lp_apy': float(s.get('univ3_lp_apy', 0)),
                    'gas_cost_usd': float(s.get('gas_cost_usd', 0))
                }
                for s in snapshots
            ]

            # 使用 upsert 来处理冲突
            result = supabase.table('pool_snapshots').upsert(data).execute()

            logger.info(f"✅ Inserted/Updated {len(snapshots)} snapshots")
            return len(snapshots)
        except Exception as e:
            logger.error(f"Error inserting snapshots: {e}")
            raise
    
    @staticmethod
    def get_pool_snapshots(
        pool_symbol: str,
        hours: int = 720,
        limit: Optional[int] = None
    ) -> List[Dict]:
        """
        获取池子历史快照

        Args:
            pool_symbol: 池子符号，如 'wBTC-USDC'
            hours: 获取最近N小时的数据
            limit: 最多返回多少条记录

        Returns:
            快照列表
        """
        try:
            # 计算时间范围
            cutoff_time = (datetime.now() - timedelta(hours=hours)).isoformat()

            # 构建查询
            query = supabase.table('pool_snapshots').select('*').eq('pool_symbol', pool_symbol).gte('timestamp', cutoff_time).order('timestamp', desc=False)

            if limit:
                query = query.limit(limit)

            response = query.execute()
            results = response.data

            # 转换timestamp为ISO格式字符串（如果需要）
            for r in results:
                if isinstance(r.get('timestamp'), str):
                    # 已经是字符串，不需要转换
                    pass
                elif isinstance(r.get('timestamp'), datetime):
                    r['timestamp'] = r['timestamp'].isoformat()

            logger.info(f"📊 Retrieved {len(results)} snapshots for {pool_symbol}")
            return results
        except Exception as e:
            logger.error(f"Error getting pool snapshots: {e}")
            raise
    
    @staticmethod
    def insert_strategy_execution(execution: Dict) -> int:
        """
        记录策略执行

        Args:
            execution: {
                'pool_symbol': 'wBTC-USDC',
                'timestamp': '2024-01-01T00:00:00',
                'aave_wbtc_pool': 0.6,
                'uniswap_v3_lp': 0.4,
                'tx_hash': '0x...',
                'model_confidence': 0.85,
                'safety_bounds': {...},
                'additional_info': {...}
            }

        Returns:
            插入的记录ID
        """
        try:
            data = {
                'pool_symbol': execution.get('pool_symbol'),
                'timestamp': execution.get('timestamp'),
                'aave_wbtc_pool': float(execution.get('aave_wbtc_pool', 0)),
                'uniswap_v3_lp': float(execution.get('uniswap_v3_lp', 0)),
                'tx_hash': execution.get('tx_hash'),
                'model_confidence': execution.get('model_confidence'),
                'safety_bounds': execution.get('safety_bounds'),
                'additional_info': execution.get('additional_info')
            }

            response = supabase.table('strategy_executions').insert(data).execute()
            record_id = response.data[0]['id'] if response.data else None

            logger.info(f"✅ Logged strategy execution (ID: {record_id})")
            return record_id
        except Exception as e:
            logger.error(f"Error inserting strategy execution: {e}")
            raise
    
    @staticmethod
    def get_strategy_executions(
        pool_symbol: str,
        hours: int = 720
    ) -> List[Dict]:
        """获取策略历史"""
        try:
            # 计算时间范围
            cutoff_time = (datetime.now() - timedelta(hours=hours)).isoformat()

            response = supabase.table('strategy_executions').select('*').eq('pool_symbol', pool_symbol).gte('timestamp', cutoff_time).order('timestamp', desc=False).execute()

            results = response.data

            # 转换timestamp（如果需要）
            for r in results:
                if isinstance(r.get('timestamp'), datetime):
                    r['timestamp'] = r['timestamp'].isoformat()

            logger.info(f"📊 Retrieved {len(results)} strategy executions")
            return results
        except Exception as e:
            logger.error(f"Error getting strategy executions: {e}")
            raise
    
    @staticmethod
    def cache_performance_metrics(
        pool_symbol: str,
        period: str,
        metrics: Dict
    ):
        """缓存性能指标"""
        try:
            data = {
                'pool_symbol': pool_symbol,
                'period': period,
                'metrics': metrics,
                'calculated_at': datetime.now().isoformat()
            }

            # Supabase upsert with conflict resolution
            supabase.table('performance_cache').upsert(data, on_conflict='pool_symbol,period').execute()

            logger.info(f"💾 Cached metrics for {pool_symbol} ({period})")
        except Exception as e:
            logger.error(f"Error caching metrics: {e}")
            raise
    
    @staticmethod
    def get_cached_metrics(
        pool_symbol: str,
        period: str,
        max_age_minutes: int = 15
    ) -> Optional[Dict]:
        """获取缓存的指标"""
        try:
            # 计算时间范围
            cutoff_time = (datetime.now() - timedelta(minutes=max_age_minutes)).isoformat()

            response = supabase.table('performance_cache').select('metrics, calculated_at').eq('pool_symbol', pool_symbol).eq('period', period).gte('calculated_at', cutoff_time).execute()

            if response.data and len(response.data) > 0:
                logger.info(f"✅ Cache hit for {pool_symbol} ({period})")
                return response.data[0]
            else:
                logger.info(f"❌ Cache miss for {pool_symbol} ({period})")
                return None
        except Exception as e:
            logger.error(f"Error getting cached metrics: {e}")
            return None
    
    @staticmethod
    def get_database_stats() -> Dict:
        """获取数据库统计信息"""
        try:
            # 快照统计 - Supabase 不直接支持 GROUP BY 聚合，需要使用 RPC 函数或者客户端处理
            # 这里简化处理，获取所有数据后在客户端聚合
            snapshots_response = supabase.table('pool_snapshots').select('pool_symbol, timestamp').execute()

            # 按 pool_symbol 聚合
            snapshot_stats = {}
            for row in snapshots_response.data:
                symbol = row['pool_symbol']
                timestamp = row['timestamp']

                if symbol not in snapshot_stats:
                    snapshot_stats[symbol] = {
                        'pool_symbol': symbol,
                        'count': 0,
                        'earliest': timestamp,
                        'latest': timestamp
                    }

                snapshot_stats[symbol]['count'] += 1
                if timestamp < snapshot_stats[symbol]['earliest']:
                    snapshot_stats[symbol]['earliest'] = timestamp
                if timestamp > snapshot_stats[symbol]['latest']:
                    snapshot_stats[symbol]['latest'] = timestamp

            # 策略统计
            strategies_response = supabase.table('strategy_executions').select('pool_symbol').execute()

            strategy_stats = {}
            for row in strategies_response.data:
                symbol = row['pool_symbol']
                if symbol not in strategy_stats:
                    strategy_stats[symbol] = {'pool_symbol': symbol, 'count': 0}
                strategy_stats[symbol]['count'] += 1

            return {
                'snapshots': list(snapshot_stats.values()),
                'strategies': list(strategy_stats.values())
            }
        except Exception as e:
            logger.error(f"Error getting database stats: {e}")
            return {'snapshots': [], 'strategies': []}