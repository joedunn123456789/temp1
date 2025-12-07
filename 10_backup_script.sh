#!/bin/bash

# Time Machine and backup management script
# Usage: ./backup_script.sh [start|stop|status|destinations]

ACTION=${1:-status}

start_backup() {
    echo "Starting Time Machine backup..."
    tmutil startbackup
}

stop_backup() {
    echo "Stopping Time Machine backup..."
    tmutil stopbackup
}

show_status() {
    echo "=== Time Machine Status ==="
    tmutil status
    echo ""

    echo "=== Latest Backups ==="
    tmutil listbackups | tail -5
    echo ""

    echo "=== Backup Destination ==="
    tmutil destinationinfo
    echo ""

    echo "=== Excluded Items ==="
    sudo mdfind "com_apple_backup_excludeItem = 'com.apple.backupd'" | head -10
}

list_destinations() {
    echo "=== Time Machine Destinations ==="
    tmutil destinationinfo
}

create_manual_backup() {
    BACKUP_DIR="/tmp/manual_backup_$(date +%Y%m%d_%H%M%S)"
    echo "Creating manual backup to $BACKUP_DIR..."

    mkdir -p "$BACKUP_DIR"

    # Backup critical system information
    system_profiler > "$BACKUP_DIR/system_info.txt"
    sw_vers > "$BACKUP_DIR/os_version.txt"
    dscl . -list /Users > "$BACKUP_DIR/users_list.txt"

    # Backup network settings
    networksetup -listallhardwareports > "$BACKUP_DIR/network_config.txt"

    # Backup installed apps
    ls /Applications > "$BACKUP_DIR/installed_apps.txt"

    echo "Manual backup completed: $BACKUP_DIR"
}

case $ACTION in
    start)
        start_backup
        ;;
    stop)
        stop_backup
        ;;
    status)
        show_status
        ;;
    destinations)
        list_destinations
        ;;
    manual)
        create_manual_backup
        ;;
    *)
        echo "Usage: $0 [start|stop|status|destinations|manual]"
        exit 1
        ;;
esac
