# --- START OF FILE predict_strategy.py ---

import torch
import torch.nn as nn
import numpy as np
import json
import os
import logging
from datetime import datetime
from typing import Dict, Any
from dotenv import load_dotenv

from data_fetcher import MultiPoolDeFiDataFetcher 
from ai_strategy_system import WeeklyStrategyLSTM, create_feature_sequences_from_snapshots

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class StrategyPredictor:
    """
    使用已训练的模型包 (.pth) 来预测最新的DeFi策略。
    """
    def __init__(self, model_package_path: str, device: str = 'cpu'):
        if not os.path.exists(model_package_path):
            raise FileNotFoundError(f"Model package not found at: {model_package_path}")
        
        self.device = torch.device(device)
        logger.info(f"Loading model package from: {model_package_path}")
        
        package = torch.load(model_package_path, map_location=self.device)
        
        self.model = WeeklyStrategyLSTM(input_dim=28)
        self.model.load_state_dict(package['model_state_dict'])
        self.model.to(self.device)
        self.model.eval()
        
        self.scaler = package['scaler']
        self.config = package.get('config', {'lookback_hours': 72})
        self.lookback_hours = self.config['lookback_hours']
        
        logger.info(f"Model loaded successfully. Lookback window: {self.lookback_hours} hours.")

    def prepare_input_data(self, feature_sequences: list) -> torch.Tensor:
        """
        准备用于预测的输入张量。
        """
        if len(feature_sequences) < self.lookback_hours:
            raise ValueError(f"Not enough recent data. Need {self.lookback_hours} hours, but only have {len(feature_sequences)}.")
        
        recent_sequences = feature_sequences[-self.lookback_hours:]
        recent_features = np.array([seq['feature_vector'] for seq in recent_sequences], dtype=np.float32)
        
        scaled_features = self.scaler.transform(recent_features)
        
        input_tensor = torch.FloatTensor(scaled_features).unsqueeze(0).to(self.device)
        
        return input_tensor

    def predict(self, feature_sequences: list) -> np.ndarray:
        """
        执行预测。
        """
        input_tensor = self.prepare_input_data(feature_sequences)
        
        with torch.no_grad():
            prediction = self.model(input_tensor)
        
        return prediction.cpu().numpy()[0]

def get_latest_strategy(pool_symbol: str, pool_config: Dict[str, Any], api_key: str = None) -> Dict:
    """
    为单个池子执行完整的预测流程，并返回策略字典。
    """
    logging.info(f"Generating new strategy for pool: {pool_symbol}")

    # --- 步骤 1: 加载模型 ---
    sanitized_symbol = pool_symbol.replace('/', '-')
    model_package_path = f'models/model_package_{sanitized_symbol}.pth'
    
    try:
        predictor = StrategyPredictor(model_package_path)
    except FileNotFoundError as e:
        logging.error(f"Could not generate strategy for {pool_symbol}: {e}")
        raise e

    # --- 步骤 2: 获取最新数据 ---
    logging.info(f"Fetching latest {predictor.lookback_hours} hours of data...")
    fetcher = MultiPoolDeFiDataFetcher(pools_config={pool_symbol: pool_config}, api_key=api_key)
    weeks_to_fetch = (predictor.lookback_hours / 24 / 7) + 1 
    raw_data = fetcher.run_full_data_collection(weeks=weeks_to_fetch)
    pool_data = raw_data.get('pools', {}).get(pool_symbol)
    if not pool_data or not pool_data.get('snapshots'):
        raise ConnectionError(f"Failed to fetch recent data for {pool_symbol}.")
        
    # --- 步骤 3 & 4: 特征转换和预测 ---
    logging.info("Processing data and predicting...")
    feature_sequences = create_feature_sequences_from_snapshots(
        pool_data['snapshots'], 
        pool_data['aave_current_reserves'],
        pool_data['gas_current']
    )
    strategy_vector = predictor.predict(feature_sequences)

    # --- 步骤 5: 解析并返回结果 ---
    last_snapshot = feature_sequences[-1]
    current_price = last_snapshot['price_current']
    price_bound_pct = strategy_vector[2]

    # Modified: only 2 allocations now
    final_strategy = {
        "pool_symbol": pool_symbol,
        "prediction_generated_at": datetime.now().isoformat(),
        "based_on_data_until": last_snapshot['timestamp'],
        "model_package": model_package_path,
        "allocations": {
            "aave_wbtc_pool": float(strategy_vector[0]),
            "uniswap_v3_lp": float(strategy_vector[1])
        },
        "safety_bounds": {
            "current_price": float(current_price),
            "price_lower_bound": float(current_price * (1 - price_bound_pct)),
            "price_upper_bound": float(current_price * (1 + price_bound_pct)),
            "price_bound_percentage": float(price_bound_pct),
            "price_range": float(current_price * price_bound_pct * 2),  # Added: total range
            "volatility_threshold": float(strategy_vector[3])
        },
        "interpretation": {
            "total_usdc_managed": "100%",
            "wbtc_in_aave_lending": f"{float(strategy_vector[0])*100:.2f}%",
            "wbtc_in_uniswap_lp": f"{float(strategy_vector[1])*100:.2f}%",
            "expected_price_range_usd": f"${float(current_price * (1 - price_bound_pct)):.2f} - ${float(current_price * (1 + price_bound_pct)):.2f}"
        }
    }

    return final_strategy
