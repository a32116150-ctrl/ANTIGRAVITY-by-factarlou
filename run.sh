#!/bin/bash
# Antigravity POS Run Script
# Optimized for Raspberry Pi (eglfs platform for hardware acceleration)

# Check if running on Pi or Desktop
if [ -f /etc/rpi-issue ]; then
    export QT_QPA_PLATFORM=eglfs
else
    # Desktop fallback
    export QT_QPA_PLATFORM=xcb
fi

# Run application
python3 main.py
