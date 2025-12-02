# Testing Guide

## Local Development Testing

### 1. Setup Environment

```bash
# Clone/navigate to project
cd mt5-community-trading

# Copy environment file
cp .env.example .env

# Edit .env with your credentials
nano .env
```

### 2. Start Services

```bash
# Build and start all services
docker-compose up --build

# Or run in detached mode
docker-compose up -d
```

### 3. Verify Services

**Check API Health**:
```bash
curl http://localhost:8000/health
```

Expected response:
```json
{"status": "healthy"}
```

**Check MT5 Container**:
```bash
docker logs mt5-community-trading-mt5-1
```

### 4. Access VNC

Use VNC client (e.g., TigerVNC, RealVNC):
- Host: `localhost:5900`
- View MT5 terminal
- Verify connection to FBS broker
- Check Expert Advisor is running

### 5. Test API Endpoints

**Create a test user**:
```bash
curl -X POST http://localhost:8000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_1",
    "email": "test@example.com",
    "investment": 1000.00
  }'
```

**Add investment**:
```bash
curl -X POST http://localhost:8000/api/users/test_user_1/invest \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_1",
    "amount": 500.00
  }'
```

**Send a test signal**:
```bash
curl -X POST http://localhost:8000/api/signal \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your_api_key_here" \
  -d '{
    "symbol": "EURUSD",
    "action": "BUY",
    "volume": 0.01,
    "sl": 1.0800,
    "tp": 1.0900
  }'
```

**Check account stats**:
```bash
curl http://localhost:8000/api/account/stats
```

**Check user stats**:
```bash
curl http://localhost:8000/api/users/test_user_1/stats
```

### 6. Use Example Client

```bash
# Install dependencies
pip install requests

# Edit example_client.py with your API_URL and API_KEY
nano example_client.py

# Run examples
python example_client.py
```

## Testing Checklist

### Pre-deployment
- [ ] MT5 connects to FBS broker
- [ ] Expert Advisor loads and runs
- [ ] API accepts signals
- [ ] Signals are stored in database
- [ ] EA polls and retrieves pending signals
- [ ] Trades execute in MT5
- [ ] Trade confirmations sent to API
- [ ] Account updates received
- [ ] Profit distribution calculates correctly
- [ ] User endpoints work

### Post-deployment (Render)
- [ ] Services are running
- [ ] Database connection works
- [ ] Environment variables set correctly
- [ ] MT5 connects from Render IP
- [ ] API is accessible via HTTPS
- [ ] Health checks passing
- [ ] VNC accessible (if needed)
- [ ] Logs are available

## Manual Testing Scenarios

### Scenario 1: Complete Trade Flow
1. Create user with investment
2. Send BUY signal via API
3. Verify signal in database (status: pending)
4. Wait for EA to poll (~1 second)
5. Check MT5 terminal for open position
6. Verify trade confirmation in database
7. Check account update received
8. Verify user profit/loss updated

### Scenario 2: Multiple Users
1. Create 3 users with different investments
2. Send signal
3. Wait for execution
4. Close position manually in MT5
5. Verify profit distributed proportionally

### Scenario 3: Signal Rejection
1. Send invalid signal (wrong symbol)
2. Verify EA handles error
3. Check logs for error message

### Scenario 4: Connection Loss
1. Stop MT5 container
2. Send signals
3. Restart MT5 container
4. Verify pending signals are processed

## Debugging

### Check MT5 Logs
```bash
# View MT5 container logs
docker logs -f mt5-community-trading-mt5-1

# Inside container (if needed)
docker exec -it mt5-community-trading-mt5-1 bash
cd /root/.wine/drive_c/Program\ Files/MetaTrader\ 5/Logs
```

### Check API Logs
```bash
# View API logs
docker logs -f mt5-community-trading-api-1

# On Render
# Use Render dashboard → Logs
```

### Database Queries
```bash
# Connect to database
docker exec -it mt5-community-trading-postgres-1 psql -U trading

# Or connect to Render PostgreSQL
psql $DATABASE_URL

# Useful queries:
SELECT * FROM signals ORDER BY created_at DESC LIMIT 10;
SELECT * FROM trades ORDER BY opened_at DESC LIMIT 10;
SELECT * FROM users;
SELECT * FROM account_state ORDER BY timestamp DESC LIMIT 1;
```

### Common Issues

**MT5 Won't Start**
- Check FBS credentials in .env
- Verify Wine installation
- Check display (Xvfb) is running
- Review startup script logs

**EA Not Executing Trades**
- Verify EA is loaded in MT5
- Check AutoTrading is enabled
- Verify API connection
- Check signal format
- Ensure sufficient margin

**API Connection Failed**
- Check API_URL in EA code
- Verify API_KEY matches
- Check network connectivity
- Review firewall rules

**Trades Not Confirming**
- Check MT5 terminal logs
- Verify trade execution in MT5
- Check API endpoint
- Review EA code for errors

## Performance Testing

### Load Testing
```bash
# Install tools
pip install locust

# Create locustfile.py
cat > locustfile.py << 'EOF'
from locust import HttpUser, task, between

class TradingUser(HttpUser):
    wait_time = between(1, 3)
    
    @task
    def send_signal(self):
        self.client.post("/api/signal",
            json={
                "symbol": "EURUSD",
                "action": "BUY",
                "volume": 0.01
            },
            headers={"X-API-Key": "your_api_key"}
        )
    
    @task(3)
    def get_stats(self):
        self.client.get("/api/account/stats")
EOF

# Run load test
locust -f locustfile.py
```

### Monitor Resources
```bash
# Check container resources
docker stats

# Check database connections
# In PostgreSQL:
SELECT count(*) FROM pg_stat_activity;
```

## Automated Testing

### Unit Tests (Future Enhancement)
```python
# backend-api/tests/test_api.py
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_create_user():
    response = client.post("/api/users", json={
        "user_id": "test123",
        "email": "test@example.com",
        "investment": 1000.0
    })
    assert response.status_code == 200
    assert response.json()["user_id"] == "test123"

# Run tests
# pytest tests/
```

## Production Monitoring

### Health Check Script
```bash
#!/bin/bash
# health_check.sh

API_URL="https://your-api.onrender.com"
MT5_URL="https://your-mt5.onrender.com"

echo "Checking API health..."
curl -f $API_URL/health || echo "❌ API DOWN"

echo "Checking MT5 health..."
curl -f $MT5_URL/health || echo "❌ MT5 DOWN"

echo "Checking latest trades..."
curl $API_URL/api/account/stats
```

### Set up monitoring with:
- Render's built-in monitoring
- UptimeRobot or similar
- Custom health check script (cron job)
- Alerting via email/SMS/Telegram

## Safety Measures

### Demo Account Testing
1. Use FBS demo account first
2. Test all functionality
3. Verify profit distribution
4. Run for several days
5. Monitor for issues

### Real Account Checklist
- [ ] Demo testing completed successfully
- [ ] All users understand risks
- [ ] Stop loss mechanisms in place
- [ ] Maximum position size limits set
- [ ] Emergency shutdown procedure documented
- [ ] Regular backup schedule
- [ ] Monitoring alerts configured

### Risk Management
- Start with small investments
- Use stop losses on all trades
- Monitor daily
- Have emergency contact procedure
- Regular profit withdrawals
- Diversify signal sources
