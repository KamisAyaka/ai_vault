#!/usr/bin/env python3
"""
AI Vault Backend - AI Strategy Example
This example shows how an AI agent can interact with the backend API to manage vault allocations
"""

import requests
import json
import time
from typing import Dict, List, Any

class AIVaultClient:
    """Client for interacting with AI Vault Backend API"""

    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({"Content-Type": "application/json"})

    def health_check(self) -> Dict[str, Any]:
        """Check if the API is healthy"""
        response = self.session.get(f"{self.base_url}/health")
        response.raise_for_status()
        return response.json()

    # ========== Vault Allocation Management ==========

    def update_allocations(self, token_address: str, allocations: List[Dict]) -> Dict[str, Any]:
        """
        Update vault allocations

        Args:
            token_address: Vault asset token address (e.g., WETH, USDC)
            allocations: List of allocation objects with adapter_index and percentage

        Example:
            allocations = [
                {"adapter_index": 0, "percentage": 5000},  # 50% to Aave
                {"adapter_index": 1, "percentage": 5000}   # 50% to UniswapV2
            ]
        """
        data = {
            "token_address": token_address,
            "allocations": allocations
        }
        response = self.session.post(f"{self.base_url}/api/v1/allocations", json=data)
        response.raise_for_status()
        return response.json()

    def withdraw_all_investments(self, token_address: str) -> Dict[str, Any]:
        """
        Withdraw all investments from a vault

        Args:
            token_address: Vault asset token address
        """
        data = {"token_address": token_address}
        response = self.session.post(f"{self.base_url}/api/v1/withdraw", json=data)
        response.raise_for_status()
        return response.json()

    # ========== Adapter Configuration ==========

    def configure_aave_adapter(self, adapter_index: int, token_address: str, vault_address: str) -> Dict[str, Any]:
        """Configure Aave adapter for a specific token"""
        data = {
            "adapter_index": adapter_index,
            "token_address": token_address,
            "vault_address": vault_address
        }
        response = self.session.post(f"{self.base_url}/api/v1/adapters/aave/configure", json=data)
        response.raise_for_status()
        return response.json()

    def configure_uniswapv2_adapter(self, adapter_index: int, token_address: str,
                                    slippage_tolerance: int, counter_party_token: str,
                                    vault_address: str) -> Dict[str, Any]:
        """Configure UniswapV2 adapter for a specific token"""
        data = {
            "adapter_index": adapter_index,
            "token_address": token_address,
            "slippage_tolerance": slippage_tolerance,
            "counter_party_token": counter_party_token,
            "vault_address": vault_address
        }
        response = self.session.post(f"{self.base_url}/api/v1/adapters/uniswapv2/configure", json=data)
        response.raise_for_status()
        return response.json()

    def update_uniswapv2_slippage(self, adapter_index: int, token_address: str, slippage_tolerance: int) -> Dict[str, Any]:
        """Update UniswapV2 slippage tolerance"""
        data = {
            "adapter_index": adapter_index,
            "token_address": token_address,
            "slippage_tolerance": slippage_tolerance
        }
        response = self.session.post(f"{self.base_url}/api/v1/adapters/uniswapv2/slippage", json=data)
        response.raise_for_status()
        return response.json()

    def update_uniswapv2_config(self, adapter_index: int, token_address: str, counter_party_token: str) -> Dict[str, Any]:
        """Update UniswapV2 trading pair and reinvest"""
        data = {
            "adapter_index": adapter_index,
            "token_address": token_address,
            "counter_party_token": counter_party_token
        }
        response = self.session.post(f"{self.base_url}/api/v1/adapters/uniswapv2/update", json=data)
        response.raise_for_status()
        return response.json()

    def configure_uniswapv3_adapter(self, adapter_index: int, token_address: str,
                                    counter_party_token: str, slippage_tolerance: int,
                                    fee_tier: int, tick_lower: int, tick_upper: int,
                                    vault_address: str) -> Dict[str, Any]:
        """Configure UniswapV3 adapter for a specific token"""
        data = {
            "adapter_index": adapter_index,
            "token_address": token_address,
            "counter_party_token": counter_party_token,
            "slippage_tolerance": slippage_tolerance,
            "fee_tier": fee_tier,
            "tick_lower": tick_lower,
            "tick_upper": tick_upper,
            "vault_address": vault_address
        }
        response = self.session.post(f"{self.base_url}/api/v1/adapters/uniswapv3/configure", json=data)
        response.raise_for_status()
        return response.json()

    def update_uniswapv3_slippage(self, adapter_index: int, token_address: str, slippage_tolerance: int) -> Dict[str, Any]:
        """Update UniswapV3 slippage tolerance"""
        data = {
            "adapter_index": adapter_index,
            "token_address": token_address,
            "slippage_tolerance": slippage_tolerance
        }
        response = self.session.post(f"{self.base_url}/api/v1/adapters/uniswapv3/slippage", json=data)
        response.raise_for_status()
        return response.json()

    def update_uniswapv3_config(self, adapter_index: int, token_address: str,
                                counter_party_token: str, fee_tier: int,
                                tick_lower: int, tick_upper: int) -> Dict[str, Any]:
        """Update UniswapV3 position config and reinvest"""
        data = {
            "adapter_index": adapter_index,
            "token_address": token_address,
            "counter_party_token": counter_party_token,
            "fee_tier": fee_tier,
            "tick_lower": tick_lower,
            "tick_upper": tick_upper
        }
        response = self.session.post(f"{self.base_url}/api/v1/adapters/uniswapv3/update", json=data)
        response.raise_for_status()
        return response.json()


def ai_generate_strategy(market_conditions: Dict[str, Any]) -> Dict[str, Any]:
    """
    AI function to generate investment strategy based on market conditions
    This is a simplified example - in reality, this would use ML models

    Returns allocation percentages for different DeFi protocols:
    - Adapter 0: Aave (lending)
    - Adapter 1: UniswapV2 (AMM liquidity)
    - Adapter 2: UniswapV3 (concentrated liquidity)
    """
    print(f"🤖 AI analyzing market conditions: {json.dumps(market_conditions, indent=2)}")

    # Simulate AI analysis based on market conditions
    volatility = market_conditions.get("volatility", "medium")
    trend = market_conditions.get("trend", "neutral")
    liquidity = market_conditions.get("liquidity", "good")

    if volatility == "high":
        # High volatility: Conservative allocation, prefer stable Aave
        allocations = [
            {"adapter_index": 0, "percentage": 7000},  # 70% Aave (safe lending)
            {"adapter_index": 1, "percentage": 2000},  # 20% UniswapV2 (moderate)
            {"adapter_index": 2, "percentage": 1000},  # 10% UniswapV3 (risky)
        ]
        strategy_name = "AI Conservative Strategy"
        description = "Conservative allocation for high volatility market"

    elif trend == "bullish" and liquidity == "good":
        # Bullish + Good liquidity: Aggressive allocation, prefer DEX
        allocations = [
            {"adapter_index": 0, "percentage": 3000},  # 30% Aave
            {"adapter_index": 1, "percentage": 4000},  # 40% UniswapV2
            {"adapter_index": 2, "percentage": 3000},  # 30% UniswapV3
        ]
        strategy_name = "AI Bullish Strategy"
        description = "Aggressive allocation for bullish market with good liquidity"

    elif volatility == "low" and liquidity == "excellent":
        # Low volatility + Excellent liquidity: Maximize yield with UniswapV3
        allocations = [
            {"adapter_index": 0, "percentage": 2000},  # 20% Aave
            {"adapter_index": 1, "percentage": 3000},  # 30% UniswapV2
            {"adapter_index": 2, "percentage": 5000},  # 50% UniswapV3 (concentrated liquidity)
        ]
        strategy_name = "AI Yield Maximizer Strategy"
        description = "Maximize yield with concentrated liquidity in stable market"

    else:
        # Neutral market: Balanced allocation
        allocations = [
            {"adapter_index": 0, "percentage": 5000},  # 50% Aave
            {"adapter_index": 1, "percentage": 3000},  # 30% UniswapV2
            {"adapter_index": 2, "percentage": 2000},  # 20% UniswapV3
        ]
        strategy_name = "AI Balanced Strategy"
        description = "Balanced allocation for neutral market conditions"

    strategy = {
        "name": strategy_name,
        "description": description,
        "allocations": allocations,
        "market_analysis": market_conditions
    }

    print(f"\n🎯 AI generated strategy: {strategy_name}")
    print(f"   Aave: {allocations[0]['percentage']/100}%")
    print(f"   UniswapV2: {allocations[1]['percentage']/100}%")
    print(f"   UniswapV3: {allocations[2]['percentage']/100}%")

    return strategy


def main():
    """Main example function demonstrating AI-driven vault management"""
    print("🚀 AI Vault Backend - AI Strategy Example")
    print("=" * 60)

    # Configuration (update these with your actual deployed addresses)
    USDC_ADDRESS = "0x700b6A60ce7EaaEA56F065753d8dcB9653dbAD35"
    WETH_ADDRESS = "0xb19b36b1456E65E3A6D514D3F715f204BD59f431"

    # Initialize client
    client = AIVaultClient()

    try:
        # 1. Check API health
        print("\n🏥 Step 1: Checking API health...")
        health = client.health_check()
        print(f"✅ API is healthy: {health['status']}")
        print(f"   Timestamp: {health['timestamp']}")
        print(f"   Version: {health['version']}")

        # 2. Simulate market analysis (this would come from real market data)
        print("\n📊 Step 2: Analyzing market conditions...")
        market_conditions = {
            "volatility": "medium",      # Options: low, medium, high
            "trend": "bullish",          # Options: bearish, neutral, bullish
            "liquidity": "good",         # Options: poor, good, excellent
            "risk_level": "medium",      # Options: low, medium, high
            "gas_price": "normal",       # Options: low, normal, high
            "tvl_trend": "increasing"    # Options: decreasing, stable, increasing
        }
        print(f"   Volatility: {market_conditions['volatility']}")
        print(f"   Trend: {market_conditions['trend']}")
        print(f"   Liquidity: {market_conditions['liquidity']}")

        # 3. Generate AI strategy
        print("\n🤖 Step 3: AI generating optimal allocation strategy...")
        strategy_data = ai_generate_strategy(market_conditions)

        # 4. Execute strategy by updating vault allocations
        print(f"\n⚡ Step 4: Executing strategy on USDC vault...")
        print(f"   Token: {USDC_ADDRESS}")

        allocation_result = client.update_allocations(
            token_address=USDC_ADDRESS,
            allocations=strategy_data["allocations"]
        )

        print(f"✅ Strategy executed successfully!")
        print(f"   Transaction Hash: {allocation_result['result']['tx_hash']}")
        print(f"   Status: {allocation_result['result']['status']}")
        print(f"   Message: {allocation_result['message']}")

        # 5. Optional: Demonstrate adapter configuration
        print("\n🔧 Step 5: Example adapter configuration (commented out)...")
        print("   # Configure Aave adapter:")
        print(f"   # client.configure_aave_adapter(0, '{USDC_ADDRESS}', '<vault_address>')")
        print("   # Configure UniswapV2 adapter:")
        print(f"   # client.configure_uniswapv2_adapter(1, '{USDC_ADDRESS}', 500, '{WETH_ADDRESS}', '<vault_address>')")

        # 6. Wait and check transaction (in real scenario, query subgraph)
        print("\n⏳ Step 6: Waiting for transaction confirmation...")
        print("   In production, you would:")
        print("   1. Query The Graph subgraph for updated allocations")
        print("   2. Monitor transaction status on-chain")
        print("   3. Verify vault state changes")

        print("\n" + "=" * 60)
        print("🎉 AI Strategy Example completed successfully!")
        print("=" * 60)
        print("\n💡 Next Steps:")
        print("   1. Query subgraph to verify allocation updates")
        print("   2. Monitor vault performance metrics")
        print("   3. Run AI analysis again when market conditions change")
        print("   4. Adjust allocations dynamically based on performance")

    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend API. Is the server running?")
        print("   Start backend: cd packages/go-backend && go run main.go")
    except requests.exceptions.RequestException as e:
        print(f"❌ API request failed: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"   Response: {e.response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
