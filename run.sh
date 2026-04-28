#!/bin/bash
# Antigravity POS Run Script
# Supports: Raspberry Pi (eglfs), Linux Desktop (xcb), macOS (cocoa)

set -e

# Detect platform
OS="$(uname -s)"
IS_RPI=0

if [ -f /etc/rpi-issue ] || grep -qi "raspberry" /proc/device-tree/model 2>/dev/null; then
    IS_RPI=1
fi

if [ "$IS_RPI" -eq 1 ]; then
    # Raspberry Pi: use EGLFS for hardware-accelerated, framebuffer rendering
    export QT_QPA_PLATFORM=eglfs
    export QT_QPA_EGLFS_KMS_ATOMIC=1
    export QT_QUICK_CONTROLS_STYLE=Basic
elif [ "$OS" = "Darwin" ]; then
    # macOS: use native cocoa backend (Qt default — no env var needed)
    export QT_QUICK_CONTROLS_STYLE=Basic
    unset QT_QPA_PLATFORM
else
    # Linux Desktop: use XCB (X11)
    export QT_QPA_PLATFORM=xcb
    export QT_QUICK_CONTROLS_STYLE=Basic
fi

echo "🚀 Starting Antigravity POS on $OS (IS_RPI=$IS_RPI)..."

# Activate venv if present
if [ -d ".venv" ]; then
    # shellcheck disable=SC1091
    source .venv/bin/activate
fi

python3 main.py
