#!/bin/bash

# Manage macOS services and launch agents
# Usage: ./manage_services.sh [list|start|stop|status] [service_name]

ACTION=$1
SERVICE=$2

list_services() {
    echo "=== System LaunchDaemons ==="
    sudo launchctl list | head -20

    echo ""
    echo "=== User LaunchAgents ==="
    launchctl list | head -20

    echo ""
    echo "=== Running Services ==="
    ps aux | grep -E '(launchd|daemon)' | head -10
}

start_service() {
    if [ -z "$SERVICE" ]; then
        echo "Error: Service name required"
        exit 1
    fi
    sudo launchctl load -w /Library/LaunchDaemons/$SERVICE.plist
    echo "Started $SERVICE"
}

stop_service() {
    if [ -z "$SERVICE" ]; then
        echo "Error: Service name required"
        exit 1
    fi
    sudo launchctl unload -w /Library/LaunchDaemons/$SERVICE.plist
    echo "Stopped $SERVICE"
}

status_service() {
    if [ -z "$SERVICE" ]; then
        echo "Error: Service name required"
        exit 1
    fi
    launchctl list | grep $SERVICE
}

case $ACTION in
    list)
        list_services
        ;;
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    status)
        status_service
        ;;
    *)
        echo "Usage: $0 [list|start|stop|status] [service_name]"
        exit 1
        ;;
esac
