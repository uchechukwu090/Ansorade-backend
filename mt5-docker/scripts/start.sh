#!/bin/bash

# Start Xvfb
Xvfb :99 -screen 0 1024x768x16 &
sleep 2

# Start VNC server
x11vnc -display :99 -forever -shared -bg

# Wait for display
sleep 2

# Start MT5
wine /root/.wine/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe \
    /config:/root/.wine/drive_c/Program\ Files/MetaTrader\ 5/config/terminal.ini \
    /login:${FBS_ACCOUNT} \
    /password:${FBS_PASSWORD} \
    /server:${FBS_SERVER} &

# Wait for MT5 to start
sleep 10

# Start monitoring API
python3 /app/monitor.py &

# Keep container running
tail -f /dev/null
