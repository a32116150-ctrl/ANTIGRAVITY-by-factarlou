#!/bin/bash -e

APP_DIR="${ROOTFS_DIR}/opt/antigravity"

echo "==> FILESDIR is: ${FILESDIR}"
echo "==> Contents:"
ls -la "${FILESDIR}" || echo "FILESDIR is empty or missing"

mkdir -p "${APP_DIR}"

if [ -d "${FILESDIR}/app" ]; then
    cp -r "${FILESDIR}/app" "${APP_DIR}/"
    cp -r "${FILESDIR}/ui" "${APP_DIR}/"
    cp "${FILESDIR}/main.py" "${APP_DIR}/"
    cp "${FILESDIR}/requirements.txt" "${APP_DIR}/"
else
    echo "ERROR: app not found in FILESDIR. Listing parent dirs..."
    ls -la "${FILESDIR}/../" || true
    ls -la "${FILESDIR}/../../" || true
    exit 1
fi

mkdir -p "${APP_DIR}/db"

install -m 644 /dev/stdin "${ROOTFS_DIR}/etc/systemd/system/antigravity.service" << 'SERVICE'
[Unit]
Description=Antigravity POS by factarlou
After=network.target

[Service]
Type=simple
User=pi
Environment=QT_QPA_PLATFORM=eglfs
Environment=PYTHONPATH=/opt/antigravity
WorkingDirectory=/opt/antigravity
ExecStart=/opt/antigravity/.venv/bin/python3 /opt/antigravity/main.py
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

on_chroot << 'CHROOT'
    if ! id "pi" &>/dev/null; then
        useradd -m -s /bin/bash pi
        echo "pi:raspberry" | chpasswd
        usermod -aG sudo,video,audio,input,bluetooth pi
    fi
    chown -R pi:pi /opt/antigravity
    python3 -m venv /opt/antigravity/.venv
    /opt/antigravity/.venv/bin/pip install --upgrade pip
    /opt/antigravity/.venv/bin/pip install -r /opt/antigravity/requirements.txt
    mkdir -p /etc/systemd/system/multi-user.target.wants
    ln -sf /etc/systemd/system/antigravity.service \
           /etc/systemd/system/multi-user.target.wants/antigravity.service
CHROOT
