#!/bin/bash
# Restore MoonlitApp to KSPlayer after MPV build
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Restoring KSPlayer build ==="

# Restore KSPlayer files from git
git checkout -- Sources/Components/KSPlayerEngine.swift Sources/Components/KSPlayerViewRepresentable.swift 2>/dev/null || true

# Remove MPV source files
rm -f Sources/Components/MPVPlayerEngine.swift
rm -f Sources/Components/MPVPlayerViewRepresentable.swift

# Restore PlayerScreen
git checkout -- Sources/Screens/PlayerScreen.swift 2>/dev/null || true
rm -f Sources/Screens/PlayerScreen.swift.mpv-backup

# Regenerate project
xcodegen generate
echo "Project restored - ready for KSPlayer build"
