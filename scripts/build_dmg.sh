#!/usr/bin/env bash
set -euo pipefail

# Determine repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

echo "=========================================="
echo " Building MacXP Distributable Disk Image  "
echo "=========================================="

# 1. Build application bundle first
echo "==> Building application bundle..."
bash "${SCRIPT_DIR}/build_app.sh"

APP_PATH="build/MacXP.app"
if [[ ! -d "${APP_PATH}" ]]; then
    echo "Error: Application bundle not found at ${APP_PATH}" >&2
    exit 1
fi

STAGING_DIR="build/dmg_staging"
DMG_PATH="build/MacXP.dmg"

echo "==> Preparing DMG staging directory at ${STAGING_DIR}..."
rm -rf "${STAGING_DIR}"
rm -f "${DMG_PATH}"
mkdir -p "${STAGING_DIR}"

# Copy MacXP.app into staging
echo "==> Copying MacXP.app into staging..."
cp -R "${APP_PATH}" "${STAGING_DIR}/"

# Create symlink to Applications
echo "==> Creating /Applications symlink..."
ln -s /Applications "${STAGING_DIR}/Applications"

# Create DMG with hdiutil
echo "==> Creating compressed disk image (.dmg)..."
hdiutil create \
    -volname "MacXP" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Clean up staging
echo "==> Cleaning up staging files..."
rm -rf "${STAGING_DIR}"

if [[ -f "${DMG_PATH}" ]]; then
    DMG_SIZE="$(du -h "${DMG_PATH}" | awk '{print $1}')"
    echo "=========================================="
    echo " DMG created successfully!"
    echo " File: ${DMG_PATH} (${DMG_SIZE})"
    echo "=========================================="
else
    echo "Error: Failed to create ${DMG_PATH}" >&2
    exit 1
fi
