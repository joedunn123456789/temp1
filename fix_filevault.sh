#!/bin/bash

################################################################################
# FileVault Fix Script for macOS
# Purpose: Automate common FileVault issue resolution
# - Secure token management
# - Recovery key restoration
# - Preboot volume repair
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (sudo)"
        exit 1
    fi
}

# Get the current user (who invoked sudo)
get_real_user() {
    if [[ -n "$SUDO_USER" ]]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

# Check if FileVault is enabled
check_filevault_status() {
    log "Checking FileVault status..."
    local fv_status=$(fdesetup status)
    echo "$fv_status"

    if echo "$fv_status" | grep -q "FileVault is Off"; then
        warning "FileVault is currently disabled"
        return 1
    else
        success "FileVault is enabled"
        return 0
    fi
}

# Check secure token status for a user
check_secure_token() {
    local username=$1
    log "Checking secure token for user: $username"

    local token_status=$(sysadminctl -secureTokenStatus "$username" 2>&1)
    echo "$token_status"

    if echo "$token_status" | grep -q "ENABLED"; then
        success "Secure token is enabled for $username"
        return 0
    else
        warning "Secure token is NOT enabled for $username"
        return 1
    fi
}

# Grant secure token to a user
grant_secure_token() {
    local target_user=$1
    local admin_user=$2

    log "Attempting to grant secure token to $target_user..."

    echo ""
    echo "Please enter the password for the admin user ($admin_user) who has a secure token:"
    read -s admin_password
    echo ""

    echo "Please enter the password for the target user ($target_user):"
    read -s target_password
    echo ""

    sysadminctl -secureTokenOn "$target_user" -password "$target_password" \
        -adminUser "$admin_user" -adminPassword "$admin_password"

    if [[ $? -eq 0 ]]; then
        success "Secure token granted to $target_user"
        return 0
    else
        error "Failed to grant secure token to $target_user"
        return 1
    fi
}

# List all FileVault enabled users
list_filevault_users() {
    log "Listing FileVault enabled users..."
    fdesetup list
}

# Check recovery key status
check_recovery_key() {
    log "Checking recovery key status..."

    local recovery_status=$(fdesetup hasinstitutionalrecoverykey 2>&1)
    if [[ $? -eq 0 ]]; then
        success "Institutional recovery key is present"
        return 0
    else
        warning "No institutional recovery key found"
        return 1
    fi
}

# Generate new personal recovery key
generate_recovery_key() {
    log "Generating new personal recovery key..."

    local output_file="/private/tmp/recovery_key_$(date +%s).plist"

    fdesetup changerecovery -personal -outputplist > "$output_file"

    if [[ $? -eq 0 ]]; then
        success "Recovery key generated and saved to: $output_file"

        # Extract and display the recovery key
        local recovery_key=$(defaults read "$output_file" RecoveryKey 2>/dev/null)
        if [[ -n "$recovery_key" ]]; then
            echo ""
            echo "=========================================="
            echo "RECOVERY KEY: $recovery_key"
            echo "=========================================="
            echo "SAVE THIS KEY IN A SECURE LOCATION!"
            echo ""
        fi

        chmod 600 "$output_file"
        return 0
    else
        error "Failed to generate recovery key"
        return 1
    fi
}

# Repair preboot volume
repair_preboot() {
    log "Repairing preboot volume..."

    # Get the boot volume
    local boot_volume=$(diskutil info / | grep "Device Node:" | awk '{print $3}')
    log "Boot volume device: $boot_volume"

    # Get the container
    local container=$(diskutil apfs list | grep -B5 "$boot_volume" | grep "APFS Container" | head -1 | awk '{print $4}')
    log "APFS Container: $container"

    if [[ -z "$container" ]]; then
        error "Could not determine APFS container"
        return 1
    fi

    # Update preboot
    log "Updating preboot volume..."
    diskutil apfs updatePreboot "$boot_volume"

    if [[ $? -eq 0 ]]; then
        success "Preboot volume updated successfully"
        return 0
    else
        error "Failed to update preboot volume"
        return 1
    fi
}

# Rebuild preboot (more aggressive)
rebuild_preboot() {
    log "Rebuilding preboot volume (this may take a few minutes)..."

    local boot_volume=$(diskutil info / | grep "Volume Name:" | awk '{print $3}')

    # This requires the system to have an authenticated restart capability
    diskutil apfs updatePreboot -force /

    if [[ $? -eq 0 ]]; then
        success "Preboot volume rebuilt successfully"
        return 0
    else
        error "Failed to rebuild preboot volume"
        return 1
    fi
}

# Verify and repair APFS volume
verify_apfs_volume() {
    log "Verifying APFS volume..."

    diskutil verifyVolume /

    if [[ $? -eq 0 ]]; then
        success "APFS volume verification passed"
        return 0
    else
        warning "APFS volume verification found issues, attempting repair..."
        diskutil repairVolume /
        return $?
    fi
}

# Pull FileVault system logs
pull_filevault_logs() {
    local time_period=${1:-"1h"}
    local output_file="/tmp/filevault_logs_$(date +%s).txt"

    log "Pulling FileVault system logs from the last $time_period..."
    echo ""

    {
        echo "=========================================="
        echo "FileVault System Logs"
        echo "Generated: $(date)"
        echo "Time Period: Last $time_period"
        echo "=========================================="
        echo ""

        echo "--- FileVault Subsystem Logs ---"
        log show --predicate 'subsystem == "com.apple.filevault"' --last "$time_period" --style syslog 2>/dev/null || echo "No FileVault subsystem logs found"
        echo ""

        echo "--- fdesetup Process Logs ---"
        log show --predicate 'process == "fdesetup"' --last "$time_period" --style syslog 2>/dev/null || echo "No fdesetup logs found"
        echo ""

        echo "--- securityd Logs (FileVault related) ---"
        log show --predicate 'process == "securityd" AND eventMessage CONTAINS "FileVault"' --last "$time_period" --style syslog 2>/dev/null || echo "No securityd FileVault logs found"
        echo ""

        echo "--- Disk Management Logs ---"
        log show --predicate 'process == "diskmanagementd"' --last "$time_period" --style syslog 2>/dev/null || echo "No disk management logs found"
        echo ""

        echo "--- Secure Token Logs ---"
        log show --predicate 'eventMessage CONTAINS "SecureToken"' --last "$time_period" --style syslog 2>/dev/null || echo "No secure token logs found"
        echo ""

        echo "--- APFS Preboot Logs ---"
        log show --predicate 'eventMessage CONTAINS "preboot"' --last "$time_period" --style syslog 2>/dev/null || echo "No preboot logs found"
        echo ""

    } | tee "$output_file"

    success "Logs saved to: $output_file"
    return 0
}

# Pull specific error logs
pull_error_logs() {
    local time_period=${1:-"24h"}

    log "Pulling FileVault error logs from the last $time_period..."
    echo ""

    echo "--- FileVault Errors ---"
    log show --predicate 'subsystem == "com.apple.filevault" AND messageType == "Error"' --last "$time_period" --style syslog 2>/dev/null || echo "No FileVault errors found"
    echo ""

    echo "--- fdesetup Errors ---"
    log show --predicate 'process == "fdesetup" AND messageType == "Error"' --last "$time_period" --style syslog 2>/dev/null || echo "No fdesetup errors found"
    echo ""

    echo "--- Secure Token Errors ---"
    log show --predicate 'eventMessage CONTAINS "SecureToken" AND messageType == "Error"' --last "$time_period" --style syslog 2>/dev/null || echo "No secure token errors found"
    echo ""

    success "Error log retrieval complete"
}

# Main menu
show_menu() {
    echo ""
    echo "=========================================="
    echo "    FileVault Fix Utility"
    echo "=========================================="
    echo "1. Check FileVault status"
    echo "2. Check secure token status"
    echo "3. Grant secure token to user"
    echo "4. List FileVault enabled users"
    echo "5. Check recovery key status"
    echo "6. Generate new recovery key"
    echo "7. Repair preboot volume"
    echo "8. Rebuild preboot volume (aggressive)"
    echo "9. Verify/Repair APFS volume"
    echo "10. Run full diagnostic"
    echo "11. Run full repair (all fixes)"
    echo "12. Pull FileVault system logs"
    echo "13. Pull FileVault error logs only"
    echo "0. Exit"
    echo "=========================================="
    echo -n "Select an option: "
}

# Full diagnostic
full_diagnostic() {
    log "Running full FileVault diagnostic..."
    echo ""

    check_filevault_status
    echo ""

    list_filevault_users
    echo ""

    local current_user=$(get_real_user)
    check_secure_token "$current_user"
    echo ""

    check_recovery_key
    echo ""

    verify_apfs_volume
    echo ""

    success "Diagnostic complete"
}

# Full repair
full_repair() {
    log "Running full FileVault repair..."
    echo ""

    warning "This will attempt all repair operations"
    echo -n "Continue? (yes/no): "
    read confirm

    if [[ "$confirm" != "yes" ]]; then
        warning "Repair cancelled"
        return 1
    fi

    # Repair APFS volume
    verify_apfs_volume
    echo ""

    # Repair preboot
    repair_preboot
    echo ""

    # Check if user needs secure token
    local current_user=$(get_real_user)
    if ! check_secure_token "$current_user"; then
        echo ""
        warning "User $current_user does not have a secure token"
        echo -n "Would you like to grant secure token? (yes/no): "
        read grant_token

        if [[ "$grant_token" == "yes" ]]; then
            echo -n "Enter the username of an admin with secure token: "
            read admin_user
            grant_secure_token "$current_user" "$admin_user"
        fi
    fi

    echo ""
    success "Full repair complete"
}

# Main script execution
main() {
    check_root

    if [[ $# -eq 0 ]]; then
        # Interactive mode
        while true; do
            show_menu
            read choice

            case $choice in
                1)
                    check_filevault_status
                    ;;
                2)
                    echo -n "Enter username to check: "
                    read username
                    check_secure_token "$username"
                    ;;
                3)
                    echo -n "Enter target username: "
                    read target_user
                    echo -n "Enter admin username (with secure token): "
                    read admin_user
                    grant_secure_token "$target_user" "$admin_user"
                    ;;
                4)
                    list_filevault_users
                    ;;
                5)
                    check_recovery_key
                    ;;
                6)
                    generate_recovery_key
                    ;;
                7)
                    repair_preboot
                    ;;
                8)
                    rebuild_preboot
                    ;;
                9)
                    verify_apfs_volume
                    ;;
                10)
                    full_diagnostic
                    ;;
                11)
                    full_repair
                    ;;
                12)
                    echo -n "Enter time period (1h, 24h, 7d, etc.) [default: 1h]: "
                    read time_period
                    time_period=${time_period:-1h}
                    pull_filevault_logs "$time_period"
                    ;;
                13)
                    echo -n "Enter time period (1h, 24h, 7d, etc.) [default: 24h]: "
                    read time_period
                    time_period=${time_period:-24h}
                    pull_error_logs "$time_period"
                    ;;
                0)
                    log "Exiting..."
                    exit 0
                    ;;
                *)
                    error "Invalid option"
                    ;;
            esac

            echo ""
            echo -n "Press Enter to continue..."
            read
        done
    else
        # Command-line mode
        case "$1" in
            --diagnostic)
                full_diagnostic
                ;;
            --repair)
                full_repair
                ;;
            --check-token)
                if [[ -n "$2" ]]; then
                    check_secure_token "$2"
                else
                    check_secure_token "$(get_real_user)"
                fi
                ;;
            --grant-token)
                if [[ -n "$2" ]] && [[ -n "$3" ]]; then
                    grant_secure_token "$2" "$3"
                else
                    error "Usage: $0 --grant-token <target_user> <admin_user>"
                    exit 1
                fi
                ;;
            --repair-preboot)
                repair_preboot
                ;;
            --generate-key)
                generate_recovery_key
                ;;
            --pull-logs)
                time_period=${2:-"1h"}
                pull_filevault_logs "$time_period"
                ;;
            --pull-errors)
                time_period=${2:-"24h"}
                pull_error_logs "$time_period"
                ;;
            --help)
                echo "Usage: $0 [option]"
                echo ""
                echo "Options:"
                echo "  --diagnostic              Run full diagnostic"
                echo "  --repair                  Run full repair"
                echo "  --check-token [user]      Check secure token for user"
                echo "  --grant-token <user> <admin>  Grant secure token to user"
                echo "  --repair-preboot          Repair preboot volume"
                echo "  --generate-key            Generate new recovery key"
                echo "  --pull-logs [time]        Pull FileVault system logs (default: 1h)"
                echo "  --pull-errors [time]      Pull FileVault error logs (default: 24h)"
                echo "  --help                    Show this help"
                echo ""
                echo "Time period examples: 1h, 24h, 7d, 30d"
                echo "Run without arguments for interactive mode"
                ;;
            *)
                error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    fi
}

main "$@"
