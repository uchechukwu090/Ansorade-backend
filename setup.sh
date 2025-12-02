#!/bin/bash

# Quick setup script for local development

echo "Setting up MT5 Community Trading Platform..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
    echo "⚠️  Please edit .env with your FBS credentials and API key"
fi

# Create necessary directories
mkdir -p mt5-docker/experts
mkdir -p logs

# Copy Expert Advisor to correct location
cp mql5-expert/CommunityTrader.mq5 mt5-docker/experts/

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env with your FBS credentials"
echo "2. Run: docker-compose up --build"
echo "3. Access VNC at localhost:5900 to monitor MT5"
echo "4. API will be available at http://localhost:8000"
echo ""
echo "For production deployment, see DEPLOYMENT.md"
