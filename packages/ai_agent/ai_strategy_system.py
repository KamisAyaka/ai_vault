# 使用LSTM+attention训练,采用滑动窗口构建训练样本,输入为72小时的特征向量序列(28维)

import numpy as np
import pandas as pd
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from sklearn.preprocessing import StandardScaler
import json
import os
from typing import Dict, List, Tuple
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def create_feature_sequences_from_snapshots(snapshots: List[Dict], aave_reserves: List[Dict], gas_data: Dict) -> List[Dict]:
    if not snapshots: return []
        
    df = pd.DataFrame(snapshots)
    numeric_cols = ['token0Price', 'volumeUSD', 'liquidity', 'tvlUSD']
    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors='coerce')
    df['timestamp'] = pd.to_datetime(df['periodStartUnix'], unit='s')
    df = df.sort_values('timestamp').ffill().fillna(0)

    df['price_ma_24'] = df['token0Price'].rolling(24, min_periods=1).mean()
    df['price_return_1h'] = df['token0Price'].pct_change(1).fillna(0)
    df['price_volatility_24h'] = df['price_return_1h'].rolling(24, min_periods=1).std().fillna(0)
    df['volume_ma_24'] = df['volumeUSD'].rolling(24, min_periods=1).mean()
    df['tvl_change_24h'] = df['tvlUSD'].pct_change(24).fillna(0)

    # usdc_apy = 3.5
    wbtc_apy = 0.1 
    for reserve in aave_reserves:
        # if reserve['symbol'] == 'USDC':
        if reserve['symbol'] == 'WBTC':
            usdc_apy = (float(reserve.get('liquidityRate', 0)) / 1e27) * 100
            logger.info(f"USDC APY from AAVE: {usdc_apy:.2f}%")
            break

    feature_sequences = []
    for _, row in df.iterrows():
        feature_vector = [
            row['token0Price'], row['price_ma_24'], row['price_return_1h'], row['price_volatility_24h'],
            row['volumeUSD'], row['volume_ma_24'],
            row['liquidity'], row['tvlUSD'], row['tvl_change_24h'],
            wbtc_apy, 
            gas_data.get('base_fee_gwei', 0.001),
            np.sin(2 * np.pi * row['timestamp'].hour / 24)
        ]
        padding = [0] * (28 - len(feature_vector))
        feature_vector.extend(padding)

        feature_sequences.append({
            'timestamp': row['timestamp'].isoformat(),
            'price_current': row['token0Price'],
            'feature_vector': feature_vector
        })
    return feature_sequences

# 使用滑动窗口,从连续的时间序列数据中创建离散的训练数据
class WeeklyStrategyDataset(Dataset):
    def __init__(self, feature_sequences: List[Dict], lookback_hours: int, prediction_hours: int, stride: int):
        self.features = np.array([f['feature_vector'] for f in feature_sequences], dtype=np.float32)
        self.lookback_hours = lookback_hours
        self.prediction_hours = prediction_hours
        self.stride = stride
        max_start_index = len(self.features) - lookback_hours - prediction_hours
        self.num_samples = max(0, (max_start_index // stride) + 1)
        logger.info(f"  Dataset created with {self.num_samples} samples (from {len(self.features)} data points).")
        logger.info(f"  Configuration: lookback={lookback_hours}h, prediction={prediction_hours}h, stride={stride}h")

    def __len__(self):
        return self.num_samples

    def __getitem__(self, idx):
        start_idx = idx * self.stride
        X = self.features[start_idx : start_idx + self.lookback_hours]
        future_window = self.features[start_idx + self.lookback_hours : start_idx + self.lookback_hours + self.prediction_hours]
        y = self._calculate_optimal_allocation_from_future(X, future_window)
        return torch.FloatTensor(X), torch.FloatTensor(y)

    # 这个函数是学习的关键
    def _calculate_optimal_allocation_from_future(self, historical: np.ndarray, future: np.ndarray) -> List[float]:
        # 安全检查
        if len(future) == 0 or len(historical) == 0:
            return [0.5, 0.5, 0.02, 0.005]
        
        # 调试模式：每100个样本打印一次详细信息
        debug_this_sample = (np.random.random() < 0.01)  # 1%概率打印
        
        # === 因子1: 波动率因子 ===
        # 使用未来价格波动率的标准差
        future_volatility = np.std(future[:, 3]) if len(future[:, 3]) > 1 else np.mean(future[:, 3])
        # 高波动 -> 倾向稳定的AAVE
        # sigmoid函数优化: 限制输入范围防止overflow
        vol_input = np.clip((future_volatility - 0.003) * 1000, -10, 10)
        volatility_score = 1 / (1 + np.exp(-vol_input))
        
        # === 因子2: 流动性/交易量因子 ===
        hist_volume_mean = np.mean(historical[:, 4]) if len(historical) > 0 else 1e-8
        future_volume_mean = np.mean(future[:, 4]) if len(future) > 0 else 0
        volume_growth = (future_volume_mean - hist_volume_mean) / (hist_volume_mean + 1e-8)
        # 交易量增加 -> LP更有吸引力(手续费收入增加)
        volume_input = np.clip(volume_growth * 10, -10, 10)
        volume_score = 1 / (1 + np.exp(-volume_input))
        
        # === 因子3: TVL变化因子 ===
        tvl_change = np.mean(future[:, 8]) if len(future) > 0 else 0  # tvl_change_24h
        # TVL增加 -> 市场信心增强,倾向LP
        tvl_input = np.clip(tvl_change * 50, -10, 10)
        tvl_score = 1 / (1 + np.exp(-tvl_input))
        
        # === 因子4: 价格趋势因子 ===
        if len(future) > 0 and future[0, 0] > 1e-8:
            price_trend = (future[-1, 0] - future[0, 0]) / (future[0, 0] + 1e-8)
        else:
            price_trend = 0
        # 强趋势 -> 可能有无常损失,倾向AAVE
        trend_strength = abs(price_trend)
        trend_input = np.clip((trend_strength - 0.02) * 200, -10, 10)
        trend_score = 1 / (1 + np.exp(-trend_input))
        
        # === 因子5: 收益率差异 ===
        # usdc_apy = np.clip(historical[-1, 9] / 100, 0, 1)  # 转换为小数并限制范围
        aave_wbtc_apy = np.clip(historical[-1, 9] / 100, 0, 1) # 从特征向量中获取wBTC的APY
        # 估算LP的年化收益率: (交易量/TVL) * 手续费率 * 年化倍数
        avg_future_volume = np.mean(future[:, 4]) if len(future) > 0 else 0
        avg_future_tvl = np.mean(future[:, 7]) if len(future) > 0 else 1e-8
        estimated_lp_apy = np.clip((avg_future_volume / (avg_future_tvl + 1e-8)) * 0.003 * 365 * 24, 0, 10)
        # apy_diff = estimated_lp_apy - usdc_apy
        apy_diff = estimated_lp_apy - aave_wbtc_apy
        # LP APY更高 -> 倾向LP
        apy_input = np.clip(apy_diff * 5, -10, 10)  # 降低放大倍数从100到5
        apy_score = 1 / (1 + np.exp(-apy_input))
        
        # === 综合评分 ===
        # AAVE得分(保守型策略得分)
        aave_score = (
            volatility_score * 0.35 +      # 波动越高越倾向AAVE
            (1 - volume_score) * 0.15 +    # 交易量低倾向AAVE
            (1 - tvl_score) * 0.15 +       # TVL下降倾向AAVE
            trend_score * 0.20 +           # 强趋势倾向AAVE(避免无常损失)
            (1 - apy_score) * 0.15         # 收益率差距小倾向AAVE
        )
        
        # LP得分(进取型策略得分)
        lp_score = 1 - aave_score
        
        # 归一化配比
        total = aave_score + lp_score
        aave_allocation = aave_score / total if total > 0 else 0.5
        lp_allocation = lp_score / total if total > 0 else 0.5
        
        # 施加约束,避免过度集中在单一资产
        aave_allocation = np.clip(aave_allocation, 0.15, 0.85)
        lp_allocation = 1 - aave_allocation
        
        # 调试输出
        if debug_this_sample:
            logger.debug(f"\n  [Sample Debug] Scores: vol={volatility_score:.3f}, volume={volume_score:.3f}, "
                        f"tvl={tvl_score:.3f}, trend={trend_score:.3f}, apy={apy_score:.3f}")
            # logger.debug(f"  [Sample Debug] Final: AAVE={aave_allocation:.3f}, LP={lp_allocation:.3f}, "
            #             f"estimated_lp_apy={estimated_lp_apy:.4f}, usdc_apy={usdc_apy:.4f}")
            logger.debug(f"  [Sample Debug] Final: AAVE={aave_allocation:.3f}, LP={lp_allocation:.3f}, "
                        f"estimated_lp_apy={estimated_lp_apy:.4f}, usdc_apy={aave_wbtc_apy:.4f}")
        
        # === 动态价格边界和波动率阈值 ===
        # 价格边界: 基础值 + 波动率调整
        price_bound = np.clip(0.015 + future_volatility * 2, 0.01, 0.04)
        # 波动率阈值: 基础值 + 当前波动率
        vol_thresh = np.clip(0.004 + future_volatility, 0.003, 0.01)
        
        return [float(aave_allocation), float(lp_allocation), float(price_bound), float(vol_thresh)]

# 使用双向LSTM、Attention机制和全连接网络
class WeeklyStrategyLSTM(nn.Module):
    def __init__(self, input_dim: int = 28, hidden_dim: int = 128, num_layers: int = 2):
        super(WeeklyStrategyLSTM, self).__init__()
        self.lstm = nn.LSTM(input_dim, hidden_dim, num_layers, batch_first=True, bidirectional=True, dropout=0.2 if num_layers > 1 else 0)
        self.attention = nn.MultiheadAttention(embed_dim=hidden_dim * 2, num_heads=8, dropout=0.1, batch_first=True)
        self.feature_extractor = nn.Sequential(nn.Linear(hidden_dim * 2, 128), nn.ReLU(), nn.LayerNorm(128), nn.Dropout(0.3), nn.Linear(128, 64), nn.ReLU())
        self.allocation_head = nn.Sequential(nn.Linear(64, 32), nn.ReLU(), nn.Linear(32, 2))
        self.boundary_head = nn.Sequential(nn.Linear(64, 16), nn.ReLU(), nn.Linear(16, 2))
        self.softmax = nn.Softmax(dim=-1)
        self.sigmoid = nn.Sigmoid()
    
    def forward(self, x):
        lstm_out, _ = self.lstm(x)
        attn_out, _ = self.attention(lstm_out, lstm_out, lstm_out)
        final_features = attn_out[:, -1, :]
        extracted = self.feature_extractor(final_features)
        allocations = self.softmax(self.allocation_head(extracted))
        boundaries = self.sigmoid(self.boundary_head(extracted)) * 0.03
        return torch.cat([allocations, boundaries], dim=1)

class WeeklyStrategyTrainer:
    def __init__(self, model: nn.Module, device: str, model_save_path: str):
        self.model = model.to(device)
        self.device = device
        self.model_save_path = model_save_path
        self.optimizer = optim.AdamW(self.model.parameters(), lr=0.0001, weight_decay=0.01)
        self.scheduler = optim.lr_scheduler.ReduceLROnPlateau(self.optimizer, 'min', factor=0.5, patience=5)
        self.allocation_loss_fn = nn.MSELoss()
        self.boundary_loss_fn = nn.MSELoss()

    def train_epoch(self, loader):
        self.model.train(); total_loss = 0
        for x, y in loader:
            x, y = x.to(self.device), y.to(self.device)
            p = self.model(x)
            loss = 0.7 * self.allocation_loss_fn(p[:,:2], y[:,:2]) + 0.3 * self.boundary_loss_fn(p[:,2:], y[:,2:])
            if torch.isnan(loss): continue
            self.optimizer.zero_grad(); loss.backward()
            torch.nn.utils.clip_grad_norm_(self.model.parameters(), 0.5)
            self.optimizer.step()
            total_loss += loss.item()
        return total_loss / len(loader) if len(loader) > 0 else float('inf')

    def validate(self, loader):
        self.model.eval(); total_loss = 0
        preds, labels = [], []
        with torch.no_grad():
            for x, y in loader:
                x, y = x.to(self.device), y.to(self.device)
                p = self.model(x)
                if torch.isnan(p).any(): return float('inf'), {}
                loss = 0.7 * self.allocation_loss_fn(p[:,:2], y[:,:2]) + 0.3 * self.boundary_loss_fn(p[:,2:], y[:,2:])
                total_loss += loss.item()
                preds.append(p.cpu().numpy()); labels.append(y.cpu().numpy())
        if not preds: return float('inf'), {}
        avg_loss = total_loss / len(loader)
        p, l = np.vstack(preds), np.vstack(labels)
        metrics = {'mae': np.mean(np.abs(p - l))}
        return avg_loss, metrics

    def train(self, train_loader, val_loader, epochs=100, patience=15):
        best_loss = float('inf'); counter = 0
        for epoch in range(epochs):
            train_loss = self.train_epoch(train_loader)
            val_loss, _ = self.validate(val_loader)
            self.scheduler.step(val_loss)
            if np.isnan(val_loss) or np.isnan(train_loss):
                logger.error("Loss became NaN. Stopping training."); break
            if val_loss < best_loss:
                best_loss = val_loss; counter = 0
                torch.save(self.model.state_dict(), self.model_save_path)
            else:
                counter += 1
            if (epoch+1)%10==0: logger.info(f"  Epoch {epoch+1}/{epochs}, Train Loss: {train_loss:.6f}, Val Loss: {val_loss:.6f}")
            if counter >= patience: logger.info(f"  Early stopping at epoch {epoch+1}."); break
        if os.path.exists(self.model_save_path): self.model.load_state_dict(torch.load(self.model_save_path))
        return best_loss


def main():
    print("\n" + "="*70)
    print("      DeFi Multi-Pool AI Strategy Training System (Optimized)")
    print("="*70)
    
    try:
        logger.info("\n[1] Loading master data file...")
        data_file = os.path.join("data", "complete_defi_data.json")
        if not os.path.exists(data_file):
            raise FileNotFoundError(f"{data_file} not found. Please run data_fetcher.py first.")
        with open(data_file, 'r') as f:
            master_data = json.load(f)

        pools_data = master_data.get('pools', {})
        if not pools_data:
            raise ValueError("No pool data found in the master file.")
            
        os.makedirs('models', exist_ok=True)

        for pool_symbol, pool_data in pools_data.items():
            print("\n" + "="*70)
            logger.info(f"[POOL] Starting training pipeline for: {pool_symbol}")
            print("="*70)

            logger.info(f"  [A] Generating feature sequences...")
            feature_sequences = create_feature_sequences_from_snapshots(
                pool_data['snapshots'], 
                pool_data['aave_current_reserves'],
                pool_data['gas_current']
            )
            if len(feature_sequences) < 168:
                logger.warning(f"  Skipping {pool_symbol}: not enough data points ({len(feature_sequences)}). Need at least 168.")
                continue

            logger.info(f"  [B] Scaling features...")
            features = np.array([f['feature_vector'] for f in feature_sequences], dtype=np.float32)
            scaler = StandardScaler()
            features_scaled = scaler.fit_transform(features)
            for i, seq in enumerate(feature_sequences):
                seq['feature_vector'] = features_scaled[i]

            logger.info(f"  [C] Creating dataset with multi-factor labeling strategy...")
            dataset = WeeklyStrategyDataset(
                feature_sequences, lookback_hours=72, prediction_hours=24, stride=12
            )
            if len(dataset) < 10:
                logger.warning(f"  Skipping {pool_symbol}: not enough training samples generated ({len(dataset)}). Need at least 10.")
                continue
            
            train_size = int(len(dataset) * 0.8)
            val_size = len(dataset) - train_size
            train_dataset, val_dataset = torch.utils.data.random_split(dataset, [train_size, val_size])
            train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True)
            val_loader = DataLoader(val_dataset, batch_size=32, shuffle=False)

            logger.info(f"  [D] Initializing and training model...")
            device = 'cuda' if torch.cuda.is_available() else 'cpu'
            logger.info(f"  Using device: {device}")
            model = WeeklyStrategyLSTM(input_dim=28).to(device)
            model_save_path = f'models/best_model_{pool_symbol.replace("/", "-")}.pth'
            trainer = WeeklyStrategyTrainer(model, device, model_save_path)
            best_loss = trainer.train(train_loader, val_loader, epochs=100, patience=15)

            logger.info(f"  [E] Generating and saving strategy...")
            model.eval()
            with torch.no_grad():
                recent_features_scaled = np.array([f['feature_vector'] for f in feature_sequences[-72:]], dtype=np.float32)
                input_tensor = torch.FloatTensor(recent_features_scaled).unsqueeze(0).to(device)
                pred = model(input_tensor).cpu().numpy()[0]

                last_seq = feature_sequences[-1]
                current_price = last_seq['price_current']
                
                # 分析最近数据的市场状况
                recent_data = np.array([f['feature_vector'] for f in feature_sequences[-168:]])  # 最近7天
                recent_volatility = np.std(recent_data[:, 3])
                recent_volume_trend = (np.mean(recent_data[-24:, 4]) / (np.mean(recent_data[:24, 4]) + 1e-8)) - 1
                recent_price_trend = (recent_data[-1, 0] - recent_data[0, 0]) / (recent_data[0, 0] + 1e-8)
                
                logger.info(f"  [Market Analysis] Recent 7-day statistics:")
                logger.info(f"    - Price Volatility: {recent_volatility:.6f}")
                logger.info(f"    - Volume Trend: {recent_volume_trend:+.2%}")
                logger.info(f"    - Price Trend: {recent_price_trend:+.2%}")
                logger.info(f"    - Current Price: ${current_price:.2f}")
                
                strategy = {
                    "pool_symbol": pool_symbol,
                    "generated_at": datetime.now().isoformat(),
                    "allocations": {
                        "aave_wbtc_pool": float(pred[0]), 
                        "uniswap_lp": float(pred[1])
                    },
                    "safety_bounds": {
                        "price_lower": current_price * (1-pred[2]), 
                        "price_upper": current_price * (1+pred[2]), 
                        "vol_threshold": float(pred[3])
                    },
                    "model_confidence": max(0.5, 1.0 - best_loss * 10) if best_loss != float('inf') else 0.5,
                    "strategy_type": "multi_factor_continuous",
                    "market_conditions": {
                        "recent_volatility": float(recent_volatility),
                        "recent_volume_trend": float(recent_volume_trend),
                        "recent_price_trend": float(recent_price_trend)
                    }
                }
                
                sanitized_symbol = pool_symbol.replace('/','-')
                output_path = f'models/strategy_output_{sanitized_symbol}.json'
                with open(output_path, 'w') as f:
                    json.dump(strategy, f, indent=2)
                logger.info(f"  Strategy saved to {output_path}")
                logger.info(f"  -> AAVE: {pred[0]:.2%}, LP: {pred[1]:.2%}, Price Bound: ±{pred[2]:.2%}, Vol Threshold: {pred[3]:.4f}")
                logger.info(f"  -> Model Confidence: {strategy['model_confidence']:.2%}, Best Val Loss: {best_loss:.6f}")

                torch.save({
                    'model_state_dict': model.state_dict(),
                    'scaler': scaler
                }, f'models/model_package_{sanitized_symbol}.pth')
                logger.info(f"  Model package saved to models/model_package_{sanitized_symbol}.pth")

    except Exception as e:
        logger.error(f"An error occurred in the main pipeline: {e}", exc_info=True)
    finally:
        print("\n" + "="*70)
        print("Training program finished.")
        print("="*70 + "\n")

if __name__ == "__main__":
    main()