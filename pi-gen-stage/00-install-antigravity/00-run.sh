#!/bin/bash -e

APP_DIR="${ROOTFS_DIR}/opt/antigravity"
mkdir -p "${APP_DIR}"

# The GITHUB_REF_NAME contains the tag (e.g., v1.2)
TAG="${GITHUB_REF_NAME}"
REPO="${GITHUB_REPOSITORY}"

echo "Downloading release ${TAG} from ${REPO}..."
curl -L --fail "https://github.com/${REPO}/releases/download/${TAG}/antigravity_pos_${TAG}_app.zip" -o "${ROOTFS_DIR}/tmp/app.zip"

unzip -o "${ROOTFS_DIR}/tmp/app.zip" -d "${APP_DIR}"
rm -f "${ROOTFS_DIR}/tmp/app.zip"
