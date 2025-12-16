#!/bin/bash

# ✅ DEPLOYMENT SCRIPT - Execute in order
# This script commits and deploys all fixes to production

echo "🚀 ANSORADE DEPLOYMENT SCRIPT"
echo "========================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check git status
echo -e "${YELLOW}Checking git status...${NC}"
git status

echo ""
echo "========================================"
echo -e "${YELLOW}Step 1: Commit MT5 Backend Changes${NC}"
echo "========================================"
cd C:\mt5-community-trading

git add backend-api/main.py
git add mql5-expert/CommunityTrader.mq5
git add FIXES_APPLIED.txt
git add QUICK_ACTION_PLAN.txt
git add SUMMARY_OF_FIXES.txt

git commit -m "🔧 Fix: Add comprehensive logging and error handling

- Enhanced /api/signal endpoint with detailed logging
- Complete rewrite of CommunityTrader.mq5 EA (v2.01) with file logging
- Now logs every step: polling, validation, execution, confirmation
- Trace entire signal flow for debugging
- Better error messages and status codes"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ MT5 Backend changes committed${NC}"
else
    echo -e "${RED}❌ Failed to commit MT5 Backend changes${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${YELLOW}Step 2: Deploy to Render (MT5 Backend)${NC}"
echo "========================================"
echo "Pushing to GitHub (Render will auto-deploy)..."

git push origin main

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Pushed to GitHub${NC}"
    echo "Monitor deployment at: https://dashboard.render.com"
else
    echo -e "${RED}❌ Push failed${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${YELLOW}Step 3: Commit Frontend Changes${NC}"
echo "========================================"
cd C:\Users\User\dyad-apps\Ansorade

git add next.config.ts
git add src/lib/api-client.ts
git add src/context/TradingContext.tsx

git commit -m "🔧 Fix: Frontend build and API error handling

- Fixed webpack configuration for Vercel builds
- Enhanced API client with graceful error handling
- Better error messages for debugging
- Fallback empty stats prevent UI crashes
- Improved polling and real-time subscriptions
- Added diagnostic method for connectivity testing"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend changes committed${NC}"
else
    echo -e "${RED}❌ Failed to commit Frontend changes${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${YELLOW}Step 4: Deploy to Vercel (Frontend)${NC}"
echo "========================================"
echo "Pushing to GitHub (Vercel will auto-deploy)..."

git push origin main

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Pushed to GitHub${NC}"
    echo "Monitor deployment at: https://vercel.com/dashboard"
else
    echo -e "${RED}❌ Push failed${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${YELLOW}Step 5: Commit Signal Generator Changes${NC}"
echo "========================================"
cd C:\Users\User\Desktop\Anso-vision-backend

git add api_server_integrated.py

git commit -m "🔧 Fix: Enhanced signal posting logging

- Added detailed logging when posting signals to MT5
- Better error messages for connection issues
- Clear signal flow visualization
- Added connection diagnostics"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Signal generator changes committed${NC}"
else
    echo -e "${RED}❌ Failed to commit Signal generator changes${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${YELLOW}Step 6: Deploy to Render (Signal Generator)${NC}"
echo "========================================"
echo "Pushing to GitHub (Render will auto-deploy)..."

git push origin main

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Pushed to GitHub${NC}"
    echo "Monitor deployment at: https://dashboard.render.com"
else
    echo -e "${RED}❌ Push failed${NC}"
    exit 1
fi

echo ""
echo "========================================"
echo -e "${GREEN}✅ ALL DEPLOYMENTS COMPLETE${NC}"
echo "========================================"
echo ""
echo "📊 Deployment Summary:"
echo ""
echo "1️⃣ MT5 Backend (Render)"
echo "   URL: https://ansorade-backend.onrender.com"
echo "   Status: Check dashboard.render.com"
echo "   ETA: 2-3 minutes"
echo ""
echo "2️⃣ Frontend (Vercel)"
echo "   URL: https://ansorade-community-trading-platform-global-investmen-600a5u0yk.vercel.app"
echo "   Status: Check vercel.com/dashboard"
echo "   ETA: 2-3 minutes"
echo ""
echo "3️⃣ Signal Generator (Render)"
echo "   URL: https://anso-vision-backend.onrender.com"
echo "   Status: Check dashboard.render.com"
echo "   ETA: 2-3 minutes"
echo ""
echo "⏱️ Wait 5-10 minutes for all services to be fully deployed"
echo ""
echo "✅ Next Steps:"
echo "   1. Check MT5 log file for order execution logs"
echo "   2. Test signal through frontend"
echo "   3. Verify order execution in MT5"
echo "   4. Check frontend balance updates"
echo ""
echo "📝 For detailed info, see:"
echo "   - FIXES_APPLIED.txt - What was fixed
echo "   - QUICK_ACTION_PLAN.txt - How to verify"
echo "   - SUMMARY_OF_FIXES.txt - Complete overview"
echo ""
