#!/bin/bash
# Phase 3: Camera Realism Setup
# Configures virtual camera via v4l2loopback for Waydroid

set -e

echo "[Phase 3] Camera Realism Setup"
echo "==============================="

LXC_CONFIG="/var/lib/waydroid/lxc/waydroid/config_nodes"

# Check if v4l2loopback is available
if ! lsmod | grep -q v4l2loopback; then
    echo "[!] v4l2loopback not loaded. Installing and loading..."
    
    # Try to load the module
    if ! sudo modprobe v4l2loopback video_nr=10 card_label="Virtual Camera" exclusive_caps=1 2>/dev/null; then
        echo "[!] v4l2loopback not installed. Installing..."
        
        # Detect package manager
        if command -v dnf &>/dev/null; then
            sudo dnf install -y v4l2loopback
        elif command -v apt &>/dev/null; then
            sudo apt install -y v4l2loopback-dkms
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm v4l2loopback-dkms
        else
            echo "[✗] Cannot install v4l2loopback. Please install manually."
            exit 1
        fi
        
        sudo modprobe v4l2loopback video_nr=10 card_label="Virtual Camera" exclusive_caps=1
    fi
fi

echo "[+] v4l2loopback loaded"

# Find virtual camera device
VIRTUAL_CAM=$(v4l2-ctl --list-devices 2>/dev/null | grep -A1 "Virtual Camera" | tail -1 | xargs)
if [[ -z "$VIRTUAL_CAM" ]]; then
    VIRTUAL_CAM="/dev/video10"
fi

echo "[+] Virtual camera device: $VIRTUAL_CAM"

# Remove auto video device mappings from Waydroid LXC config
if [[ -f "$LXC_CONFIG" ]]; then
    sudo sed -i '/video/d' "$LXC_CONFIG"
    echo "[+] Removed auto video mappings from LXC config"
fi

# Add manual camera binding
echo "lxc.mount.entry = $VIRTUAL_CAM dev/video0 none bind,create=file,optional 0 0" | sudo tee -a "$LXC_CONFIG" >/dev/null
echo "[+] Added virtual camera binding to LXC config"

# Create udev rule for persistent device
UDEV_RULE="/etc/udev/rules.d/99-waydroid-camera.rules"
echo 'KERNEL=="video10", SYMLINK+="waydroid_cam", MODE="0666"' | sudo tee "$UDEV_RULE" >/dev/null
sudo udevadm control --reload-rules
echo "[+] Created udev rule for camera persistence"

# Create modprobe config for auto-load
echo "options v4l2loopback video_nr=10 card_label=\"Virtual Camera\" exclusive_caps=1" | sudo tee /etc/modprobe.d/v4l2loopback.conf >/dev/null
echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf >/dev/null
echo "[+] Configured v4l2loopback for auto-load on boot"

echo ""
echo "[*] OBS Virtual Camera Setup:"
echo "    1. Open OBS Studio"
echo "    2. Start Virtual Camera (Tools > Start Virtual Camera)"
echo "    3. OBS will output to $VIRTUAL_CAM"
echo "    4. Waydroid will see it as /dev/video0"
echo ""
echo "[✓] Phase 3 complete"
