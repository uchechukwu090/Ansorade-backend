# Deployment Guide for Render

## Prerequisites
1. Render account
2. FBS MT5 account credentials
3. PostgreSQL database (Render provides this)
4. Docker Hub account (for pushing images)

## Step 1: Build and Push Docker Images

### MT5 Container
```bash
cd mt5-docker
docker build -t your-dockerhub-username/mt5-community:latest .
docker push your-dockerhub-username/mt5-community:latest
```

### Backend API
```bash
cd backend-api
docker build -t your-dockerhub-username/mt5-api:latest .
docker push your-dockerhub-username/mt5-api:latest
```

## Step 2: Setup Render Services

### Create PostgreSQL Database
1. Go to Render Dashboard
2. New → PostgreSQL
3. Name: `community-trading-db`
4. Save connection string

### Deploy Backend API
1. New → Web Service
2. Deploy from Docker image
3. Image URL: `your-dockerhub-username/mt5-api:latest`
4. Environment variables:
   - `DATABASE_URL`: (from PostgreSQL above)
   - `API_SECRET_KEY`: (generate secure key)
5. Instance type: Starter or above
6. Deploy

### Deploy MT5 Container
1. New → Web Service
2. Deploy from Docker image
3. Image URL: `your-dockerhub-username/mt5-community:latest`
4. Environment variables:
   - `FBS_ACCOUNT`: Your FBS account number
   - `FBS_PASSWORD`: Your FBS password
   - `FBS_SERVER`: FBS-Real
   - `API_SECRET_KEY`: (same as API)
5. Instance type: Standard or above (needs more resources)
6. Health check path: `/health`
7. Deploy

## Step 3: Configure MT5

### Upload Expert Advisor
Since Render doesn't have persistent storage, you need to:
1. Build the EA into the Docker image (already done)
2. Or use VNC to access MT5 and manually upload

### VNC Access
- Use VNC client to connect to: `your-mt5-service.onrender.com:5900`
- Monitor MT5 terminal
- Ensure EA is running

## Step 4: Connect Signal Generator

Your signal generator should send POST requests to:
```
https://your-api-service.onrender.com/api/signal
```

Headers:
```
X-API-Key: your_api_secret_key
Content-Type: application/json
```

Body:
```json
{
  "symbol": "EURUSD",
  "action": "BUY",
  "volume": 0.01,
  "sl": 1.0800,
  "tp": 1.0900
}
```

## Step 5: User Management

### Create users via API:
```bash
curl -X POST https://your-api-service.onrender.com/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "email": "user@example.com",
    "investment": 1000.00
  }'
```

### User invests:
```bash
curl -X POST https://your-api-service.onrender.com/api/users/user123/invest \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "amount": 500.00
  }'
```

## Important Notes

### Render Limitations
- Free tier spins down after 15 min inactivity
- Use paid tier for production
- MT5 needs persistent connection to broker

### Security
- NEVER commit `.env` with real credentials
- Use strong API keys
- Implement rate limiting
- Add authentication for user endpoints

### Monitoring
- Check Render logs regularly
- Monitor MT5 via VNC
- Set up alerts for failed trades
- Track account balance

## Troubleshooting

### MT5 Won't Connect
- Check FBS credentials
- Verify FBS allows connection from Render IPs
- Check firewall settings

### Trades Not Executing
- Verify EA is running in MT5
- Check EA logs in terminal
- Ensure AutoTrading is enabled
- Verify sufficient margin

### API Not Responding
- Check Render service status
- Verify environment variables
- Check database connection
- Review application logs

## Alternative: Render Blueprint

Create `render.yaml`:
```yaml
services:
  - type: web
    name: mt5-api
    env: docker
    dockerfilePath: ./backend-api/Dockerfile
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: community-trading-db
          property: connectionString
      - key: API_SECRET_KEY
        generateValue: true

  - type: web
    name: mt5-container
    env: docker
    dockerfilePath: ./mt5-docker/Dockerfile
    envVars:
      - key: FBS_ACCOUNT
        sync: false
      - key: FBS_PASSWORD
        sync: false
      - key: FBS_SERVER
        value: FBS-Real

databases:
  - name: community-trading-db
    plan: starter
```

Deploy with: `render deploy`
