#!/bin/bash -e

APP_DIR="${ROOTFS_DIR}/opt/antigravity"
mkdir -p "${APP_DIR}"

# The tag is injected by the GitHub Action before running pi-gen
TAG="THE_GITHUB_TAG"
REPO="a32116150-ctrl/ANTIGRAVITY-by-factarlou"

echo "Downloading release ${TAG} from ${REPO}..."
curl -L --fail "https://github.com/${REPO}/releases/download/${TAG}/antigravity_pos_${TAG}_app.zip" -o "${ROOTFS_DIR}/tmp/app.zip"


