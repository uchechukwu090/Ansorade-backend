#!/bin/bash

# ✅ DEPLOYMENT CHECKLIST FOR ANSORADE TRADING PLATFORM
# This script validates and fixes all critical issues

echo "🚀 ANSORADE DEPLOYMENT CHECKLIST"
echo "=================================="
echo ""

# Check Node.js version
echo "1️⃣ Checking Node.js environment..."
node_version=$(node -v)
npm_version=$(npm -v)
echo "   Node.js: $node_version"
echo "   npm: $npm_version"
echo ""

# Check frontend dependencies
echo "2️⃣ Checking frontend dependencies..."
if [ -f "package.json" ]; then
    echo "   ✅ package.json found"
    echo "   Installing dependencies (if needed)..."
    npm ci --legacy-peer-deps
else
    echo "   ❌ package.json not found - run from frontend directory"
    exit 1
fi
echo ""

# Check environment variables
echo "3️⃣ Checking environment variables..."
if [ -f ".env.local" ]; then
    echo "   ✅ .env.local file found"
    echo "   NEXT_PUBLIC_API_URL: $(grep NEXT_PUBLIC_API_URL .env.local || echo 'NOT SET')"
else
    echo "   ⚠️ .env.local not found - using defaults or system env"
fi
echo ""

# Build frontend
echo "4️⃣ Building frontend..."
npm run build
if [ $? -eq 0 ]; then
    echo "   ✅ Build successful"
else
    echo "   ❌ Build failed - check errors above"
    exit 1
fi
echo ""

echo "5️⃣ Deployment Ready!"
echo "   To deploy to Vercel:"
echo "   • Push to GitHub: git push origin main"
echo "   • Vercel will automatically build and deploy"
echo ""
echo "   Environment variables to set in Vercel:"
echo "   NEXT_PUBLIC_API_URL=https://ansorade-backend.onrender.com"
echo "   NEXT_PUBLIC_API_SECRET_KEY=Mr.creative090"
echo "   NEXT_PUBLIC_SUPABASE_URL=https://xhjnvdiupbsnqorwotaa.supabase.co"
echo "   NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-key>"
echo ""
