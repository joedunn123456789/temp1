#!/bin/bash

# Gather comprehensive system information for Mac inventory
# Usage: ./system_inventory.sh

echo "=== Mac System Inventory ==="
echo "Date: $(date)"
echo ""

echo "=== Hardware Information ==="
echo "Computer Name: $(scutil --get ComputerName)"
echo "Hostname: $(scutil --get HostName)"
echo "Serial Number: $(system_profiler SPHardwareDataType | awk '/Serial Number/ {print $4}')"
echo "Model: $(sysctl -n hw.model)"
echo "Processor: $(sysctl -n machdep.cpu.brand_string)"
echo "Memory: $(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 )) GB"
echo "Disk Size: $(diskutil info / | awk '/Disk Size/ {print $3, $4}')"
echo ""

echo "=== OS Information ==="
echo "macOS Version: $(sw_vers -productVersion)"
echo "Build: $(sw_vers -buildVersion)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime | awk '{print $3, $4}')"
echo ""

echo "=== Network Information ==="
echo "Primary IP: $(ipconfig getifaddr en0)"
echo "MAC Address: $(ifconfig en0 | awk '/ether/ {print $2}')"
echo "DNS Servers: $(scutil --dns | awk '/nameserver\[0\]/ {print $3}')"
echo ""

echo "=== User Accounts ==="
dscl . list /Users | grep -v '^_'
echo ""

echo "=== Installed Applications ==="
ls /Applications | head -10
echo "... (showing first 10)"
