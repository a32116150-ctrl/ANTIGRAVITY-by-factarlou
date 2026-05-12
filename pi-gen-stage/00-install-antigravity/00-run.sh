#!/bin/bash -e

APP_DIR="${ROOTFS_DIR}/opt/antigravity"

echo "Copying app files into rootfs using FILESDIR..."
mkdir -p "${APP_DIR}"
# Use official FILESDIR variable for robustness
# Copy each item explicitly to avoid accidental recursion with Buildroot/pi-gen folders
cp -r "${FILESDIR}"/app "${APP_DIR}/"
cp -r "${FILESDIR}"/ui "${APP_DIR}/"
cp "${FILESDIR}"/main.py "${APP_DIR}/"
cp "${FILESDIR}"/requirements.txt "${APP_DIR}/"
mkdir -p "${APP_DIR}/db"

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
WantedBy=multi-user.target
SERVICE

echo "Setting up environment in chroot..."
on_chroot << 'CHROOT'
    APP_DIR="/opt/antigravity"

    # Create pi user if it doesn't exist (Critical for Bookworm Lite)
    if ! id "pi" &>/dev/null; then
        echo "Creating 'pi' user..."
        useradd -m -s /bin/bash pi
        echo "pi:raspberry" | chpasswd
        usermod -aG sudo,video,audio,input,bluetooth pi
    fi

    chown -R pi:pi "${APP_DIR}"

    # Setup Virtual Environment
    python3 -m venv "${APP_DIR}/.venv"
    "${APP_DIR}/.venv/bin/pip" install --upgrade pip
    "${APP_DIR}/.venv/bin/pip" install -r "${APP_DIR}/requirements.txt"

    # Enable service via manual symlink (More reliable than systemctl enable in chroot)
    mkdir -p /etc/systemd/system/multi-user.target.wants
    ln -sf /etc/systemd/system/antigravity.service \
           /etc/systemd/system/multi-user.target.wants/antigravity.service
CHROOT
