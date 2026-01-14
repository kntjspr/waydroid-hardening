#!/bin/bash
# Phase 4: Filesystem Keyword Elimination
# Removes waydroid/lxc/container strings from visible paths

set -e

echo "[Phase 4] Filesystem Keyword Elimination"
echo "========================================="

WAYDROID_DIR="/var/lib/waydroid"
NEUTRAL_DIR="/var/lib/wd"

# Check if already migrated
if [[ -L "$WAYDROID_DIR" ]] || mountpoint -q "$WAYDROID_DIR" 2>/dev/null; then
    echo "[*] Filesystem already neutralized"
    echo "[✓] Phase 4 complete (no changes needed)"
    exit 0
fi

# Stop Waydroid if running
if waydroid status 2>/dev/null | grep -q "Session"; then
    echo "[*] Stopping Waydroid session..."
    waydroid session stop
    sleep 2
fi

if sudo lxc-info -n waydroid 2>/dev/null | grep -q "RUNNING"; then
    echo "[*] Stopping Waydroid container..."
    sudo waydroid container stop
    sleep 2
fi

# Move to neutral location
if [[ -d "$WAYDROID_DIR" ]] && [[ ! -d "$NEUTRAL_DIR" ]]; then
    echo "[*] Moving Waydroid data to neutral path..."
    sudo mv "$WAYDROID_DIR" "$NEUTRAL_DIR"
    echo "[+] Moved to $NEUTRAL_DIR"
fi

# Create mount point and bind mount
sudo mkdir -p "$WAYDROID_DIR"
sudo mount --bind "$NEUTRAL_DIR" "$WAYDROID_DIR"
echo "[+] Created bind mount: $NEUTRAL_DIR -> $WAYDROID_DIR"

# Add to fstab for persistence
FSTAB_ENTRY="$NEUTRAL_DIR $WAYDROID_DIR none bind 0 0"
if ! grep -qF "$FSTAB_ENTRY" /etc/fstab; then
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab >/dev/null
    echo "[+] Added bind mount to /etc/fstab"
fi

# Verify
echo ""
echo "[*] Verification:"
if mountpoint -q "$WAYDROID_DIR"; then
    echo "    ✓ Bind mount active"
else
    echo "    ✗ Bind mount failed"
    exit 1
fi

echo ""
echo "[*] After starting Waydroid, verify with:"
echo "    adb shell grep -i waydroid /proc/self/mounts"
echo "    (should return empty)"
echo ""
echo "[✓] Phase 4 complete"
