"""
数据迁移脚本：将 complete_defi_data.json 导入 PostgreSQL
"""
import json
import os
import sys
from datetime import datetime
from typing import List, Dict
import logging
from dotenv import load_dotenv

from packages.ai_agent.database import DatabaseManager

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

load_dotenv()


class DataMigrator:
    """数据迁移工具"""
    
    def __init__(self, json_file_path: str = 'data/complete_defi_data.json'):
        self.json_file_path = json_file_path
        self.db = DatabaseManager()
        self.stats = {
            'total_snapshots': 0,
            'successful_snapshots': 0,
            'failed_snapshots': 0,
            'pools_processed': 0
        }
    
    def load_json_data(self) -> Dict:
        """加载JSON文件"""
        if not os.path.exists(self.json_file_path):
            raise FileNotFoundError(
                f"❌ JSON文件不存在: {self.json_file_path}\n"
                f"请先运行 data_fetcher.py 获取数据"
            )
        
        logger.info(f"📂 加载数据: {self.json_file_path}")
        with open(self.json_file_path, 'r') as f:
            data = json.load(f)
        
        pools_count = len(data.get('pools', {}))
        logger.info(f"✅ 找到 {pools_count} 个池子的数据")
        
        return data
    
    def transform_snapshot(
        self, 
        pool_symbol: str,
        raw_snap: Dict,
        aave_apy: float,
        gas_cost: float
    ) -> Dict:
        """
        转换单个快照为数据库格式
        
        Args:
            pool_symbol: 池子符号
            raw_snap: 原始快照数据
            aave_apy: Aave APY (小时化)
            gas_cost: Gas费用 (USD)
        
        Returns:
            转换后的快照
        """
        try:
            # 解析时间戳
            timestamp = datetime.fromtimestamp(int(raw_snap['periodStartUnix']))
            
            # 提取价格和交易数据
            wbtc_price = float(raw_snap.get('token0Price', 0))
            volume_usd = float(raw_snap.get('volumeUSD', 0))
            liquidity = float(raw_snap.get('liquidity', 0))
            tvl_usd = float(raw_snap.get('tvlUSD', 1))
            
            # 计算UniV3 LP APY (基于手续费收入)
            # APY ≈ (volume / TVL) * fee_rate
            fee_rate = 0.003  # 0.3% 手续费
            univ3_lp_apy = (volume_usd / tvl_usd) * fee_rate if tvl_usd > 0 else 0
            
            # 限制APY在合理范围 (0-1% 每小时)
            univ3_lp_apy = max(0, min(univ3_lp_apy, 0.01))
            
            return {
                'pool_symbol': pool_symbol,
                'timestamp': timestamp,
                'wbtc_price': wbtc_price,
                'volume_usd': volume_usd,
                'liquidity': liquidity,
                'tvl_usd': tvl_usd,
                'aave_wbtc_apy': aave_apy,
                'univ3_lp_apy': univ3_lp_apy,
                'gas_cost_usd': gas_cost
            }
        
        except Exception as e:
            logger.warning(f"⚠️  跳过异常快照: {e}")
            return None
    
    def migrate_pool_snapshots(self, pool_symbol: str, pool_data: Dict):
        """迁移池子的快照数据"""
        logger.info(f"\n{'='*70}")
        logger.info(f"📊 处理池子: {pool_symbol}")
        logger.info(f"{'='*70}")
        
        # 获取Aave APY
        aave_reserves = pool_data.get('aave_current_reserves', [])
        aave_wbtc_apy = 0.0
        
        for reserve in aave_reserves:
            if reserve.get('symbol') == 'WBTC':
                # liquidityRate 是年化利率 (Ray格式: 1e27)
                annual_rate = float(reserve.get('liquidityRate', 0)) / 1e27
                # 转换为小时APY
                aave_wbtc_apy = annual_rate / (24 * 365)
                logger.info(f"  📈 Aave WBTC APY: {aave_wbtc_apy*100*24*365:.2f}% 年化")
                break
        
        # 获取Gas费用
        gas_data = pool_data.get('gas_current', {})
        gas_cost_usd = gas_data.get('base_fee_gwei', 0.001) * 0.01  # 估算
        
        # 转换所有快照
        raw_snapshots = pool_data.get('snapshots', [])
        logger.info(f"  📦 原始快照数: {len(raw_snapshots)}")
        
        transformed_snapshots = []
        for raw_snap in raw_snapshots:
            snapshot = self.transform_snapshot(
                pool_symbol, 
                raw_snap, 
                aave_wbtc_apy, 
                gas_cost_usd
            )
            if snapshot:
                transformed_snapshots.append(snapshot)
        
        logger.info(f"  ✅ 有效快照数: {len(transformed_snapshots)}")
        
        if not transformed_snapshots:
            logger.warning(f"  ⚠️  没有有效数据，跳过")
            return
        
        # 批量插入 (每次500条，避免超时)
        batch_size = 500
        total_inserted = 0
        
        for i in range(0, len(transformed_snapshots), batch_size):
            batch = transformed_snapshots[i:i + batch_size]
            
            try:
                inserted = self.db.insert_pool_snapshots(batch)
                total_inserted += inserted
                
                progress = (i + len(batch)) / len(transformed_snapshots) * 100
                logger.info(
                    f"  💾 批次 {i//batch_size + 1}: "
                    f"插入 {len(batch)} 条 "
                    f"({progress:.1f}%)"
                )
                
            except Exception as e:
                logger.error(f"  ❌ 批次插入失败: {e}")
                self.stats['failed_snapshots'] += len(batch)
                continue
        
        self.stats['successful_snapshots'] += total_inserted
        self.stats['pools_processed'] += 1
        
        logger.info(f"  ✅ 池子处理完成，共插入 {total_inserted} 条记录")
    
    def migrate_strategy_logs(self):
        """迁移策略执行日志（如果存在）"""
        log_file = 'logs/strategy_executions.jsonl'
        
        if not os.path.exists(log_file):
            logger.info("\n📝 未找到策略日志文件，跳过...")
            return
        
        logger.info(f"\n{'='*70}")
        logger.info("📝 迁移策略执行日志")
        logger.info(f"{'='*70}")
        
        count = 0
        errors = 0
        
        with open(log_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                try:
                    log_entry = json.loads(line.strip())
                    
                    # 准备执行记录
                    execution = {
                        'pool_symbol': log_entry.get('pool_symbol', 'wBTC-USDC'),
                        'timestamp': log_entry.get('timestamp'),
                        'aave_wbtc_pool': float(log_entry.get('aave_wbtc_pool', 0)),
                        'uniswap_v3_lp': float(log_entry.get('uniswap_v3_lp', 0)),
                        'tx_hash': log_entry.get('tx_hash'),
                        'model_confidence': log_entry.get('model_confidence'),
                        'safety_bounds': log_entry.get('safety_bounds'),
                        'additional_info': {
                            k: v for k, v in log_entry.items() 
                            if k not in ['pool_symbol', 'timestamp', 'aave_wbtc_pool', 
                                       'uniswap_v3_lp', 'tx_hash', 'model_confidence', 
                                       'safety_bounds']
                        }
                    }
                    
                    self.db.insert_strategy_execution(execution)
                    count += 1
                    
                    if count % 10 == 0:
                        logger.info(f"  💾 已迁移 {count} 条日志...")
                    
                except Exception as e:
                    errors += 1
                    logger.warning(f"  ⚠️  第{line_num}行解析失败: {e}")
                    continue
        
        logger.info(f"  ✅ 策略日志迁移完成: {count} 成功, {errors} 失败")
    
    def verify_migration(self):
        """验证迁移结果"""
        logger.info(f"\n{'='*70}")
        logger.info("🔍 验证迁移结果")
        logger.info(f"{'='*70}")
        
        try:
            stats = self.db.get_database_stats()
            
            # 显示快照统计
            logger.info("\n📊 池子快照统计:")
            for pool_stat in stats['snapshots']:
                pool = pool_stat['pool_symbol']
                count = pool_stat['count']
                earliest = pool_stat['earliest']
                latest = pool_stat['latest']
                
                logger.info(f"  • {pool}: {count:,} 条记录")
                logger.info(f"    时间范围: {earliest} 至 {latest}")
            
            # 显示策略统计
            if stats['strategies']:
                logger.info("\n🎯 策略执行统计:")
                for strat_stat in stats['strategies']:
                    pool = strat_stat['pool_symbol']
                    count = strat_stat['count']
                    logger.info(f"  • {pool}: {count} 条记录")
            else:
                logger.info("\n🎯 策略执行统计: 暂无数据")
            
            # 总结
            total_snapshots = sum(s['count'] for s in stats['snapshots'])
            total_strategies = sum(s['count'] for s in stats['strategies'])
            
            logger.info(f"\n📈 总计:")
            logger.info(f"  • 快照总数: {total_snapshots:,}")
            logger.info(f"  • 策略记录: {total_strategies}")
            
        except Exception as e:
            logger.error(f"❌ 验证失败: {e}")
    
    def run_full_migration(self):
        """运行完整迁移流程"""
        logger.info("\n" + "="*70)
        logger.info("🚀 开始数据迁移到 PostgreSQL (Supabase)")
        logger.info("="*70)
        
        start_time = datetime.now()
        
        try:
            # 1. 加载JSON数据
            json_data = self.load_json_data()
            
            # 2. 迁移每个池子的快照
            pools = json_data.get('pools', {})
            
            if not pools:
                logger.error("❌ JSON中没有找到池子数据")
                return
            
            self.stats['total_snapshots'] = sum(
                len(pool_data.get('snapshots', [])) 
                for pool_data in pools.values()
            )
            
            for pool_symbol, pool_data in pools.items():
                self.migrate_pool_snapshots(pool_symbol, pool_data)
            
            # 3. 迁移策略日志
            self.migrate_strategy_logs()
            
            # 4. 验证结果
            self.verify_migration()
            
            # 5. 显示总结
            elapsed = (datetime.now() - start_time).total_seconds()
            
            logger.info(f"\n{'='*70}")
            logger.info("✅ 迁移完成！")
            logger.info(f"{'='*70}")
            logger.info(f"⏱️  耗时: {elapsed:.1f} 秒")
            logger.info(f"📊 统计:")
            logger.info(f"  • 处理池子数: {self.stats['pools_processed']}")
            logger.info(f"  • 快照总数: {self.stats['total_snapshots']:,}")
            logger.info(f"  • 成功插入: {self.stats['successful_snapshots']:,}")
            logger.info(f"  • 失败: {self.stats['failed_snapshots']}")
            
            logger.info(f"\n📚 下一步:")
            logger.info(f"  1. 启动 Analytics API: python analytics_api.py")
            logger.info(f"  2. 测试接口: curl http://localhost:8001/api/v1/analytics/health")
            logger.info(f"  3. 修改 agent.py 启用数据库日志")
            
        except Exception as e:
            logger.error(f"\n❌ 迁移失败: {e}", exc_info=True)
            sys.exit(1)


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='将 DeFi 数据从 JSON 迁移到 PostgreSQL'
    )
    parser.add_argument(
        '--json-file',
        default='data/complete_defi_data.json',
        help='JSON 数据文件路径'
    )
    parser.add_argument(
        '--verify-only',
        action='store_true',
        help='仅验证现有数据，不执行迁移'
    )
    
    args = parser.parse_args()
    
    migrator = DataMigrator(json_file_path=args.json_file)
    
    if args.verify_only:
        migrator.verify_migration()
    else:
        migrator.run_full_migration()


if __name__ == "__main__":
    main()