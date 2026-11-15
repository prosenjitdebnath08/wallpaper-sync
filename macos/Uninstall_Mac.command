#!/bin/bash

clear
echo "=========================================================="
echo "    Wallpaper Sync - Mac Uninstaller"
echo "=========================================================="
echo ""

PLIST_PATH="$HOME/Library/LaunchAgents/com.wallpapersync.agent.plist"

echo "Stopping background service..."
launchctl unload "$PLIST_PATH" 2>/dev/null || true
rm -f "$PLIST_PATH"

echo "Removing application files..."
rm -rf "$HOME/.wallpapersync"

echo ""
echo "=========================================================="
echo "    ✓ Wallpaper Sync has been completely removed."
echo "=========================================================="
echo ""
read -p "Press [Enter] to close this window..."
