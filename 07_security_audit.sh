#!/bin/bash

# Security audit script for macOS
# Usage: ./security_audit.sh

echo "=== macOS Security Audit ==="
echo "Date: $(date)"
echo ""

echo "=== Firewall Status ==="
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
echo ""

echo "=== FileVault Status ==="
fdesetup status
echo ""

echo "=== Gatekeeper Status ==="
spctl --status
echo ""

echo "=== System Integrity Protection (SIP) ==="
csrutil status
echo ""

echo "=== Failed Login Attempts ==="
sudo log show --predicate 'eventMessage contains "Authentication failed"' --last 1d | tail -10
echo ""

echo "=== Admin Users ==="
dscl . -read /Groups/admin GroupMembership
echo ""

echo "=== Users with Sudo Access ==="
sudo dscl . -read /Groups/admin | grep GroupMembership
echo ""

echo "=== Recently Modified System Files ==="
sudo find /System /Library -type f -mtime -1 2>/dev/null | head -10
echo ""

echo "=== SSH Configuration ==="
if [ -f /etc/ssh/sshd_config ]; then
    echo "SSH is configured"
    sudo systemsetup -getremotelogin
else
    echo "SSH config not found"
fi
echo ""

echo "=== Open Ports ==="
sudo lsof -iTCP -sTCP:LISTEN -n -P | head -15
