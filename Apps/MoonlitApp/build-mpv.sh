#!/bin/bash
# Build MoonlitApp with MPVKit instead of KSPlayer
# Usage: ./build-mpv.sh [device-id]
set -e

DEVICE_ID="${1:-00008130-000145483E21001C}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Building MoonlitApp with MPVKit ==="

# Step 1: Copy MPV source files into Sources, remove KSPlayer files
echo "Swapping player source files..."
cp _mpv_staging/MPVPlayerEngine.swift Sources/Components/
cp _mpv_staging/MPVPlayerViewRepresentable.swift Sources/Components/
cp _mpv_staging/MetalLayer.swift Sources/Components/
cp _mpv_staging/SubtitleCue.swift Sources/Components/   # defines SubtitleCue + SubtitleCueIndex (used by PlayerScreen)
rm -f Sources/Components/KSPlayerEngine.swift Sources/Components/KSPlayerViewRepresentable.swift
echo "Patching PlayerScreen..."
PLAYER_SCREEN="Sources/Screens/PlayerScreen.swift"
cp "$PLAYER_SCREEN" "$PLAYER_SCREEN.mpv-backup"
sed -i '' 's/@StateObject private var ksEngine = KSPlayerEngine()/@StateObject private var mpvEngine = MPVPlayerEngine()/' "$PLAYER_SCREEN"
sed -i '' 's/KSPlayerViewRepresentable/MPVPlayerViewRepresentable/g' "$PLAYER_SCREEN"
sed -i '' 's/ksEngine/mpvEngine/g' "$PLAYER_SCREEN"

# Step 3: Generate project with MPV config
echo "Generating Xcode project..."
xcodegen generate --spec project-mpv.yml

# Step 4: Build (separate DerivedData to avoid SPM conflict with KSPlayer/FFmpegKit)
echo "Building..."
DERIVED="/tmp/moonlit-mpv-$(date +%s)"
xcodebuild -project MoonlitApp.xcodeproj -scheme MoonlitApp \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  -derivedDataPath "$DERIVED" \
  build 2>&1 | tail -5

# Step 5: Find app and install
echo "Installing..."
APP_PATH="$DERIVED/Build/Products/Debug-iphoneos/MoonlitApp.app"
if [ -z "$APP_PATH" ]; then
    echo "ERROR: Could not find built .app"
    exit 1
fi
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo ""
echo "=== MPVKit build installed! ==="
echo "Run './restore-ksplayer.sh' to switch back to KSPlayer"
