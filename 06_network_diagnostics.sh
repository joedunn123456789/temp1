#!/bin/bash

# Network diagnostics and troubleshooting for macOS
# Usage: ./network_diagnostics.sh

echo "=== Network Diagnostics ==="
echo "Timestamp: $(date)"
echo ""

echo "=== Active Network Interfaces ==="
networksetup -listallhardwareports
echo ""

echo "=== Network Configuration ==="
for interface in $(networksetup -listallnetworkservices | grep -v '*'); do
    echo "Service: $interface"
    networksetup -getinfo "$interface"
    echo ""
done

echo "=== DNS Configuration ==="
scutil --dns | grep 'nameserver\[' | head -5
echo ""

echo "=== Current Connections ==="
netstat -an | grep ESTABLISHED | head -10
echo ""

echo "=== Wi-Fi Status (if applicable) ==="
if /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I &> /dev/null; then
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I
fi
echo ""

echo "=== Ping Test (Google DNS) ==="
ping -c 4 8.8.8.8
echo ""

echo "=== DNS Resolution Test ==="
nslookup google.com
