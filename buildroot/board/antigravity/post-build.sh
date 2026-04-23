#!/bin/sh

set -u
set -e

# Path to the buildroot target directory
TARGET_DIR=$1
BOARD_DIR="board/antigravity"

# 1. Copy Application Files
mkdir -p "${TARGET_DIR}/opt/antigravity"
cp -r ../app "${TARGET_DIR}/opt/antigravity/"
cp -r ../ui "${TARGET_DIR}/opt/antigravity/"
cp -r ../assets "${TARGET_DIR}/opt/antigravity/"

# 2. Create /db mount point
mkdir -p "${TARGET_DIR}/db"

# 3. Create Systemd Service for Auto-start
cat <<EOF > "${TARGET_DIR}/etc/systemd/system/antigravity.service"
[Unit]
Description=Antigravity POS Sales Screen
After=network.target Weston.service

[Service]
Type=simple
Environment=QT_QPA_PLATFORM=eglfs
Environment=QT_QPA_EGLFS_KMS_ATOMIC=1
WorkingDirectory=/opt/antigravity
ExecStart=/usr/bin/python3 app/main.py
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
ln -sf /etc/systemd/system/antigravity.service "${TARGET_DIR}/etc/systemd/system/multi-user.target.wants/antigravity.service"

# 4. Optimize for Fast Boot / Silent Boot
# Suppress kernel logs on console
sed -i 's/console=tty1/console=tty3 quiet loglevel=0/g' "${TARGET_DIR}/boot/cmdline.txt" || true

# 5. Read-only preparation: Move random seed to writable if needed
# (Systemd handles most of this, but ensure /var/log etc are tmpfs)

echo "Post-build optimization complete."
