#!/bin/bash

# Monitor disk space and alert if threshold exceeded
# Usage: ./check_disk_space.sh [threshold_percentage]

THRESHOLD=${1:-80}

echo "=== Disk Space Check ==="
echo "Alert Threshold: ${THRESHOLD}%"
echo ""

# Check all mounted volumes
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | while read line; do
    USAGE=$(echo $line | awk '{print $5}' | sed 's/%//')
    MOUNT=$(echo $line | awk '{print $9}')
    SIZE=$(echo $line | awk '{print $2}')
    USED=$(echo $line | awk '{print $3}')
    AVAIL=$(echo $line | awk '{print $4}')

    if [ "$USAGE" -ge "$THRESHOLD" ]; then
        echo "⚠️  WARNING: $MOUNT is at ${USAGE}% capacity"
        echo "   Size: $SIZE | Used: $USED | Available: $AVAIL"
        echo ""
    else
        echo "✓ $MOUNT is at ${USAGE}% (healthy)"
        echo "   Size: $SIZE | Used: $USED | Available: $AVAIL"
        echo ""
    fi
done

# Find large files (top 10)
echo "=== Top 10 Largest Files in /Users ==="
sudo find /Users -type f -size +100M -exec ls -lh {} \; 2>/dev/null | \
    awk '{print $5, $9}' | sort -hr | head -10
