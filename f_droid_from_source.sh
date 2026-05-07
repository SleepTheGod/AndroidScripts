#!/usr/bin/env bash
#
# f-build — Build & deploy F‑Droid from source
#   Non‑root friendly, but root required for Privileged Extension.
#   Run on Linux, macOS, or Windows (WSL2) with Bash.
#
set -euo pipefail

# ------------------------------ Colors ------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --------------------------- Configuration ---------------------------
FDROID_REPO="https://gitlab.com/fdroid/fdroidclient.git"
PRIVEXT_REPO="https://gitlab.com/fdroid/privileged-extension.git"
FDROID_DIR="fdroidclient"
PRIVEXT_DIR="privileged-extension"
BUILD_VARIANT="assembleRelease"       # or assembleDebug for quick test
SOURCE_DEPS="false"                   # Set to "true" for fully source-built
INSTALL_WITH_ADB="true"               # Will attempt ADB install if available

# --------------------------- Helper Functions ---------------------------
msg_info()  { echo -e "${BLUE}[*]${NC} $*"; }
msg_ok()    { echo -e "${GREEN}[+]${NC} $*"; }
msg_warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
msg_err()   { echo -e "${RED}[!]${NC} $*"; }

check_command() {
    if ! command -v "$1" &>/dev/null; then
        msg_err "$1 is required but not installed."
        exit 1
    fi
}

check_adb_device() {
    if ! adb get-state 1>/dev/null 2>&1; then
        msg_warn "No ADB device detected. APK will not be installed automatically."
        return 1
    fi
    return 0
}

# --------------------------- Main Script ---------------------------
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}   F‑Droid Source Builder & Installer${NC}"
echo -e "${BLUE}=========================================${NC}"

# 1. Prerequisites check
msg_info "Checking prerequisites..."
check_command git
check_command java
# Check Java version (17+)
JAVA_VER=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VER" -lt 17 ]; then
    msg_err "Java 17 or later is required. Found version $JAVA_VER."
    exit 1
fi

# Android SDK / ANDROID_HOME
if [ -z "${ANDROID_HOME:-}" ]; then
    # Try to guess common locations
    if [ -d "$HOME/Android/Sdk" ]; then
        export ANDROID_HOME="$HOME/Android/Sdk"
    elif [ -d "$HOME/Android" ]; then
        export ANDROID_HOME="$HOME/Android"
    elif [ -d "$HOME/Library/Android/sdk" ]; then
        export ANDROID_HOME="$HOME/Library/Android/sdk"
    else
        msg_err "ANDROID_HOME is not set and cannot be guessed."
        msg_err "Please set it to your Android SDK location, e.g.:"
        msg_err "  export ANDROID_HOME=~/Android/Sdk"
        exit 1
    fi
fi
msg_ok "ANDROID_HOME = $ANDROID_HOME"

# ADB optional
if command -v adb &>/dev/null; then
    msg_ok "ADB found – will attempt to install APK after build."
else
    msg_warn "ADB not found. APK will only be built, not installed."
    INSTALL_WITH_ADB="false"
fi

# 2. Clone F‑Droid client if needed
if [ ! -d "$FDROID_DIR" ]; then
    msg_info "Cloning F‑Droid client repository..."
    git clone "$FDROID_REPO" "$FDROID_DIR"
else
    msg_ok "F‑Droid source directory already exists. Pulling latest changes..."
    cd "$FDROID_DIR"
    git pull origin master
    cd ..
fi

# 3. Build F‑Droid client
msg_info "Building F‑Droid client APK..."
cd "$FDROID_DIR"

GRADLEW="./gradlew"
if [ ! -f "$GRADLEW" ]; then
    msg_err "gradlew not found inside $FDROID_DIR. Something is wrong."
    exit 1
fi

# Ensure gradlew is executable
chmod +x "$GRADLEW"

if [ "$SOURCE_DEPS" = "true" ]; then
    msg_info "Building with source dependencies (may take much longer)..."
    "$GRADLEW" "$BUILD_VARIANT" -PsourceDeps
else
    "$GRADLEW" "$BUILD_VARIANT"
fi

cd ..

APK_PATH="$FDROID_DIR/app/build/outputs/apk/release/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    msg_err "Build failed – APK not found at: $APK_PATH"
    exit 1
fi
msg_ok "F‑Droid APK built successfully: $APK_PATH"

# 4. Install via ADB (if desired and available)
if [ "$INSTALL_WITH_ADB" = "true" ]; then
    if check_adb_device; then
        msg_info "Installing F‑Droid on connected device..."
        # Uninstall any previous official version (package name org.fdroid.fdroid)
        adb uninstall org.fdroid.fdroid 2>/dev/null || true
        adb install "$APK_PATH"
        msg_ok "F‑Droid installed. Launch it from the app drawer."
    fi
else
    msg_info "To install manually, transfer the APK to your device and open it."
    msg_info "APK location: $APK_PATH"
fi

# 5. Optional: Privileged Extension (root only)
echo -n "Do you want to build and install the Privileged Extension? (requires root) [y/N]: "
read -r priv_choice
if [[ "$priv_choice" =~ ^[Yy]$ ]]; then
    msg_warn "Proceeding with Privileged Extension (root required)."
    if [ ! -d "$PRIVEXT_DIR" ]; then
        msg_info "Cloning Privileged Extension repository..."
        git clone "$PRIVEXT_REPO" "$PRIVEXT_DIR"
    fi
    cd "$PRIVEXT_DIR"
    chmod +x ./gradlew
    msg_info "Building extension APK..."
    ./gradlew assembleRelease
    EXT_APK="app/build/outputs/apk/release/app-release.apk"
    if [ ! -f "$EXT_APK" ]; then
        msg_err "Extension build failed – APK not found."
        exit 1
    fi
    msg_ok "Extension APK built."
    if check_adb_device; then
        msg_info "Pushing extension to device..."
        adb push "$EXT_APK" /sdcard/fdroid-privileged.apk
        msg_warn "Now you must manually move it to /system/priv-app/ with root access."
        echo "Run:"
        echo "  adb shell"
        echo "  su"
        echo "  mount -o rw,remount /system"
        echo "  cp /sdcard/fdroid-privileged.apk /system/priv-app/org.fdroid.fdroid.privileged/"
        echo "  chmod 644 /system/priv-app/org.fdroid.fdroid.privileged/*.apk"
        echo "  reboot"
    fi
    cd ..
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}   F‑Droid build & deployment completed.${NC}"
echo -e "${BLUE}=========================================${NC}"
