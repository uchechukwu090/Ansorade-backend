#!/usr/bin/env python3
"""
✅ COMPREHENSIVE SIGNAL FLOW VERIFICATION
Tests the complete signal chain from Anso-vision to Ansorade to Supabase to MT5
"""
import requests
import json
import os
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# Configuration
ANSO_VISION_URL = "https://anso-vision-backend.onrender.com"
ANSORADE_URL = "https://ansorade-backend.onrender.com"
API_KEY = "Mr.creative090"
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

print("\n" + "="*80)
print("🔄 SIGNAL FLOW VERIFICATION")
print("="*80)

# Test 1: Check Anso-vision backend health
print("\n1️⃣ CHECKING ANSO-VISION BACKEND...")
try:
    response = requests.get(f"{ANSO_VISION_URL}/health", timeout=5)
    if response.status_code == 200:
        health = response.json()
        print(f"   ✅ Anso-vision is healthy")
        print(f"      Service: {health.get('service')}")
        print(f"      Version: {health.get('version')}")
        print(f"      WebSocket connections: {health.get('websocket_connections')}")
        print(f"      MT5 Backend: {health.get('mt5_backend')}")
    else:
        print(f"   ⚠️ Anso-vision returned: {response.status_code}")
except Exception as e:
    print(f"   ❌ Cannot reach Anso-vision: {e}")

# Test 2: Check Ansorade backend health
print("\n2️⃣ CHECKING ANSORADE BACKEND...")
try:
    response = requests.get(f"{ANSORADE_URL}/health", timeout=5)
    if response.status_code == 200:
        health = response.json()
        print(f"   ✅ Ansorade is healthy")
        print(f"      Status: {health.get('status')}")
        print(f"      Database: {health.get('database')}")
        print(f"      API Key: {'Configured' if health.get('api_key') else 'Missing'}")
    else:
        print(f"   ⚠️ Ansorade returned: {response.status_code}")
except Exception as e:
    print(f"   ❌ Cannot reach Ansorade: {e}")

# Test 3: Send a test signal from Anso-vision format
print("\n3️⃣ TESTING SIGNAL POST TO ANSORADE...")
test_signal = {
    "symbol": "EURUSD",
    "action": "BUY",
    "entry": 1.0950,
    "tp": 1.1050,
    "sl": 1.0900,
    "volume": 0.01,
    "confidence": 0.85,
    "limit_orders": False,
    "reasoning": "Test signal - Verify signal flow",
    "timeframe": "1h"
}

try:
    headers = {
        "X-API-Key": API_KEY,
        "Content-Type": "application/json"
    }
    response = requests.post(
        f"{ANSORADE_URL}/api/signal",
        json=test_signal,
        headers=headers,
        timeout=5
    )
    
    if response.status_code == 200:
        result = response.json()
        signal_id = result.get('signal_id')
        print(f"   ✅ Signal accepted by Ansorade")
        print(f"      Signal ID: {signal_id}")
        print(f"      Status: {result.get('status')}")
        print(f"      Symbol: {result.get('symbol')}")
        print(f"      Action: {result.get('action')}")
        print(f"      Limit Orders: {result.get('limit_orders')}")
    elif response.status_code == 403:
        print(f"   ❌ API Key rejected: {response.text}")
    else:
        print(f"   ❌ Ansorade error ({response.status_code}): {response.text[:100]}")
except Exception as e:
    print(f"   ❌ Cannot POST signal: {e}")

# Test 4: Check if signal was stored in Supabase
print("\n4️⃣ CHECKING SUPABASE SIGNAL STORAGE...")
try:
    from supabase import create_client
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    # Get the most recent signal
    response = supabase.table("signals").select("*").order("created_at", desc=True).limit(1).execute()
    
    if response.data:
        signal = response.data[0]
        print(f"   ✅ Latest signal found in Supabase")
        print(f"      ID: {signal.get('id')}")
        print(f"      Symbol: {signal.get('symbol')}")
        print(f"      Action: {signal.get('action')}")
        print(f"      Entry: {signal.get('entry')}")
        print(f"      TP: {signal.get('tp')}")
        print(f"      SL: {signal.get('sl')}")
        print(f"      Limit Orders: {signal.get('limit_orders')}")
        print(f"      Reasoning: {signal.get('reasoning')[:50] if signal.get('reasoning') else 'N/A'}...")
        print(f"      Status: {signal.get('status')}")
        print(f"      Created: {signal.get('created_at')}")
    else:
        print(f"   ⚠️ No signals found in Supabase")
except Exception as e:
    print(f"   ❌ Cannot access Supabase: {e}")

# Test 5: Check pending signals (for MT5 EA)
print("\n5️⃣ CHECKING PENDING SIGNALS FOR MT5 EA...")
try:
    headers = {"X-API-Key": API_KEY}
    response = requests.get(
        f"{ANSORADE_URL}/api/signals/pending",
        headers=headers,
        timeout=5
    )
    
    if response.status_code == 200:
        pending_signals = response.json()
        print(f"   ✅ Fetched pending signals")
        print(f"      Count: {len(pending_signals)}")
        if pending_signals:
            for signal in pending_signals[:3]:  # Show first 3
                print(f"      - {signal.get('symbol')} {signal.get('action')} (ID: {signal.get('id')})")
    else:
        print(f"   ⚠️ Cannot fetch pending signals: {response.status_code}")
except Exception as e:
    print(f"   ❌ Cannot fetch pending signals: {e}")

# Test 6: Test manual signal endpoint
print("\n6️⃣ TESTING MANUAL SIGNAL ENDPOINT...")
manual_signal = {
    "symbol": "GBPUSD",
    "action": "SELL",
    "entry": 1.2750,
    "tp": 1.2650,
    "sl": 1.2850,
    "volume": 0.02,
    "confidence": 0.75,
    "timeframe": "4h",
    "reasoning": "Manual test signal"
}

try:
    response = requests.post(
        f"{ANSORADE_URL}/api/signals/manual",
        json=manual_signal,
        timeout=5
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f"   ✅ Manual signal created")
        print(f"      Signal ID: {result.get('signal_id')}")
        print(f"      Status: {result.get('message')}")
    else:
        print(f"   ❌ Manual signal failed: {response.text[:100]}")
except Exception as e:
    print(f"   ❌ Cannot create manual signal: {e}")

# Summary
print("\n" + "="*80)
print("✅ SIGNAL FLOW VERIFICATION COMPLETE")
print("="*80)
print(f"\nTimestamp: {datetime.now().isoformat()}")
print("\n📋 Next Steps:")
print("  1. If all tests pass: Signal flow is working correctly")
print("  2. Check Ansorade logs to verify signal reception")
print("  3. Verify MT5 EA is polling /api/signals/pending")
print("  4. Monitor signal execution in Supabase trades table")
print()
