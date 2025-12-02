# MT5 Community Trading Platform - Architecture

## System Overview

```
┌─────────────────┐
│  Signal         │
│  Generator      │──┐
│  (Your App)     │  │
└─────────────────┘  │
                     │ HTTP POST
                     ▼
┌──────────────────────────────────────────────┐
│           Backend API (Render)               │
│                                              │
│  ┌────────────────────────────────────┐   │
│  │  FastAPI                            │   │
│  │  - Receive signals                  │   │
│  │  - Manage users                     │   │
│  │  - Track investments                │   │
│  │  - Distribute profits               │   │
│  └────────────────────────────────────┘   │
│                    │                        │
│                    ▼                        │
│         ┌─────────────────┐               │
│         │  PostgreSQL DB  │               │
│         └─────────────────┘               │
└──────────────────────────────────────────────┘
                     │
                     │ HTTP (polling)
                     ▼
┌──────────────────────────────────────────────┐
│      MT5 Docker Container (Render)           │
│                                              │
│  ┌────────────────────────────────────┐   │
│  │  Wine + Xvfb                       │   │
│  │  ┌──────────────────────────┐    │   │
│  │  │  MetaTrader 5 Terminal   │    │   │
│  │  │                           │    │   │
│  │  │  ┌───────────────────┐  │    │   │
│  │  │  │ Expert Advisor    │  │    │   │
│  │  │  │ - Poll for signals│  │    │   │
│  │  │  │ - Execute trades  │  │    │   │
│  │  │  │ - Send updates    │  │    │   │
│  │  │  └───────────────────┘  │    │   │
│  │  └──────────────────────────┘    │   │
│  └────────────────────────────────────┘   │
│                    │                        │
│                    ▼                        │
│         ┌─────────────────┐               │
│         │  VNC Server     │               │
│         │  (Monitoring)   │               │
│         └─────────────────┘               │
└──────────────────────────────────────────────┘
                     │
                     │ MT5 Protocol
                     ▼
┌──────────────────────────────────────────────┐
│         FBS Broker Server                    │
│         - Real Trading Account               │
│         - Execute Orders                     │
│         - Account Balance                    │
└──────────────────────────────────────────────┘
```

## Data Flow

### 1. Signal Reception
```
Signal Generator → API (/api/signal) → PostgreSQL (pending)
```

### 2. Signal Execution
```
EA polls API (/api/signals/pending) → EA executes → Confirms to API
```

### 3. Profit Distribution
```
MT5 Account Updates → API calculates shares → Update user P/L
```

## Components

### Backend API
- **Language**: Python 3.11
- **Framework**: FastAPI
- **Database**: PostgreSQL
- **Deployment**: Render (Web Service)

**Key Endpoints**:
- `POST /api/signal` - Receive trading signals
- `GET /api/signals/pending` - MT5 polls for new signals
- `POST /api/trades/confirm` - Confirm trade execution
- `POST /api/account/update` - Update account state
- `POST /api/users` - Create user
- `POST /api/users/{id}/invest` - Add investment
- `GET /api/users/{id}/stats` - Get user statistics
- `GET /api/account/stats` - Get account statistics

### MT5 Docker Container
- **Base**: Ubuntu 22.04
- **Runtime**: Wine (Windows emulator)
- **Display**: Xvfb (virtual framebuffer)
- **Monitoring**: VNC server
- **Platform**: MetaTrader 5

**Components**:
- MT5 Terminal (Windows app via Wine)
- Expert Advisor (MQL5)
- VNC Server (port 5900)
- Health check endpoint

### Expert Advisor (EA)
- **Language**: MQL5
- **Functions**:
  - Poll API every second for signals
  - Execute trades via MT5 API
  - Send trade confirmations
  - Send account updates
  - Handle errors

### Database Schema

**users**
```sql
user_id (PK)
email
investment (DECIMAL)
profit_loss (DECIMAL)
created_at
```

**signals**
```sql
signal_id (PK)
symbol
action (BUY/SELL)
volume
sl (stop loss)
tp (take profit)
status (pending/processing/executed)
created_at
executed_at
```

**trades**
```sql
trade_id (PK)
ticket (MT5 ticket number)
signal_id (FK)
symbol
action
volume
open_price
close_price
profit
status (open/closed)
opened_at
closed_at
```

**account_state**
```sql
id (PK)
balance
equity
margin
free_margin
profit
timestamp
```

## Investment Model

### Community Wallet
- All users invest in a single FBS account
- Trades are executed on behalf of the community
- Profits/losses are distributed proportionally

### Profit Distribution Formula
```
User Share = (User Investment / Total Investment) × 100%
User Profit = Total Account Profit × User Share
```

### Example
```
Total Investment: $10,000
User A: $3,000 (30%)
User B: $7,000 (70%)

If account profit = $500:
User A profit = $500 × 30% = $150
User B profit = $500 × 70% = $350
```

## Security Considerations

1. **API Authentication**: All endpoints require API key
2. **Environment Variables**: Sensitive data in env vars
3. **No Direct Access**: Users can't directly access MT5
4. **Rate Limiting**: Prevent API abuse
5. **Audit Logging**: Track all trades and investments

## Limitations & Considerations

### Render Challenges
- No persistent storage (EA must be in Docker image)
- Network egress costs for high-frequency trading
- Need paid tier for 24/7 operation
- IP address may change (check FBS whitelist)

### MT5 Docker Challenges
- Wine can be unstable
- VNC adds overhead
- MT5 needs stable connection
- Resource intensive

### Trading Risks
- All users share same account risk
- No individual stop losses per user
- Single point of failure
- Broker limitations (max positions, etc.)

## Alternatives to Consider

1. **Direct Broker API**: Some brokers offer REST/FIX APIs
2. **MT5 Gateway**: Third-party MT5 API gateways
3. **VPS Provider**: Traditional VPS with MT5
4. **Copy Trading**: Use broker's copy trading feature

## Monitoring

### Health Checks
- API health endpoint
- MT5 container health
- Database connection
- EA heartbeat

### Metrics to Track
- Signal latency (reception to execution)
- Trade execution success rate
- Account balance changes
- User profit/loss distribution
- System uptime

### Alerts
- Failed trade executions
- MT5 disconnection
- API errors
- Unusual account activity

## Scaling Considerations

### Current Setup
- Single MT5 account
- One signal generator
- Limited to broker's max positions

### Future Enhancements
- Multiple MT5 accounts
- Risk management per signal
- User-specific settings
- Multiple signal generators
- Portfolio rebalancing
- Real-time notifications
