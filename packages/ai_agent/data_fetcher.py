# 主要爬取三份数据：Uniswap V3 流动性池历史数据、Aave V3 借贷市场当前数据、Base链当前Gas费用数据

import requests
import json
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import time
from typing import Dict, List, Optional
import logging
import os
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class MultiPoolDeFiDataFetcher:
    
    def __init__(self, pools_config: Dict, api_key: str = None):
        self.pools_config = pools_config
        self.api_key = api_key
        
        self.subgraph_urls = {
            "uniswap_v3_base": "https://gateway.thegraph.com/api/subgraphs/id/HMuAwufqZ1YCRmzL2SfHTVkzZovC9VL2UAKhjvRqKiR1",
            "aave_v3_base": "https://gateway.thegraph.com/api/subgraphs/id/GQFbb95cE6d8mV989mL5figjaGaKCQB3xqYrr1bRyXqF"
        }
        
        self.headers = {"Content-Type": "application/json"}
        if self.api_key:
            self.headers["Authorization"] = f"Bearer {self.api_key}"
    
    def execute_query(self, url: str, query: str, variables: Dict = None) -> Dict:
        payload = {"query": query, "variables": variables or {}}
        try:
            response = requests.post(url, json=payload, headers=self.headers, timeout=60)
            response.raise_for_status()
            data = response.json()
            if "errors" in data:
                logger.error(f"GraphQL query returned errors: {data['errors']}")
                return {}
            return data.get("data", {})
        except Exception as e:
            logger.error(f"Failed to execute query on {url}: {e}")
            return {}

    def get_pool_snapshots_paginated(self, pool_address: str, start_timestamp: int) -> List[Dict]:
        logger.info(f"Fetching snapshots for pool {pool_address} since timestamp {start_timestamp}...")
        all_snapshots = []
        last_timestamp = start_timestamp
        
        query = """
        query GetPoolHourlySnapshots($poolAddress: String!, $startTime: Int!, $first: Int!) {
            poolHourDatas(
                where: { pool: $poolAddress, periodStartUnix_gte: $startTime },
                orderBy: periodStartUnix, orderDirection: asc, first: $first
            ) {
                id periodStartUnix liquidity sqrtPrice token0Price token1Price
                volumeUSD volumeToken0 volumeToken1 txCount open high low close tvlUSD
            }
        }
        """
        while True:
            variables = {"poolAddress": pool_address.lower(), "startTime": last_timestamp, "first": 1000}
            result = self.execute_query(self.subgraph_urls["uniswap_v3_base"], query, variables)
            snapshots = result.get("poolHourDatas", [])
            
            if not snapshots:
                break
                
            all_snapshots.extend(snapshots)
            new_last_timestamp = int(snapshots[-1]['periodStartUnix'])
            
            if new_last_timestamp == last_timestamp:
                break

            last_timestamp = new_last_timestamp + 1
            logger.info(f"  Fetched {len(snapshots)} snapshots, now at timestamp {last_timestamp}")
            time.sleep(0.5)

        unique_snapshots = list({item['id']: item for item in all_snapshots}.values())
        logger.info(f"  Total unique snapshots fetched: {len(unique_snapshots)}")
        return unique_snapshots

    def get_aave_reserves_data(self, asset_addresses: List[str]) -> List[Dict]:
        query = """
        query GetReserveData($assetIds: [String!]) {
            reserves(where: {underlyingAsset_in: $assetIds}) {
                id underlyingAsset name symbol decimals liquidityRate variableBorrowRate
                totalATokenSupply totalCurrentVariableDebt utilizationRate lastUpdateTimestamp
            }
        }
        """
        variables = {"assetIds": [addr.lower() for addr in asset_addresses]}
        result = self.execute_query(self.subgraph_urls["aave_v3_base"], query, variables)
        return result.get("reserves", [])
    
    def get_base_gas_data(self) -> Dict:
        try:
            response = requests.post("https://mainnet.base.org", json={
                "jsonrpc": "2.0", "method": "eth_getBlockByNumber",
                "params": ["latest", False], "id": 1
            }, timeout=10)
            if response.status_code == 200:
                block = response.json().get('result', {})
                base_fee = int(block.get('baseFeePerGas', '0x0'), 16) / 1e9
                return {'base_fee_gwei': base_fee, 'block_number': int(block.get('number', '0x0'), 16)}
        except Exception as e:
            logger.error(f"Could not fetch gas data: {e}")
        return {'base_fee_gwei': 0.001, 'block_number': 0}

    def run_full_data_collection(self, weeks: int = 12) -> Dict:
        logger.info(f"Starting full data collection for {weeks} weeks...")
        end_timestamp = datetime.now()
        start_timestamp = int((end_timestamp - timedelta(weeks=weeks)).timestamp())
        
        all_data = {
            'collection_info': {
                'timestamp': end_timestamp.isoformat(),
                'period_weeks': weeks
            },
            'pools': {}
        }

        gas_data = self.get_base_gas_data() # Fetch gas data once

        for pool_symbol, config in self.pools_config.items():
            logger.info(f"\n{'='*20} Processing Pool: {pool_symbol} {'='*20}")
            pool_address = config['address']
            
            snapshots = self.get_pool_snapshots_paginated(pool_address, start_timestamp)
            if not snapshots:
                logger.warning(f"No snapshots found for pool {pool_symbol}. Skipping.")
                continue

            aave_assets = config.get('aave_assets', [])
            aave_data = self.get_aave_reserves_data(aave_assets) if aave_assets else []

            all_data['pools'][pool_symbol] = {
                'address': pool_address,
                'snapshots': snapshots,
                'aave_current_reserves': aave_data,
                'gas_current': gas_data
            }

        os.makedirs('data', exist_ok=True)
        file_path = 'data/complete_defi_data.json'
        with open(file_path, 'w') as f:
            json.dump(all_data, f, indent=2)
        logger.info(f"\nAll data collection finished. Master file saved to {file_path}")

        return all_data

def main():
    load_dotenv()
    API_KEY = os.getenv("THE_GRAPH_API_KEY")
    if not API_KEY:
        logger.warning("THE_GRAPH_API_KEY not found. Using public endpoints (rate limits may apply).")

    POOLS_TO_FETCH = {
        # 可根据需要增加池子
        # "USDC-cbBTC": {
        #     "address": "0xfbb6eed8e7aa03b138556eedaf5d271a5e1e43ef",
        #     "aave_assets": [
        #         '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' 
        #     ]
        # }
        "wBTC-USDC": {
            "address": "0xfBB6Eed8e7aa03B138556eeDaF5D271A5E1e43ef", # Uniswap V3 cbBTC(wBTC)-USDC Pool
            "aave_assets": [
                '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf' # cbBTC on Base
            ]
        }
    }
    
    # 以过去12个月的数据为训练数据
    WEEKS_OF_DATA = 52  

    fetcher = MultiPoolDeFiDataFetcher(pools_config=POOLS_TO_FETCH, api_key=API_KEY)
    fetcher.run_full_data_collection(weeks=WEEKS_OF_DATA)

if __name__ == "__main__":
    main()