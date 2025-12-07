#!/bin/bash

# Check for available macOS and software updates
# Usage: ./software_update_check.sh

echo "=== macOS Software Update Check ==="
echo "Current OS: $(sw_vers -productVersion)"
echo "Build: $(sw_vers -buildVersion)"
echo ""

echo "Checking for available updates..."
softwareupdate --list

echo ""
echo "=== Homebrew Updates (if installed) ==="
if command -v brew &> /dev/null; then
    brew update
    brew outdated
else
    echo "Homebrew not installed"
fi

echo ""
echo "=== System Update History ==="
softwareupdate --history | tail -20
