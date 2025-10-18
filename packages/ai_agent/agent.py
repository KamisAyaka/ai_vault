import requests
import json
import time
import os
import logging
from dotenv import load_dotenv
from datetime import datetime, timedelta
from predict import get_latest_strategy
from database import DatabaseManager
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- 配置常量 (适配器索引) ---
ADAPTER_MAP = {
    "aave": 0,
    "uniswap_v2": 1,
    "uniswap_v3": 2,
}

# AI模型输出与适配器索引的映射
ADAPTER_NAME_TO_AI_KEY = {
    "aave": "aave_wbtc_pool",
    "uniswap_v3": "uniswap_v3_lp",
}


def transform_strategy_for_backend(strategy: dict, token_address: str) -> dict:
    """将AI生成的策略JSON转换为Go后端API需要的格式"""
    allocations_list = []
    ai_allocations = strategy['allocations']
    
    for adapter_name, adapter_index in ADAPTER_MAP.items():
        # 从AI的输出中查找对应的策略键
        ai_strategy_key = ADAPTER_NAME_TO_AI_KEY.get(adapter_name)

        percentage_float = 0.0
        # 如果找到了对应的AI策略键，并且AI的分配结果中确实有这个键
        if ai_strategy_key and ai_strategy_key in ai_allocations:
            percentage_float = ai_allocations[ai_strategy_key]
        
        # 将百分比从 0.0-1.0 转换为 0-1000 的整数（基点）
        percentage_basis_points = int(percentage_float * 1000)
        
        allocations_list.append({
            "adapter_index": adapter_index,
            "percentage": percentage_basis_points
        })

    # 确保总和为 1000
    total_percentage = sum(item['percentage'] for item in allocations_list)
    if total_percentage != 1000:
        # 简单的归一化处理
        logging.warning(f"Percentages sum to {total_percentage}, normalizing to 10000.")
        if allocations_list:
            item_to_adjust = next((item for item in allocations_list if item['percentage'] > 0), allocations_list[-1])
            item_to_adjust['percentage'] += (1000 - total_percentage)

    allocations_list.sort(key=lambda x: x['adapter_index'])

    return {
        "token_address": token_address,
        "allocations": allocations_list
    }


def main_loop():
    """Agent的主循环"""
    load_dotenv()
    BACKEND_URL = os.getenv("BACKEND_API_URL")
    TOKEN_ADDRESS = os.getenv("TOKEN_ADDRESS")
    THE_GRAPH_API_KEY = os.getenv("THE_GRAPH_API_KEY")

    db = DatabaseManager()
    logger.info("✅ Database manager initialized")

    # 这是模型和数据获取相关的配置
    POOL_SYMBOL = "wBTC-USDC"
    POOL_CONFIG = {
        # wBTC-USDC Pool on Base Uniswap V3
        "address": "0xfbb6eed8e7aa03b138556eedaf5d271a5e1e43ef",
        # wBTC on Base for Aave V3
        "aave_assets": ['0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf'] 
    }
    
    while True:
        try:
            logging.info("="*50)
            logging.info("Starting new strategy evaluation cycle...")

            # 1. AI生成新的策略
            logging.info("Step 1: Generating new strategy from AI model...")
            ai_strategy = get_latest_strategy(POOL_SYMBOL, POOL_CONFIG, api_key=THE_GRAPH_API_KEY)
            logging.info(f"AI Recommended Allocations: Aave WBTC={ai_strategy['allocations']['aave_wbtc_pool']:.2%}, UniV3 LP={ai_strategy['allocations']['uniswap_v3_lp']:.2%}")

            # 2. 将策略转换为后端需要的格式
            logging.info("Step 2: Transforming strategy for backend API...")
            backend_payload = transform_strategy_for_backend(ai_strategy, TOKEN_ADDRESS)
            logging.info(f"Payload to be sent: {json.dumps(backend_payload, indent=2)}")
            
            # 3. 通过Go后端执行策略
            logging.info("Step 3: Sending transaction request to Go backend...")
            api_endpoint = f"{BACKEND_URL}/api/v1/allocations"
            response = requests.post(api_endpoint, json=backend_payload, timeout=30)
            
            response.raise_for_status() # 如果HTTP状态码是4xx或5xx，则会抛出异常
            
            response_data = response.json()
            tx_hash = response_data.get("result", {}).get("tx_hash")
            logging.info(f"✅ Strategy update successfully sent! Transaction Hash: {tx_hash}")

            if tx_hash:
                try:
                    execution_record = {
                        'pool_symbol': POOL_SYMBOL,
                        'timestamp': datetime.now().isoformat(),
                        'aave_wbtc_pool': ai_strategy['allocations']['aave_wbtc_pool'],
                        'uniswap_v3_lp': ai_strategy['allocations']['uniswap_v3_lp'],
                        'tx_hash': tx_hash,
                        'model_confidence': ai_strategy.get('model_confidence'),
                        'safety_bounds': ai_strategy.get('safety_bounds'),
                        'additional_info': {
                            'backend_response': response_data,
                            'prediction_generated_at': ai_strategy.get('prediction_generated_at')
                        }
                    }
                    
                    db.insert_strategy_execution(execution_record)
                    logging.info("📝 Strategy execution logged to database")
                    
                except Exception as log_error:
                    logging.error(f"⚠️  Failed to log to database: {log_error}")
                
        except requests.exceptions.RequestException as e:
            logging.error(f"🚨 Failed to communicate with Go backend: {e}")
        except Exception as e:
            logging.error(f"🚨 An unexpected error occurred in the agent loop: {e}", exc_info=True)

        # 等待下一个周期
        sleep_duration_seconds = 60  # 休眠60秒，即1分钟
        logging.info(f"Cycle finished. Sleeping for {sleep_duration_seconds} seconds...")
        logging.info("="*50 + "\n")
        time.sleep(sleep_duration_seconds)
        # sleep_duration_hours = 1
        # logging.info(f"Cycle finished. Sleeping for {sleep_duration_hours} hour(s)...")
        # logging.info("="*50 + "\n")
        # time.sleep(sleep_duration_hours * 3600)


if __name__ == "__main__":
    main_loop()