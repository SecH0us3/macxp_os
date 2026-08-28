#!/usr/bin/env bash
set -euo pipefail

# Determine repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

echo "=========================================="
echo " Building MacXP Release Application Bundle"
echo "=========================================="

# Build release binary
echo "==> Compiling Swift package in release mode..."
swift build -c release

# Locate release binary
BIN_PATH="$(swift build -c release --show-bin-path)/MacXP"

if [[ ! -f "${BIN_PATH}" ]]; then
    # Fallback search if show-bin-path differed
    if [[ -f ".build/release/MacXP" ]]; then
        BIN_PATH=".build/release/MacXP"
    elif [[ -f ".build/arm64-apple-macosx/release/MacXP" ]]; then
        BIN_PATH=".build/arm64-apple-macosx/release/MacXP"
    elif [[ -f ".build/x86_64-apple-macosx/release/MacXP" ]]; then
        BIN_PATH=".build/x86_64-apple-macosx/release/MacXP"
    else
        echo "Error: Could not locate compiled MacXP binary." >&2
        exit 1
    fi
fi

APP_DIR="build/MacXP.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Creating application bundle structure at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
echo "==> Copying binary..."
cp "${BIN_PATH}" "${MACOS_DIR}/MacXP"
chmod +x "${MACOS_DIR}/MacXP"

# Copy Info.plist
if [[ -f "Resources/Info.plist" ]]; then
    echo "==> Copying Info.plist..."
    cp "Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
else
    echo "Warning: Resources/Info.plist not found, generating default..."
    cat << 'EOF' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MacXP</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.macxp.os</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>MacXP</string>
    <key>CFBundleDisplayName</key>
    <string>MacXP</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF
fi

# PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Copy all Resources (Bliss wallpaper, Windows flags, AppIcon, etc.)
if [[ -d "Resources" ]]; then
    echo "==> Copying all assets from Resources/ to bundle..."
    cp -R Resources/* "${RESOURCES_DIR}/" || true
fi

# Copy or generate AppIcon.icns
if [[ -f "Resources/AppIcon.icns" ]]; then
    echo "==> Copying AppIcon.icns..."
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
elif [[ -f "scripts/generate_icon.swift" ]]; then
    echo "==> Generating AppIcon.icns..."
    swift scripts/generate_icon.swift
    if [[ -f "Resources/AppIcon.icns" ]]; then
        cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
    fi
fi

# Code sign bundle ad-hoc
if command -v codesign &>/dev/null; then
    echo "==> Applying ad-hoc code signature..."
    codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || true
fi

echo "==> Build complete: ${APP_DIR}"
