#!/bin/bash -e

APP_DIR="/opt/antigravity"
SERVICE_FILE="/etc/systemd/system/antigravity.service"

echo "Setting up Python virtual environment..."
python3 -m venv "${APP_DIR}/.venv"
"${APP_DIR}/.venv/bin/pip" install --upgrade pip
"${APP_DIR}/.venv/bin/pip" install -r "${APP_DIR}/requirements.txt"

echo "Setting up systemd service..."
cat > "${SERVICE_FILE}" << 'EOF'
[Unit]
Description=Antigravity POS by factarlou
After=network.target
Wants=graphical.target

[Service]
Type=simple
User=pi
Environment=QT_QPA_PLATFORM=eglfs
Environment=QT_QPA_EGLFS_KMS_ATOMIC=1
Environment=QT_QUICK_CONTROLS_STYLE=Basic
Environment=PYTHONPATH=/opt/antigravity
WorkingDirectory=/opt/antigravity
ExecStart=/opt/antigravity/.venv/bin/python3 /opt/antigravity/main.py
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical.target
EOF

systemctl daemon-reload
systemctl enable antigravity.service
