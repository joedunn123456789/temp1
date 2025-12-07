#!/bin/bash

# Repair permissions and ownership issues on macOS
# Usage: ./permissions_repair.sh [username]

USERNAME=${1:-$(whoami)}

echo "=== macOS Permissions Repair Tool ==="
echo "Target User: $USERNAME"
echo ""

# Get user's home directory
USER_HOME=$(dscl . -read /Users/$USERNAME NFSHomeDirectory | awk '{print $2}')

if [ ! -d "$USER_HOME" ]; then
    echo "Error: Home directory not found for $USERNAME"
    exit 1
fi

echo "Repairing permissions for $USER_HOME..."

# Reset home directory permissions
sudo chown -R $USERNAME:staff "$USER_HOME"

# Fix common permission issues
echo "Fixing Desktop permissions..."
sudo chmod 700 "$USER_HOME/Desktop" 2>/dev/null

echo "Fixing Documents permissions..."
sudo chmod 700 "$USER_HOME/Documents" 2>/dev/null

echo "Fixing Downloads permissions..."
sudo chmod 755 "$USER_HOME/Downloads" 2>/dev/null

echo "Fixing Library permissions..."
sudo chmod 755 "$USER_HOME/Library" 2>/dev/null
sudo chown -R $USERNAME:staff "$USER_HOME/Library" 2>/dev/null

echo "Fixing Preferences permissions..."
sudo chmod -R 700 "$USER_HOME/Library/Preferences" 2>/dev/null

# Rebuild Launch Services database
echo "Rebuilding Launch Services database..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Clear caches
echo "Clearing system caches..."
sudo rm -rf /Library/Caches/*
rm -rf ~/Library/Caches/*

echo ""
echo "✓ Permissions repair completed for $USERNAME"
echo "Consider restarting the system for changes to take full effect."
