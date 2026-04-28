#!/bin/sh

set -u
set -e

# ── Arguments ──────────────────────────────────────────────
# Buildroot calls this script as: post-build.sh <TARGET_DIR>
TARGET_DIR="$1"

# ── Resolve Project Root ────────────────────────────────────
# This script lives at: <project_root>/buildroot/board/antigravity/post-build.sh
# During Buildroot's make, the CWD is the Buildroot SOURCE dir (buildroot_src/).
# The project root is therefore its parent: $(pwd)/..
# We use the script's own path for a reliable reference.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# SCRIPT_DIR = <project_root>/buildroot/board/antigravity
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "==> post-build.sh: PROJECT_ROOT=${PROJECT_ROOT}"
echo "==> post-build.sh: TARGET_DIR=${TARGET_DIR}"

# ── 1. Copy Application Files ──────────────────────────────
APP_DEST="${TARGET_DIR}/opt/antigravity"
mkdir -p "${APP_DEST}"

for dir in app ui assets; do
    SRC="${PROJECT_ROOT}/${dir}"
    if [ -d "${SRC}" ]; then
        echo "    Copying ${dir}/ → ${APP_DEST}/${dir}"
        cp -r "${SRC}" "${APP_DEST}/"
    else
        echo "WARNING: ${SRC} not found — skipping"
    fi
done

# Copy main.py entry point
cp "${PROJECT_ROOT}/main.py" "${APP_DEST}/main.py"

# Copy requirements for pip install below
cp "${PROJECT_ROOT}/requirements.txt" "${APP_DEST}/requirements.txt"

# ── 2. Install Python Packages via pip ─────────────────────
# PySide6 is not a Buildroot package, so we install it cross-py via pip.
# We need to install into the TARGET sysroot's Python.
# Use --target to install into the target's site-packages.
PYTHON_TARGET="${TARGET_DIR}/usr/lib/python3"
# Find the actual python3.x dir
SITE_PKG=$(find "${TARGET_DIR}/usr/lib" -maxdepth 2 -name "site-packages" 2>/dev/null | head -1)

if [ -n "${SITE_PKG}" ]; then
    echo "==> Installing Python packages into ${SITE_PKG}..."
    pip3 install \
        --target="${SITE_PKG}" \
        --no-deps \
        --platform linux_aarch64 \
        --only-binary=:all: \
        -r "${APP_DEST}/requirements.txt" || {
        echo "WARNING: pip install failed — PySide6 wheels for aarch64 may not be available."
        echo "         The app will not work without PySide6. Consider using a Pi 4 build server."
    }
else
    echo "WARNING: Could not find site-packages in target. Skipping pip install."
fi

# ── 3. Create /db mount point (writable partition) ─────────
mkdir -p "${TARGET_DIR}/db"

# ── 4. Create Systemd Service ──────────────────────────────
SYSTEMD_DIR="${TARGET_DIR}/etc/systemd/system"
mkdir -p "${SYSTEMD_DIR}/multi-user.target.wants"

cat > "${SYSTEMD_DIR}/antigravity.service" << 'EOF'
[Unit]
Description=Antigravity POS System
After=network.target

[Service]
Type=simple
User=root
Environment=QT_QPA_PLATFORM=eglfs
Environment=QT_QPA_EGLFS_KMS_ATOMIC=1
Environment=QT_QUICK_CONTROLS_STYLE=Basic
Environment=PYTHONPATH=/opt/antigravity
WorkingDirectory=/opt/antigravity
ExecStart=/usr/bin/python3 /opt/antigravity/main.py
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable service
ln -sf /etc/systemd/system/antigravity.service \
       "${SYSTEMD_DIR}/multi-user.target.wants/antigravity.service"

echo "==> post-build.sh complete ✓"
