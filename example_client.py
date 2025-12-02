import requests
import json
from datetime import datetime

# Configuration
API_URL = "http://localhost:8000"  # Change to your Render URL in production
API_KEY = "your_api_key_here"

def send_signal(symbol: str, action: str, volume: float, sl: float = None, tp: float = None):
    """
    Send a trading signal to the MT5 community platform
    
    Args:
        symbol: Trading pair (e.g., "EURUSD")
        action: "BUY" or "SELL"
        volume: Lot size (e.g., 0.01)
        sl: Stop loss price (optional)
        tp: Take profit price (optional)
    """
    endpoint = f"{API_URL}/api/signal"
    
    headers = {
        "Content-Type": "application/json",
        "X-API-Key": API_KEY
    }
    
    payload = {
        "symbol": symbol,
        "action": action,
        "volume": volume,
        "sl": sl,
        "tp": tp,
        "signal_id": f"{symbol}_{action}_{datetime.now().timestamp()}"
    }
    
    try:
        response = requests.post(endpoint, headers=headers, json=payload)
        response.raise_for_status()
        
        result = response.json()
        print(f"✅ Signal sent successfully: {result}")
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error sending signal: {e}")
        return None

def get_account_stats():
    """Get current account statistics"""
    endpoint = f"{API_URL}/api/account/stats"
    
    try:
        response = requests.get(endpoint)
        response.raise_for_status()
        
        stats = response.json()
        print(f"📊 Account Stats:")
        print(json.dumps(stats, indent=2))
        return stats
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error getting stats: {e}")
        return None

def create_user(user_id: str, email: str, initial_investment: float = 0):
    """Create a new user"""
    endpoint = f"{API_URL}/api/users"
    
    payload = {
        "user_id": user_id,
        "email": email,
        "investment": initial_investment
    }
    
    try:
        response = requests.post(endpoint, json=payload)
        response.raise_for_status()
        
        result = response.json()
        print(f"✅ User created: {result}")
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error creating user: {e}")
        return None

def add_investment(user_id: str, amount: float):
    """Add investment for a user"""
    endpoint = f"{API_URL}/api/users/{user_id}/invest"
    
    payload = {
        "user_id": user_id,
        "amount": amount
    }
    
    try:
        response = requests.post(endpoint, json=payload)
        response.raise_for_status()
        
        result = response.json()
        print(f"✅ Investment added: {result}")
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error adding investment: {e}")
        return None

def get_user_stats(user_id: str):
    """Get user statistics"""
    endpoint = f"{API_URL}/api/users/{user_id}/stats"
    
    try:
        response = requests.get(endpoint)
        response.raise_for_status()
        
        stats = response.json()
        print(f"👤 User {user_id} Stats:")
        print(json.dumps(stats, indent=2))
        return stats
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error getting user stats: {e}")
        return None


# Example usage
if __name__ == "__main__":
    print("🚀 MT5 Community Trading - Example Client\n")
    
    # Example 1: Send a BUY signal
    print("Example 1: Sending BUY signal for EURUSD")
    send_signal(
        symbol="EURUSD",
        action="BUY",
        volume=0.01,
        sl=1.0800,
        tp=1.0900
    )
    print()
    
    # Example 2: Send a SELL signal
    print("Example 2: Sending SELL signal for GBPUSD")
    send_signal(
        symbol="GBPUSD",
        action="SELL",
        volume=0.01,
        sl=1.2700,
        tp=1.2600
    )
    print()
    
    # Example 3: Create a user
    print("Example 3: Creating a new user")
    create_user(
        user_id="user123",
        email="user123@example.com",
        initial_investment=1000.00
    )
    print()
    
    # Example 4: Add investment
    print("Example 4: Adding investment")
    add_investment("user123", 500.00)
    print()
    
    # Example 5: Get user stats
    print("Example 5: Getting user stats")
    get_user_stats("user123")
    print()
    
    # Example 6: Get account stats
    print("Example 6: Getting account stats")
    get_account_stats()
