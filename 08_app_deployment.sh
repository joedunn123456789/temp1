#!/bin/bash

# Deploy/Install applications on macOS
# Usage: ./app_deployment.sh [install|remove|list] [app_name]

ACTION=$1
APP=$2

install_app() {
    if [ -z "$APP" ]; then
        echo "Error: Application name required"
        exit 1
    fi

    # Check if it's a .dmg, .pkg, or .app
    if [[ "$APP" == *.dmg ]]; then
        echo "Installing from DMG: $APP"
        hdiutil attach "$APP"
        VOLUME=$(hdiutil info | grep /Volumes | tail -1 | awk '{print $3}')
        cp -R "${VOLUME}"/*.app /Applications/
        hdiutil detach "$VOLUME"
    elif [[ "$APP" == *.pkg ]]; then
        echo "Installing PKG: $APP"
        sudo installer -pkg "$APP" -target /
    else
        echo "Unsupported format. Please provide .dmg or .pkg file"
    fi
}

remove_app() {
    if [ -z "$APP" ]; then
        echo "Error: Application name required"
        exit 1
    fi

    if [ -d "/Applications/$APP.app" ]; then
        echo "Removing $APP..."
        sudo rm -rf "/Applications/$APP.app"
        echo "$APP removed successfully"
    else
        echo "Application not found: $APP"
    fi
}

list_apps() {
    echo "=== Installed Applications ==="
    ls -1 /Applications | grep .app
    echo ""
    echo "=== Recently Installed Apps (last 30 days) ==="
    find /Applications -name "*.app" -mtime -30 -maxdepth 1
}

case $ACTION in
    install)
        install_app
        ;;
    remove)
        remove_app
        ;;
    list)
        list_apps
        ;;
    *)
        echo "Usage: $0 [install|remove|list] [app_name/path]"
        exit 1
        ;;
esac
