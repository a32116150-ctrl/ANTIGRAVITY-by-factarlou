#!/bin/bash

set -e

BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Copy custom config/cmdline to the images directory before genimage runs
cp "${BOARD_DIR}/config.txt" "${BINARIES_DIR}/rpi-firmware/"
cp "${BOARD_DIR}/cmdline.txt" "${BINARIES_DIR}/rpi-firmware/"

rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

exit $?
