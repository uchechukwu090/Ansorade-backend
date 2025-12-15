from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import os
from decimal import Decimal
import httpx
import asyncio
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="MT5 Community Trading API")

# CORS - Read from environment for security
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
API_SECRET_KEY = os.getenv("API_SECRET_KEY", "Mr.creative090")

# ✅ Fix: Skip API key check for OPTIONS requests (CORS preflight)
async def verify_api_key(request: Request, x_api_key: str = Header(None)):
    if request.method == "OPTIONS":
        return None  # allow preflight through without API key
    if x_api_key != API_SECRET_KEY:
        raise HTTPException(status_code=403, detail="Invalid API key")
    return x_api_key

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
API_SECRET_KEY = os.getenv("API_SECRET_KEY", "Mr.creative090")

# Account Configuration
ACCOUNT_MODE = os.getenv("ACCOUNT_MODE", "demo")  # "demo" or "real"
DEMO_ACCOUNT = os.getenv("DEMO_ACCOUNT", "")
DEMO_PASSWORD = os.getenv("DEMO_PASSWORD", "")
DEMO_SERVER = os.getenv("DEMO_SERVER", "FBS-Demo")
REAL_ACCOUNT = os.getenv("REAL_ACCOUNT", "")
REAL_PASSWORD = os.getenv("REAL_PASSWORD", "")
REAL_SERVER = os.getenv("REAL_SERVER", "FBS-Real")

print(f"🔧 Account Mode: {ACCOUNT_MODE.upper()}")
print(f"   Demo Account: {DEMO_ACCOUNT if DEMO_ACCOUNT else 'Not configured'}")
print(f"   Real Account: {REAL_ACCOUNT if REAL_ACCOUNT else 'Not configured'}")
print(f"   CORS Origins: {ALLOWED_ORIGINS}")

# Signal Generator Integration
SIGNAL_GENERATOR_URL = os.getenv("SIGNAL_GENERATOR_URL", "https://anso-vision-backend.onrender.com")
TRADING_BACKEND_URL = os.getenv("TRADING_BACKEND_URL", "http://localhost:8000")

# Initialize Supabase client
supabase_client = None

def get_supabase_client():
    global supabase_client
    if supabase_client is None:
        from supabase import create_client
        supabase_client = create_client(SUPABASE_URL, SUPABASE_KEY)
    return supabase_client

# Models
class Signal(BaseModel):
    symbol: str
    action: str  # BUY or SELL
    volume: float
    sl: Optional[float] = None
    tp: Optional[float] = None
    signal_id: Optional[str] = None
    confidence: Optional[float] = None
    timeframe: Optional[str] = None

class AccountUpdate(BaseModel):
    balance: float
    equity: float
    margin: float
    free_margin: float
    profit: float

class TradeConfirmation(BaseModel):
    ticket: int
    action: str
    symbol: str
    volume: float
    price: float

class UserInvestment(BaseModel):
    user_id: str
    amount: float

class User(BaseModel):
    user_id: str
    email: str
    investment: float = 0.0

# API Key verification
async def verify_api_key(x_api_key: str = Header(None)):
    if x_api_key != API_SECRET_KEY:
        raise HTTPException(status_code=403, detail="Invalid API key")
    return x_api_key

# Signal Generator Integration Functions
async def fetch_signal_from_generator(symbol: str, candles: List[float], timeframe: str = "1h"):
    """Fetch trading signal from Anso Vision backend"""
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            payload = {
                "symbol": symbol,
                "candles": candles,
                "timeframe": timeframe
            }
            
            response = await client.post(
                f"{SIGNAL_GENERATOR_URL}/analyze",
                json=payload
            )
            
            if response.status_code == 200:
                signal_data = response.json()
                print(f"✅ Signal generated for {symbol}: {signal_data.get('signal')}")
                return signal_data
            else:
                print(f"❌ Signal generator error: {response.text}")
                return None
                
    except Exception as e:
        print(f"❌ Error fetching signal: {str(e)}")
        return None

async def send_signal_to_trading_app(signal_data: dict):
    """Send signal from generator to trading backend"""
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            headers = {
                "X-API-Key": API_SECRET_KEY,
                "Content-Type": "application/json"
            }
            
            payload = {
                "symbol": signal_data.get("symbol"),
                "action": signal_data.get("signal", "BUY"),
                "volume": signal_data.get("volume", 0.01),
                "sl": signal_data.get("sl"),
                "tp": signal_data.get("tp"),
                "confidence": signal_data.get("confidence"),
                "timeframe": signal_data.get("timeframe")
            }
            
            response = await client.post(
                f"{TRADING_BACKEND_URL}/api/signal",
                json=payload,
                headers=headers
            )
            
            if response.status_code == 200:
                print(f"✅ Signal sent to trading backend: {signal_data['symbol']}")
                return response.json()
            else:
                print(f"❌ Failed to send signal: {response.text}")
                return None
                
    except Exception as e:
        print(f"❌ Error sending signal to trading app: {str(e)}")
        return None

# Database helper functions
async def init_supabase_tables():
    """Initialize Supabase tables if they don't exist"""
    supabase = get_supabase_client()
    
    try:
        supabase.table("users").select().limit(1).execute()
    except Exception:
        pass

@app.on_event("startup")
async def startup():
    """Initialize Supabase connection on startup"""
    try:
        supabase = get_supabase_client()
        supabase.table("users").select().limit(1).execute()
        print("✅ Supabase connection successful")
    except Exception as e:
        print(f"❌ Supabase connection failed: {e}")

@app.on_event("shutdown")
async def shutdown():
    """Cleanup on shutdown"""
    pass

# Endpoints
@app.get("/")
async def root():
    return {"message": "MT5 Community Trading API", "status": "running", "version": "2.0"}

@app.get("/health")
async def health():
    try:
        supabase = get_supabase_client()
        supabase.table("users").select().limit(1).execute()
        return {"status": "healthy", "database": "connected", "api_key": "configured"}
    except Exception as e:
        return {"status": "unhealthy", "database": "disconnected", "error": str(e)}, 500

@app.post("/api/signal")
async def receive_signal(signal: Signal, api_key: str = Depends(verify_api_key)):
    """Receive trading signal from signal generator"""
    try:
        supabase = get_supabase_client()
        
        response = supabase.table("signals").insert({
            "symbol": signal.symbol,
            "action": signal.action,
            "volume": signal.volume,
            "sl": signal.sl,
            "tp": signal.tp,
            "confidence": signal.confidence,
            "timeframe": signal.timeframe,
            "status": "pending",
            "created_at": datetime.utcnow().isoformat()
        }).execute()
        
        signal_id = response.data[0]["id"] if response.data else None
        print(f"✅ Signal stored: {signal.symbol} {signal.action}")
        
        return {"message": "Signal received", "signal_id": signal_id}
    except Exception as e:
        print(f"❌ Error storing signal: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error storing signal: {str(e)}")

@app.post("/api/signals/manual")
async def manual_signal(signal: Signal):
    """Manually send a trading signal (no API key required for testing)"""
    try:
        supabase = get_supabase_client()
        
        response = supabase.table("signals").insert({
            "symbol": signal.symbol,
            "action": signal.action.upper(),
            "volume": signal.volume,
            "sl": signal.sl,
            "tp": signal.tp,
            "confidence": signal.confidence or 0.85,
            "timeframe": signal.timeframe or "M15",
            "status": "pending",
            "created_at": datetime.utcnow().isoformat()
        }).execute()
        
        signal_id = response.data[0]["id"] if response.data else None
        print(f"✅ Manual signal stored: {signal.symbol} {signal.action}")
        
        return {
            "success": True,
            "message": "Signal created successfully",
            "signal_id": signal_id,
            "signal": {
                "symbol": signal.symbol,
                "action": signal.action.upper(),
                "volume": signal.volume,
                "sl": signal.sl,
                "tp": signal.tp,
                "status": "pending"
            }
        }
    except Exception as e:
        print(f"❌ Error creating manual signal: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error creating signal: {str(e)}")

@app.get("/api/signals/pending")
async def get_pending_signals(api_key: str = Depends(verify_api_key)):
    """MT5 EA polls this endpoint for new signals"""
    try:
        supabase = get_supabase_client()
        
        signals = supabase.table("signals").select("*").eq("status", "pending").order("created_at", desc=False).limit(10).execute()
        
        if signals.data:
            signal_ids = [s["id"] for s in signals.data]
            supabase.table("signals").update({"status": "processing"}).in_("id", signal_ids).execute()
        
        return signals.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching signals: {str(e)}")

@app.post("/api/trades/confirm")
async def confirm_trade(trade: TradeConfirmation, api_key: str = Depends(verify_api_key)):
    """MT5 EA confirms trade execution"""
    try:
        supabase = get_supabase_client()
        
        supabase.table("trades").insert({
            "ticket": trade.ticket,
            "symbol": trade.symbol,
            "action": trade.action,
            "volume": trade.volume,
            "open_price": trade.price,
            "status": "open",
            "opened_at": datetime.utcnow().isoformat()
        }).execute()
        
        print(f"✅ Trade confirmed: {trade.symbol} {trade.action}")
        return {"message": "Trade confirmed"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error confirming trade: {str(e)}")

@app.post("/api/account/update")
async def update_account(account: AccountUpdate, api_key: str = Depends(verify_api_key)):
    """MT5 EA sends account updates"""
    try:
        supabase = get_supabase_client()
        
        supabase.table("account_state").insert({
            "balance": account.balance,
            "equity": account.equity,
            "margin": account.margin,
            "free_margin": account.free_margin,
            "profit": account.profit,
            "timestamp": datetime.utcnow().isoformat()
        }).execute()
        
        await distribute_profits(account.profit)
        
        print(f"✅ Account updated: Balance={account.balance}, Profit={account.profit}")
        return {"message": "Account updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating account: {str(e)}")

@app.post("/api/users")
async def create_user(user: User):
    """Create new user"""
    try:
        supabase = get_supabase_client()
        
        supabase.table("users").insert({
            "user_id": user.user_id,
            "email": user.email,
            "investment": user.investment,
            "profit_loss": 0.0,
            "created_at": datetime.utcnow().isoformat()
        }).execute()
        
        print(f"✅ User created: {user.user_id}")
        return {"message": "User created", "user_id": user.user_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating user: {str(e)}")

@app.post("/api/users/{user_id}/invest")
async def user_invest(user_id: str, investment: UserInvestment):
    """User adds investment to community wallet"""
    try:
        supabase = get_supabase_client()
        
        user_data = supabase.table("users").select("investment").eq("user_id", user_id).execute()
        
        if not user_data.data:
            raise HTTPException(status_code=404, detail="User not found")
        
        current_investment = user_data.data[0]["investment"]
        new_investment = current_investment + investment.amount
        
        supabase.table("users").update({"investment": new_investment}).eq("user_id", user_id).execute()
        
        print(f"✅ Investment added: {user_id} +${investment.amount}")
        return {"message": "Investment added", "amount": investment.amount, "total": new_investment}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating investment: {str(e)}")

@app.get("/api/users/{user_id}/stats")
async def get_user_stats(user_id: str):
    """Get user's investment and profit/loss"""
    try:
        supabase = get_supabase_client()
        
        user = supabase.table("users").select("*").eq("user_id", user_id).execute()
        
        if not user.data:
            raise HTTPException(status_code=404, detail="User not found")
        
        return user.data[0]
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching user stats: {str(e)}")

@app.get("/api/account/stats")
async def get_account_stats():
    """Get current account statistics"""
    try:
        supabase = get_supabase_client()
        
        account_state = supabase.table("account_state").select("*").order("timestamp", desc=True).limit(1).execute()
        
        users = supabase.table("users").select("investment").execute()
        total_investment = sum(u["investment"] for u in users.data) if users.data else 0
        
        # Get current account config
        current_account = DEMO_ACCOUNT if ACCOUNT_MODE == "demo" else REAL_ACCOUNT
        current_server = DEMO_SERVER if ACCOUNT_MODE == "demo" else REAL_SERVER
        
        return {
            "account": account_state.data[0] if account_state.data else {},
            "total_investment": float(total_investment),
            "account_mode": ACCOUNT_MODE,
            "account_number": current_account,
            "server": current_server,
            "is_demo": ACCOUNT_MODE == "demo"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching account stats: {str(e)}")

@app.get("/api/account/config")
async def get_account_config():
    """Get MT5 account configuration for EA"""
    try:
        if ACCOUNT_MODE == "demo":
            if not DEMO_ACCOUNT or not DEMO_PASSWORD:
                raise HTTPException(status_code=500, detail="Demo account not configured")
            return {
                "mode": "demo",
                "account": DEMO_ACCOUNT,
                "password": DEMO_PASSWORD,
                "server": DEMO_SERVER
            }
        else:
            if not REAL_ACCOUNT or not REAL_PASSWORD:
                raise HTTPException(status_code=500, detail="Real account not configured")
            return {
                "mode": "real",
                "account": REAL_ACCOUNT,
                "password": REAL_PASSWORD,
                "server": REAL_SERVER
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting account config: {str(e)}")

@app.get("/api/trades/history")
async def get_trades_history(limit: int = 50):
    """Get trade history"""
    try:
        supabase = get_supabase_client()
        
        trades = supabase.table("trades").select("*").order("opened_at", desc=True).limit(limit).execute()
        
        return trades.data or []
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching trades: {str(e)}")



async def distribute_profits(total_profit: float):
    """Distribute profits/losses proportionally to users"""
    try:
        supabase = get_supabase_client()
        
        users = supabase.table("users").select("user_id, investment").gt("investment", 0).execute()
        
        if not users.data:
            return
        
        total_investment = sum(u["investment"] for u in users.data)
        
        if total_investment > 0:
            for user in users.data:
                user_share = user["investment"] / total_investment
                user_profit = total_profit * user_share
                
                supabase.table("users").update({"profit_loss": user_profit}).eq("user_id", user["user_id"]).execute()
                
        print(f"✅ Profits distributed: ${total_profit}")
    except Exception as e:
        print(f"❌ Error distributing profits: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
