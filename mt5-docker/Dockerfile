FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99

# Install Wine and dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    wget \
    wine64 \
    wine32 \
    xvfb \
    x11vnc \
    supervisor \
    curl \
    python3 \
    python3-pip && \
    apt-get clean

# Create MT5 directory
RUN mkdir -p /root/.wine/drive_c/Program\ Files/MetaTrader\ 5

# Download and install MT5 (FBS)
WORKDIR /tmp
RUN wget -O fbs5setup.exe https://fbs.com/trading-platforms/metatrader5/download && \
    wine fbs5setup.exe /auto || true

# Wait for installation
RUN sleep 10

# Copy MT5 configuration
COPY config/terminal.ini /root/.wine/drive_c/Program\ Files/MetaTrader\ 5/config/

# Copy Expert Advisor
COPY experts/ /root/.wine/drive_c/Program\ Files/MetaTrader\ 5/MQL5/Experts/

# Install Python dependencies for monitoring
RUN pip3 install fastapi uvicorn requests

# Copy startup script
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

# Copy supervisor config
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose VNC and API ports
EXPOSE 5900 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
