#!/usr/bin/env python3
"""
AI Vault Backend - AI Strategy Example
This example shows how an AI agent can interact with the backend API
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
    
    def health_check(self) -> Dict[str, Any]:
        """Check if the API is healthy"""
        response = self.session.get(f"{self.base_url}/health")
        response.raise_for_status()
        return response.json()
    
    def create_strategy(self, name: str, description: str, allocations: List[Dict]) -> Dict[str, Any]:
        """Create a new investment strategy"""
        data = {
            "name": name,
            "description": description,
            "allocations": allocations
        }
        response = self.session.post(f"{self.base_url}/api/v1/strategies", json=data)
        response.raise_for_status()
        return response.json()
    
    def get_strategy(self, strategy_id: str) -> Dict[str, Any]:
        """Get strategy details"""
        response = self.session.get(f"{self.base_url}/api/v1/strategies/{strategy_id}")
        response.raise_for_status()
        return response.json()
    
    def list_strategies(self, limit: int = 10, offset: int = 0) -> Dict[str, Any]:
        """List all strategies"""
        params = {"limit": limit, "offset": offset}
        response = self.session.get(f"{self.base_url}/api/v1/strategies", params=params)
        response.raise_for_status()
        return response.json()
    
    def execute_strategy(self, strategy_id: str, vault_id: str) -> Dict[str, Any]:
        """Execute a strategy on a vault"""
        data = {
            "strategy_id": strategy_id,
            "vault_id": vault_id
        }
        response = self.session.post(f"{self.base_url}/api/v1/strategies/execute", json=data)
        response.raise_for_status()
        return response.json()
    
    def get_execution(self, execution_id: str) -> Dict[str, Any]:
        """Get execution details"""
        response = self.session.get(f"{self.base_url}/api/v1/executions/{execution_id}")
        response.raise_for_status()
        return response.json()
    
    def list_vaults(self, limit: int = 10, offset: int = 0) -> Dict[str, Any]:
        """List all vaults"""
        params = {"limit": limit, "offset": offset}
        response = self.session.get(f"{self.base_url}/api/v1/vaults", params=params)
        response.raise_for_status()
        return response.json()

def ai_generate_strategy(market_conditions: Dict[str, Any]) -> Dict[str, Any]:
    """
    AI function to generate investment strategy based on market conditions
    This is a simplified example - in reality, this would use ML models
    """
    print(f"🤖 AI analyzing market conditions: {market_conditions}")
    
    # Simulate AI analysis
    if market_conditions.get("volatility", "low") == "high":
        # High volatility: More conservative allocation
        strategy = {
            "name": "AI Conservative Strategy",
            "description": "Conservative allocation for high volatility market",
            "allocations": [
                {"adapter_index": 0, "percentage": 800, "protocol": "Aave"},  # 80% Aave
                {"adapter_index": 1, "percentage": 200, "protocol": "UniswapV2"}  # 20% UniswapV2
            ]
        }
    elif market_conditions.get("trend", "neutral") == "bullish":
        # Bullish market: More aggressive allocation
        strategy = {
            "name": "AI Bullish Strategy",
            "description": "Aggressive allocation for bullish market",
            "allocations": [
                {"adapter_index": 0, "percentage": 400, "protocol": "Aave"},  # 40% Aave
                {"adapter_index": 1, "percentage": 600, "protocol": "UniswapV2"}  # 60% UniswapV2
            ]
        }
    else:
        # Neutral market: Balanced allocation
        strategy = {
            "name": "AI Balanced Strategy",
            "description": "Balanced allocation for neutral market",
            "allocations": [
                {"adapter_index": 0, "percentage": 500, "protocol": "Aave"},  # 50% Aave
                {"adapter_index": 1, "percentage": 500, "protocol": "UniswapV2"}  # 50% UniswapV2
            ]
        }
    
    print(f"🎯 AI generated strategy: {strategy['name']}")
    return strategy

def main():
    """Main example function"""
    print("🚀 AI Vault Backend - AI Strategy Example")
    print("=" * 50)
    
    # Initialize client
    client = AIVaultClient()
    
    try:
        # Check API health
        print("🏥 Checking API health...")
        health = client.health_check()
        print(f"✅ API is healthy: {health['status']}")
        
        # Simulate market analysis
        market_conditions = {
            "volatility": "high",
            "trend": "neutral",
            "liquidity": "good",
            "risk_level": "medium"
        }
        
        # Generate AI strategy
        print("\n🤖 AI generating strategy...")
        strategy_data = ai_generate_strategy(market_conditions)
        
        # Create strategy via API
        print("\n📝 Creating strategy via API...")
        strategy_response = client.create_strategy(
            name=strategy_data["name"],
            description=strategy_data["description"],
            allocations=strategy_data["allocations"]
        )
        
        strategy = strategy_response["strategy"]
        strategy_id = strategy["id"]
        print(f"✅ Strategy created with ID: {strategy_id}")
        
        # List all strategies
        print("\n📋 Listing all strategies...")
        strategies = client.list_strategies()
        print(f"Found {len(strategies['strategies'])} strategies")
        
        # Get strategy details
        print(f"\n🔍 Getting strategy details for {strategy_id}...")
        strategy_details = client.get_strategy(strategy_id)
        print(f"Strategy: {strategy_details['strategy']['name']}")
        print(f"Status: {strategy_details['strategy']['status']}")
        print(f"Allocations: {len(strategy_details['strategy']['allocations'])}")
        
        # List vaults (assuming you have vaults set up)
        print("\n🏦 Listing available vaults...")
        vaults = client.list_vaults()
        if vaults["vaults"]:
            vault_id = vaults["vaults"][0]["id"]
            print(f"Found vault: {vault_id}")
            
            # Execute strategy (uncomment when you have a real vault)
            # print(f"\n⚡ Executing strategy on vault {vault_id}...")
            # execution = client.execute_strategy(strategy_id, vault_id)
            # print(f"✅ Strategy execution started: {execution['execution']['id']}")
        else:
            print("⚠️  No vaults found. Please set up vaults first.")
        
        print("\n🎉 Example completed successfully!")
        
    except requests.exceptions.RequestException as e:
        print(f"❌ API request failed: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
