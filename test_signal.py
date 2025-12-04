"""
Test Script for Sending Manual Trading Signals
Usage: python test_signal.py
"""
import requests
import json

# Backend URL
BASE_URL = "https://ansorade-backend.onrender.com"

def send_manual_signal(symbol, action, volume, sl, tp):
    """Send a manual trading signal"""
    url = f"{BASE_URL}/api/signals/manual"
    
    payload = {
        "symbol": symbol,
        "action": action.upper(),
        "volume": volume,
        "sl": sl,
        "tp": tp,
        "timeframe": "M15"
    }
    
    print(f"\n{'='*60}")
    print(f"Sending Signal to: {url}")
    print(f"{'='*60}")
    print(json.dumps(payload, indent=2))
    print(f"{'='*60}\n")
    
    try:
        response = requests.post(url, json=payload, timeout=10)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response:")
        print(json.dumps(response.json(), indent=2))
        
        if response.status_code == 200:
            print("\n✅ Signal sent successfully!")
        else:
            print("\n❌ Failed to send signal")
            
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")

def get_pending_signals():
    """Get pending signals from backend"""
    url = f"{BASE_URL}/api/signals/pending"
    headers = {"X-API-Key": "Mr.creative090"}
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        print(f"\n{'='*60}")
        print("Pending Signals:")
        print(f"{'='*60}")
        print(json.dumps(response.json(), indent=2))
    except Exception as e:
        print(f"❌ Error fetching signals: {str(e)}")

def check_health():
    """Check if backend is running"""
    url = f"{BASE_URL}/health"
    
    try:
        response = requests.get(url, timeout=10)
        print(f"\n{'='*60}")
        print("Backend Health Check:")
        print(f"{'='*60}")
        print(json.dumps(response.json(), indent=2))
        print(f"{'='*60}\n")
        return True
    except Exception as e:
        print(f"❌ Backend not reachable: {str(e)}")
        return False

if __name__ == "__main__":
    print("\n" + "="*60)
    print("ANSORADE TRADING BACKEND - SIGNAL TESTER")
    print("="*60)
    
    # Check backend health
    if not check_health():
        print("\n⚠️ Backend is not running. Please start it first.")
        exit(1)
    
    # Test signals
    print("\n📊 Test 1: XAUUSD SELL Signal")
    send_manual_signal(
        symbol="XAUUSD",
        action="SELL",
        volume=0.01,
        sl=2702.92,
        tp=2690.53
    )
    
    print("\n\n📊 Test 2: EURUSD BUY Signal")
    send_manual_signal(
        symbol="EURUSD",
        action="BUY",
        volume=0.01,
        sl=1.0850,
        tp=1.0900
    )
    
    # Get pending signals
    print("\n\n📋 Fetching Pending Signals...")
    get_pending_signals()
    
    print("\n" + "="*60)
    print("Testing Complete!")
    print("="*60)
    print("\nNext steps:")
    print("1. Check your Supabase database 'signals' table")
    print("2. View signals in frontend: https://your-frontend.vercel.app")
    print("3. If MT5 EA is running, it will execute these trades")
    print("4. If not, they remain as paper trades in the database")
    print("="*60 + "\n")
