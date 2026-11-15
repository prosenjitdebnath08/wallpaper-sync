#!/bin/bash
set -e

clear
echo "=========================================================="
echo "    Wallpaper Sync - 1-Click Mac Installer"
echo "=========================================================="
echo ""

APP_DIR="$HOME/.wallpapersync"
mkdir -p "$APP_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SWIFT_FILE="$SCRIPT_DIR/macos_agent/universal_sync.swift"

if [ ! -f "$SWIFT_FILE" ]; then
    echo "Error: Could not locate universal_sync.swift at $SWIFT_FILE"
    echo "Please make sure you unzipped the complete WallpaperSync package."
    exit 1
fi

echo "1/3. Compiling background sync service for your Mac..."
/usr/bin/swiftc -O "$SWIFT_FILE" -o "$APP_DIR/wallpaper_agent"

echo "2/3. Setting up 24/7 background service..."
PLIST_PATH="$HOME/Library/LaunchAgents/com.wallpapersync.agent.plist"
mkdir -p "$HOME/Library/LaunchAgents"

cat << EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.wallpapersync.agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_DIR/wallpaper_agent</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/wallpapersync.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/wallpapersync.err</string>
</dict>
</plist>
EOF

echo "3/3. Activating Wallpaper Sync..."
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo ""
echo "=========================================================="
echo "    ✓ Installation Successful!"
echo "    Wallpaper Sync is now running in the background."
echo ""
echo "    Whenever you change a wallpaper on your phone,"
echo "    your Mac desktop will update automatically in 3s!"
echo "=========================================================="
echo ""
read -p "Press [Enter] to close this window..."
