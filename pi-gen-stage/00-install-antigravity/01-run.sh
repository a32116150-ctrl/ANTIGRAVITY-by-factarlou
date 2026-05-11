#!/bin/bash -e

APP_DIR="${ROOTFS_DIR}/opt/antigravity"
mkdir -p "${APP_DIR}"

# The tag is injected by the GitHub Action before running pi-gen
TAG="THE_GITHUB_TAG"
REPO="a32116150-ctrl/ANTIGRAVITY-by-factarlou"

echo "Copying app files into rootfs..."
cp -r files/* "${APP_DIR}/"
mkdir -p "${APP_DIR}/db"
chmod -R 755 "${APP_DIR}"

