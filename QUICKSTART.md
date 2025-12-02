# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Docker & Docker Compose installed
- FBS MT5 account (demo or real)
- PostgreSQL database (local or cloud)

### Step 1: Clone and Configure
```bash
cd mt5-community-trading
cp .env.example .env
nano .env  # Add your FBS credentials and API key
```

### Step 2: Start Services
```bash
docker-compose up --build
```

Wait 1-2 minutes for services to start.

### Step 3: Verify Everything Works

**Check API:**
```bash
curl http://localhost:8000/health
# Should return: {"status":"healthy"}
```

**Access MT5 via VNC:**
- Open VNC client
- Connect to: `localhost:5900`
- Check MT5 is connected to FBS
- Verify Expert Advisor is running

### Step 4: Send Your First Signal
```bash
curl -X POST http://localhost:8000/api/signal \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your_api_key_from_env" \
  -d '{
    "symbol": "EURUSD",
    "action": "BUY",
    "volume": 0.01,
    "sl": 1.0800,
    "tp": 1.0900
  }'
```

Within 1-2 seconds, check MT5 terminal for the executed trade!

---

## 📋 Project Structure

```
mt5-community-trading/
├── backend-api/              # FastAPI backend
│   ├── main.py              # Main API code
│   ├── Dockerfile           # API container
│   └── requirements.txt     # Python dependencies
│
├── mt5-docker/              # MT5 Docker setup
│   ├── Dockerfile           # MT5 container
│   ├── config/              # MT5 configuration
│   ├── scripts/             # Startup scripts
│   └── supervisor/          # Process management
│
├── mql5-expert/             # Expert Advisor
│   └── CommunityTrader.mq5  # EA source code
│
├── example_client.py        # Example signal sender
├── docker-compose.yml       # Local development
├── .env.example            # Environment template
│
└── Documentation:
    ├── README.md           # Overview
    ├── ARCHITECTURE.md     # System design
    ├── DEPLOYMENT.md       # Render deployment
    └── TESTING.md          # Testing guide
```

---

## 🎯 Key Concepts

### How It Works
1. **Your signal generator** sends signals to the API
2. **Backend API** stores signals in PostgreSQL
3. **MT5 Expert Advisor** polls API every second
4. **EA executes trades** in MT5 terminal
5. **Profits/losses** are distributed to users proportionally

### Investment Model
- All users invest in one FBS account (community wallet)
- Trades execute for the entire community
- Profits split based on investment percentage

**Example:**
- Total pool: $10,000
- User A invested: $3,000 (30%)
- User B invested: $7,000 (70%)
- Trade profit: $500
- User A gets: $150 (30%)
- User B gets: $350 (70%)

---

## 🔗 Important Endpoints

### Signal Management
- `POST /api/signal` - Send new trading signal
- `GET /api/signals/pending` - Get pending signals (used by EA)

### User Management
- `POST /api/users` - Create new user
- `POST /api/users/{id}/invest` - Add investment
- `GET /api/users/{id}/stats` - Get user statistics

### Account Info
- `GET /api/account/stats` - Get account statistics
- `POST /api/account/update` - Update account (used by EA)

### Trade Tracking
- `POST /api/trades/confirm` - Confirm trade execution (used by EA)

---

## 🛠️ Common Commands

**View logs:**
```bash
docker-compose logs -f        # All services
docker-compose logs -f api    # Just API
docker-compose logs -f mt5    # Just MT5
```

**Restart services:**
```bash
docker-compose restart
```

**Stop everything:**
```bash
docker-compose down
```

**Rebuild after changes:**
```bash
docker-compose up --build
```

**Check container status:**
```bash
docker-compose ps
```

---

## 📊 Monitoring

### Check Account Status
```bash
curl http://localhost:8000/api/account/stats
```

### Create and Check User
```bash
# Create user
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user1","email":"user1@example.com","investment":1000}'

# Check user stats
curl http://localhost:8000/api/users/user1/stats
```

### Use Example Client
```bash
python example_client.py
```

---

## ⚠️ Important Notes

### Security
- Change API_SECRET_KEY in .env
- NEVER commit .env file
- Use strong passwords for FBS account
- Enable 2FA on FBS account

### Testing
- Start with FBS **DEMO** account
- Test thoroughly before using real money
- Use small lot sizes (0.01) initially
- Monitor for at least a week

### Render Deployment
- Free tier sleeps after 15 min inactivity
- Use paid tier for production ($7+/month)
- MT5 needs constant connection to broker
- Check FBS allows connections from Render IPs

---

## 🆘 Troubleshooting

**MT5 won't connect:**
- Check FBS credentials in .env
- Verify FBS server name (FBS-Real or FBS-Demo)
- Check if FBS allows connections from your IP

**EA not executing trades:**
- Open VNC and check MT5 terminal
- Verify AutoTrading button is ON (green)
- Check Expert Advisors are allowed in Tools > Options
- Look for errors in MT5 Experts tab

**API returns 403 Forbidden:**
- Check X-API-Key header matches .env
- Verify API_SECRET_KEY is set correctly

**No trades executing:**
- Check EA is running in MT5 (via VNC)
- Verify signal format is correct
- Check MT5 terminal for error messages
- Ensure sufficient margin in account

---

## 📚 Next Steps

1. **Read Documentation:**
   - ARCHITECTURE.md - Understand the system
   - DEPLOYMENT.md - Deploy to Render
   - TESTING.md - Test thoroughly

2. **Integrate Your Signal Generator:**
   - Use example_client.py as reference
   - Send signals to your API endpoint
   - Monitor execution

3. **Add Users:**
   - Create user accounts
   - Track investments
   - Monitor profit distribution

4. **Deploy to Production:**
   - Follow DEPLOYMENT.md
   - Use Render or similar platform
   - Set up monitoring and alerts

---

## 💡 Tips

- Start with small investments
- Use stop losses on all signals
- Monitor daily, especially initially
- Keep EA and API logs for debugging
- Test signal generator thoroughly
- Have emergency shutdown procedure
- Regular profit withdrawals

---

## 📞 Need Help?

- Check TESTING.md for debugging tips
- Review logs: `docker-compose logs`
- Connect via VNC to see MT5 directly
- Test with demo account first

---

**Good luck with your community trading platform! 🚀📈**
