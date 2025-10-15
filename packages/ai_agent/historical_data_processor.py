"""
历史数据处理器
从Subgraph数据和AI策略日志中构建完整的分析数据集
"""

import json
import os
import pandas as pd
import numpy as np
from datetime import datetime
from typing import Dict, List, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class HistoricalDataProcessor:
    """处理历史数据，为量化分析提供数据源"""
    
    def __init__(self, data_dir: str = "data", logs_dir: str = "logs"):
        self.data_dir = data_dir
        self.logs_dir = logs_dir
        
        # 确保日志目录存在
        os.makedirs(logs_dir, exist_ok=True)
    
    def load_pool_historical_data(self, pool_symbol: str = "wBTC-USDC") -> pd.DataFrame:
        """
        从 complete_defi_data.json 加载池子的历史快照数据
        
        Returns:
            DataFrame with columns:
                - timestamp
                - wbtc_price (token0Price)
                - volume_usd
                - liquidity
                - tvl_usd
        """
        data_file = os.path.join(self.data_dir, "complete_defi_data.json")
        
        if not os.path.exists(data_file):
            raise FileNotFoundError(f"Data file not found: {data_file}")
        
        with open(data_file, 'r') as f:
            data = json.load(f)
        
        pool_data = data.get('pools', {}).get(pool_symbol)
        if not pool_data:
            raise ValueError(f"Pool {pool_symbol} not found in data")
        
        snapshots = pool_data['snapshots']
        
        df = pd.DataFrame(snapshots)
        df['timestamp'] = pd.to_datetime(df['periodStartUnix'], unit='s')
        
        # 提取关键字段并转换类型
        df['wbtc_price'] = pd.to_numeric(df['token0Price'], errors='coerce')
        df['volume_usd'] = pd.to_numeric(df['volumeUSD'], errors='coerce')
        df['liquidity'] = pd.to_numeric(df['liquidity'], errors='coerce')
        df['tvl_usd'] = pd.to_numeric(df['tvlUSD'], errors='coerce')
        
        # 计算小时APY（基于交易量和TVL）
        # LP APY ≈ (hourly_volume / TVL) * fee_tier * hours_per_year
        fee_tier = 0.003  # Uniswap V3 通常是0.3%
        df['univ3_lp_apy'] = (df['volume_usd'] / df['tvl_usd'].replace(0, np.nan)) * fee_tier
        df['univ3_lp_apy'] = df['univ3_lp_apy'].fillna(0).clip(0, 0.01)  # 限制在合理范围
        
        df = df.sort_values('timestamp').reset_index(drop=True)
        
        logger.info(f"Loaded {len(df)} hourly snapshots for {pool_symbol}")
        
        return df[['timestamp', 'wbtc_price', 'volume_usd', 'liquidity', 'tvl_usd', 'univ3_lp_apy']]
    
    def load_aave_apy_data(self, pool_symbol: str = "wBTC-USDC") -> Dict:
        """
        从 complete_defi_data.json 加载 Aave 当前的 APY
        
        Returns:
            {
                'wbtc_apy': 0.0001,  # 小时化APY
                'last_update': '2024-01-01T00:00:00'
            }
        """
        data_file = os.path.join(self.data_dir, "complete_defi_data.json")
        
        with open(data_file, 'r') as f:
            data = json.load(f)
        
        pool_data = data.get('pools', {}).get(pool_symbol)
        aave_reserves = pool_data.get('aave_current_reserves', [])
        
        wbtc_apy_annual = 0.0
        for reserve in aave_reserves:
            if reserve['symbol'] == 'WBTC':
                # liquidityRate 是年化APY (Ray格式: 1e27)
                wbtc_apy_annual = float(reserve.get('liquidityRate', 0)) / 1e27
                break
        
        # 转换为小时APY
        wbtc_apy_hourly = wbtc_apy_annual / (24 * 365)
        
        return {
            'wbtc_apy': wbtc_apy_hourly,
            'last_update': datetime.now().isoformat()
        }
    
    def load_strategy_execution_logs(self) -> pd.DataFrame:
        """
        从日志文件中加载AI agent的历史执行记录
        
        这需要你在 agent.py 中添加日志记录功能
        
        Returns:
            DataFrame with columns:
                - timestamp
                - aave_wbtc_pool
                - uniswap_v3_lp
                - tx_hash
        """
        log_file = os.path.join(self.logs_dir, "strategy_executions.jsonl")
        
        if not os.path.exists(log_file):
            logger.warning(f"Strategy log file not found: {log_file}")
            logger.info("Returning empty log. Please implement logging in agent.py")
            return pd.DataFrame(columns=['timestamp', 'aave_wbtc_pool', 'uniswap_v3_lp'])
        
        logs = []
        with open(log_file, 'r') as f:
            for line in f:
                try:
                    logs.append(json.loads(line))
                except:
                    continue
        
        if not logs:
            return pd.DataFrame(columns=['timestamp', 'aave_wbtc_pool', 'uniswap_v3_lp'])
        
        df = pd.DataFrame(logs)
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        
        return df.sort_values('timestamp').reset_index(drop=True)
    
    def build_complete_historical_dataset(
        self, 
        pool_symbol: str = "wBTC-USDC"
    ) -> Dict[str, List[Dict]]:
        """
        构建完整的历史数据集，供分析引擎使用
        
        Returns:
            {
                'historical_data': [...],  # 每小时的市场数据
                'strategy_allocations': [...]  # AI的历史配置
            }
        """
        # 1. 加载池子数据
        pool_df = self.load_pool_historical_data(pool_symbol)
        
        # 2. 加载Aave APY（假设相对稳定，用最新值填充历史）
        aave_data = self.load_aave_apy_data(pool_symbol)
        pool_df['aave_wbtc_apy'] = aave_data['wbtc_apy']
        
        # 3. 模拟Gas费用（可以从链上获取，这里简化处理）
        pool_df['gas_cost_usd'] = 0.05  # Base链gas费很低
        
        historical_data = pool_df.to_dict('records')
        
        # 4. 加载策略执行日志
        strategy_df = self.load_strategy_execution_logs()
        
        if strategy_df.empty:
            # 如果没有日志，使用模型输出的策略文件作为fallback
            logger.info("No execution logs found, using strategy output files...")
            strategy_allocations = self._load_strategy_from_model_output(pool_symbol)
        else:
            strategy_allocations = strategy_df.to_dict('records')
        
        logger.info(f"Built dataset with {len(historical_data)} market snapshots "
                   f"and {len(strategy_allocations)} strategy points")
        
        return {
            'historical_data': historical_data,
            'strategy_allocations': strategy_allocations
        }
    
    def _load_strategy_from_model_output(self, pool_symbol: str) -> List[Dict]:
        """
        从模型输出文件中加载策略（仅作为fallback）
        """
        sanitized_symbol = pool_symbol.replace('/', '-')
        strategy_file = f'models/strategy_output_{sanitized_symbol}.json'
        
        if not os.path.exists(strategy_file):
            logger.warning("No strategy output file found. Returning default 50-50 allocation.")
            return [{
                'timestamp': datetime.now().isoformat(),
                'aave_wbtc_pool': 0.5,
                'uniswap_v3_lp': 0.5
            }]
        
        with open(strategy_file, 'r') as f:
            strategy = json.load(f)
        
        return [{
            'timestamp': strategy['generated_at'],
            'aave_wbtc_pool': strategy['allocations']['aave_wbtc_pool'],
            'uniswap_v3_lp': strategy['allocations']['uniswap_v3_lp']
        }]
    
    def save_strategy_execution(
        self,
        allocations: Dict[str, float],
        tx_hash: str,
        additional_info: Dict = None
    ):
        """
        保存每次策略执行记录（供agent.py调用）
        
        Args:
            allocations: {'aave_wbtc_pool': 0.6, 'uniswap_v3_lp': 0.4}
            tx_hash: 交易哈希
            additional_info: 其他信息（如gas费用、模型置信度等）
        """
        log_file = os.path.join(self.logs_dir, "strategy_executions.jsonl")
        
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'aave_wbtc_pool': allocations.get('aave_wbtc_pool', 0),
            'uniswap_v3_lp': allocations.get('uniswap_v3_lp', 0),
            'tx_hash': tx_hash,
            **(additional_info or {})
        }
        
        with open(log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')
        
        logger.info(f"Strategy execution logged: {tx_hash}")


# ===== 使用示例 =====
if __name__ == "__main__":
    processor = HistoricalDataProcessor()
    
    # 构建完整数据集
    dataset = processor.build_complete_historical_dataset("wBTC-USDC")
    
    print(f"Historical data points: {len(dataset['historical_data'])}")
    print(f"Strategy allocation points: {len(dataset['strategy_allocations'])}")
    
    # 查看第一条记录
    if dataset['historical_data']:
        print("\nSample market data:")
        print(dataset['historical_data'][0])
    
    if dataset['strategy_allocations']:
        print("\nSample strategy allocation:")
        print(dataset['strategy_allocations'][0])

        