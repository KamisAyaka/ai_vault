"""
数据库操作封装 - PostgreSQL 直连版（兼容 Supabase）
"""

import os
import json
import logging
import psycopg2
import psycopg2.extras
from decimal import Decimal
from typing import List, Dict, Optional
from datetime import datetime, timedelta
from dotenv import load_dotenv

# ========== 初始化 ==========
load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("❌ DATABASE_URL not found in environment variables")

def get_connection():
    """获取数据库连接"""
    return psycopg2.connect(DATABASE_URL, sslmode="require")


class DatabaseManager:
    """数据库操作类"""
    @staticmethod
    def get_database_stats() -> Dict:
        """简单的数据库统计（用于健康检查）"""
        try:
            conn = get_connection()
            with conn.cursor() as cur:
                cur.execute("SELECT COUNT(*) FROM pool_snapshots;")
                snapshots_count = cur.fetchone()[0]
                cur.execute("SELECT COUNT(*) FROM strategy_executions;")
                strategies_count = cur.fetchone()[0]
            return {
                "snapshots_count": int(snapshots_count),
                "strategies_count": int(strategies_count),
                "status": "ok"
            }
        except Exception as e:
            logger.error(f"get_database_stats error: {e}", exc_info=True)
            return {"status": "error", "error": str(e)}
        finally:
            try:
                conn.close()
            except Exception:
                pass


    # ========== 池子快照 ==========
    @staticmethod
    def insert_pool_snapshots(snapshots: List[Dict]) -> int:
        """批量插入池子快照"""
        if not snapshots:
            return 0

        sql = """
        INSERT INTO pool_snapshots (
            pool_symbol, timestamp, wbtc_price, volume_usd, liquidity, tvl_usd,
            aave_wbtc_apy, univ3_lp_apy, gas_cost_usd
        )
        VALUES %s
        ON CONFLICT (pool_symbol, timestamp) DO UPDATE SET
            wbtc_price = EXCLUDED.wbtc_price,
            volume_usd = EXCLUDED.volume_usd,
            liquidity = EXCLUDED.liquidity,
            tvl_usd = EXCLUDED.tvl_usd,
            aave_wbtc_apy = EXCLUDED.aave_wbtc_apy,
            univ3_lp_apy = EXCLUDED.univ3_lp_apy,
            gas_cost_usd = EXCLUDED.gas_cost_usd
        """

        values = [
            (
                s.get("pool_symbol"),
                s.get("timestamp"),
                float(s.get("wbtc_price", 0)),
                float(s.get("volume_usd", 0)),
                float(s.get("liquidity", 0)),
                float(s.get("tvl_usd", 0)),
                float(s.get("aave_wbtc_apy", 0)),
                float(s.get("univ3_lp_apy", 0)),
                float(s.get("gas_cost_usd", 0))
            )
            for s in snapshots
        ]

        try:
            conn = get_connection()
            with conn.cursor() as cur:
                psycopg2.extras.execute_values(cur, sql, values)
            conn.commit()
            logger.info(f"✅ Inserted/Updated {len(values)} pool snapshots")
            return len(values)
        except Exception as e:
            logger.error(f"❌ Error inserting pool snapshots: {e}", exc_info=True)
            if conn:
                conn.rollback()
            raise
        finally:
            if conn:
                conn.close()

    @staticmethod
    def get_pool_snapshots(pool_symbol: str, hours: int = 720, limit: Optional[int] = None) -> List[Dict]:
        """获取池子历史快照（并把 Decimal 转为 float，timestamp 转为 ISO）"""
        try:
            cutoff = (datetime.now() - timedelta(hours=hours))
            sql = """
            SELECT * FROM pool_snapshots
            WHERE pool_symbol = %s AND timestamp >= %s
            ORDER BY timestamp ASC
            """
            if limit:
                sql += f" LIMIT {limit}"

            conn = get_connection()
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(sql, (pool_symbol, cutoff))
                rows = cur.fetchall() or []

            # 转换 Decimal -> float，转换 timestamp -> ISO str
            cleaned = []
            numeric_keys = {'wbtc_price', 'volume_usd', 'liquidity', 'tvl_usd',
                            'aave_wbtc_apy', 'univ3_lp_apy', 'gas_cost_usd'}
            for r in rows:
                newr = dict(r)
                # timestamp -> ISO string
                ts = newr.get('timestamp')
                if isinstance(ts, datetime):
                    newr['timestamp'] = ts.isoformat()
                # convert decimals
                for k in numeric_keys:
                    v = newr.get(k)
                    if isinstance(v, Decimal):
                        newr[k] = float(v)
                    elif v is None:
                        newr[k] = 0.0
                    else:
                        try:
                            newr[k] = float(v)
                        except Exception:
                            # leave as is if cannot cast
                            pass
                cleaned.append(newr)

            logger.info(f"📊 Retrieved {len(cleaned)} snapshots for {pool_symbol}")
            return cleaned
        except Exception as e:
            logger.error(f"Error getting pool snapshots: {e}", exc_info=True)
            return []
        finally:
            try:
                conn.close()
            except Exception:
                pass


    # ========== 策略执行 ==========
    @staticmethod
    def insert_strategy_execution(execution: Dict) -> Optional[int]:
        """插入策略执行记录"""
        sql = """
        INSERT INTO strategy_executions (
            pool_symbol, timestamp, aave_wbtc_pool, uniswap_v3_lp, tx_hash,
            model_confidence, safety_bounds, additional_info
        )
        VALUES (%(pool_symbol)s, %(timestamp)s, %(aave_wbtc_pool)s, %(uniswap_v3_lp)s,
                %(tx_hash)s, %(model_confidence)s, %(safety_bounds)s, %(additional_info)s)
        RETURNING id
        """
        try:
            conn = get_connection()
            with conn.cursor() as cur:
                cur.execute(sql, {
                    **execution,
                    "safety_bounds": json.dumps(execution.get("safety_bounds", {})),
                    "additional_info": json.dumps(execution.get("additional_info", {}))
                })
                record_id = cur.fetchone()[0]
            conn.commit()
            logger.info(f"✅ Logged strategy execution (ID={record_id})")
            return record_id
        except Exception as e:
            logger.error(f"❌ Error inserting strategy execution: {e}", exc_info=True)
            if conn:
                conn.rollback()
            return None
        finally:
            if conn:
                conn.close()

    @staticmethod
    def get_strategy_executions(pool_symbol: str, hours: int = 720) -> List[Dict]:
        """获取策略执行历史"""
        cutoff = datetime.now() - timedelta(hours=hours)
        sql = """
        SELECT * FROM strategy_executions
        WHERE pool_symbol = %s AND timestamp >= %s
        ORDER BY timestamp DESC
        """

        try:
            conn = get_connection()
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(sql, (pool_symbol, cutoff))
                rows = cur.fetchall()
            logger.info(f"📈 Retrieved {len(rows)} strategy executions for {pool_symbol}")
            return rows
        except Exception as e:
            logger.error(f"❌ Error getting strategy executions: {e}", exc_info=True)
            return []
        finally:
            if conn:
                conn.close()

    # ========== 缓存指标 ==========
    @staticmethod
    def cache_performance_metrics(pool_symbol: str, period: str, metrics: Dict):
        """缓存性能指标"""
        sql = """
        INSERT INTO performance_cache (pool_symbol, period, metrics, calculated_at)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (pool_symbol, period)
        DO UPDATE SET
            metrics = EXCLUDED.metrics,
            calculated_at = EXCLUDED.calculated_at
        """
        try:
            conn = get_connection()
            with conn.cursor() as cur:
                cur.execute(sql, (
                    pool_symbol, period, json.dumps(metrics), datetime.now()
                ))
            conn.commit()
            logger.info(f"💾 Cached performance metrics for {pool_symbol} ({period})")
        except Exception as e:
            logger.error(f"❌ Error caching metrics: {e}", exc_info=True)
            if conn:
                conn.rollback()
        finally:
            if conn:
                conn.close()

    @staticmethod
    def get_cached_metrics(pool_symbol: str, period: str, max_age_minutes: int = 15) -> Optional[Dict]:
        """获取缓存的性能指标"""
        sql = """
        SELECT metrics, calculated_at FROM performance_cache
        WHERE pool_symbol = %s AND period = %s AND calculated_at >= %s
        """
        cutoff = datetime.now() - timedelta(minutes=max_age_minutes)
        try:
            conn = get_connection()
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(sql, (pool_symbol, period, cutoff))
                row = cur.fetchone()
            return json.loads(row["metrics"]) if row else None
        except Exception as e:
            logger.error(f"❌ Error getting cached metrics: {e}", exc_info=True)
            return None
        finally:
            if conn:
                conn.close()
