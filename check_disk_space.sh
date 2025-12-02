#!/bin/bash

# Script to check disk drive space
# Displays disk usage information in a human-readable format

echo "==================================="
echo "Disk Drive Space Report"
echo "==================================="
echo ""

# Display disk usage for all mounted filesystems
df -h

echo ""
echo "==================================="
echo "Disk Usage Summary by Mount Point"
echo "==================================="
echo ""

# Display usage with percentage and highlight filesystems above 80% usage
df -h | awk 'NR==1 {print $0} NR>1 {
    usage = int($5)
    if (usage >= 80) {
        print $0 " <- WARNING: High usage!"
    } else {
        print $0
    }
}'

echo ""
echo "==================================="
echo "Largest Directories in Current Path"
echo "==================================="
echo ""

# Show top 10 largest directories in current location
du -sh * 2>/dev/null | sort -rh | head -10
