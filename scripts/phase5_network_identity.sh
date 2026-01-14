#!/bin/bash
# Phase 5: Network Identity (Wi-Fi / MAC)
# Assigns vendor-valid MAC address to prevent detection

set -e

echo "[Phase 5] Network Identity Setup"
echo "================================="

INTERFACE="waydroid0"

# Google OUI prefixes (valid manufacturer codes)
GOOGLE_OUIS=(
    "3C:5A:B4"  # Google Inc.
    "94:EB:2C"  # Google Inc.
    "F4:F5:D8"  # Google Inc.
    "DC:56:E7"  # Google Inc.
)

# Samsung OUI prefixes (alternative)
SAMSUNG_OUIS=(
    "00:1A:8A"  # Samsung Electronics
    "34:C3:D2"  # Samsung Electronics
    "A0:82:1F"  # Samsung Electronics
)

# Generate random bytes for device-unique portion
generate_mac_suffix() {
    printf '%02X:%02X:%02X' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

# Pick random Google OUI
OUI="${GOOGLE_OUIS[$((RANDOM % ${#GOOGLE_OUIS[@]}))]}"
SUFFIX=$(generate_mac_suffix)
NEW_MAC="$OUI:$SUFFIX"

echo "[*] Generated MAC: $NEW_MAC (Google OUI)"

# Check if interface exists
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo "[!] Interface $INTERFACE not found"
    echo "[*] Waydroid may not be running. Start it first with: waydroid session start"
    echo ""
    echo "[*] Save this MAC for later use: $NEW_MAC"
    echo ""
    
    # Create systemd service for MAC assignment on Waydroid start
    SERVICE_FILE="/etc/systemd/system/waydroid-mac.service"
    cat << EOF | sudo tee "$SERVICE_FILE" >/dev/null
[Unit]
Description=Set Waydroid MAC Address
After=waydroid-container.service
Requires=waydroid-container.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 2
ExecStart=/bin/bash -c 'ip link set dev waydroid0 down && ip link set dev waydroid0 address $NEW_MAC && ip link set dev waydroid0 up'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable waydroid-mac.service
    echo "[+] Created systemd service for automatic MAC assignment"
    echo "[✓] Phase 5 complete (service will apply MAC on next Waydroid start)"
    exit 0
fi

# Apply MAC now
echo "[*] Applying MAC to $INTERFACE..."
sudo ip link set dev "$INTERFACE" down
sudo ip link set dev "$INTERFACE" address "$NEW_MAC"
sudo ip link set dev "$INTERFACE" up

# Verify
CURRENT_MAC=$(ip link show "$INTERFACE" | grep -oP 'link/ether \K[0-9a-f:]+')
echo "[+] Applied MAC: $CURRENT_MAC"

# Check if MAC is valid (not locally administered)
FIRST_BYTE=$(echo "$CURRENT_MAC" | cut -d: -f1)
FIRST_BYTE_DEC=$((16#$FIRST_BYTE))
if (( FIRST_BYTE_DEC & 2 )); then
    echo "[!] Warning: MAC appears locally administered"
else
    echo "[+] MAC is globally unique (valid vendor)"
fi

echo ""
echo "[✓] Phase 5 complete"
