#!/bin/bash -e

APP_DIR="${ROOTFS_DIR}/opt/antigravity"

echo "Copying app files into rootfs..."
mkdir -p "${APP_DIR}"
cp -r files/* "${APP_DIR}/"
mkdir -p "${APP_DIR}/db"
chmod -R 755 "${APP_DIR}"

echo "Writing systemd service file..."
install -m 644 /dev/stdin "${ROOTFS_DIR}/etc/systemd/system/antigravity.service" << 'SERVICE'
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
SERVICE

echo "Setting up Python virtual environment in chroot..."
on_chroot << 'CHROOT'
    APP_DIR="/opt/antigravity"

    # Create pi user if it doesn't exist (Bookworm Lite default)
    if ! id "pi" &>/dev/null; then
        echo "Creating 'pi' user..."
        useradd -m -s /bin/bash pi
        echo "pi:raspberry" | chpasswd
        usermod -aG sudo,video,audio,input,bluetooth pi
    fi

    chown -R pi:pi "${APP_DIR}"

    python3 -m venv "${APP_DIR}/.venv"
    "${APP_DIR}/.venv/bin/pip" install --upgrade pip
    "${APP_DIR}/.venv/bin/pip" install -r "${APP_DIR}/requirements.txt"

    systemctl daemon-reload
    systemctl enable antigravity.service
CHROOT
