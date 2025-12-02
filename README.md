# MT5 Community Trading Platform

A dockerized MetaTrader 5 solution for community-based trading on Render.

## Architecture

1. **MT5 Docker Container**: Runs MT5 terminal with Expert Advisor
2. **Backend API**: Receives signals and manages user funds
3. **MQL5 Expert Advisor**: Executes trades based on signals

## Components

### 1. MT5 Docker (`mt5-docker/`)
- Dockerfile for Wine-based MT5 installation
- MT5 terminal configuration
- VNC for optional monitoring

### 2. Backend API (`backend-api/`)
- FastAPI server for signal reception
- User wallet management
- Trade execution coordination
- Profit/loss distribution

### 3. MQL5 Expert (`mql5-expert/`)
- Expert Advisor for trade execution
- API communication module
- Risk management

## Setup

### Environment Variables
Create `.env` file:
```
FBS_ACCOUNT=your_account_number
FBS_PASSWORD=your_password
FBS_SERVER=FBS-Real
API_SECRET_KEY=your_secret_key
DATABASE_URL=your_database_url
```

### Deployment to Render

1. Build and push Docker image
2. Configure Render service with environment variables
3. Deploy backend API separately
4. Connect signal generator

## Usage

Send signals to API:
```bash
curl -X POST https://your-api.render.com/api/signal \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "EURUSD",
    "action": "BUY",
    "volume": 0.01,
    "sl": 1.0800,
    "tp": 1.0900
  }'
```

## Security Notes

- Never commit `.env` file
- Use secure API keys
- Implement proper authentication
- Monitor account activity
