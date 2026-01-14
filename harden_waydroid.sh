#!/bin/bash
# Waydroid Anti-Emulator Hardening - Master Script
# Makes Waydroid indistinguishable from a real Pixel 5

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        Waydroid Anti-Emulator Hardening Suite                ║"
echo "║                    Pixel 5 (redfin)                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for root/sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}[!] Some operations require root. You may be prompted for sudo.${NC}"
fi

# Check Waydroid installed
if ! command -v waydroid &>/dev/null; then
    echo -e "${RED}[✗] Waydroid not found. Please install Waydroid first.${NC}"
    exit 1
fi

# Menu
show_menu() {
    echo ""
    echo "Select hardening phases to run:"
    echo ""
    echo "  1) Phase 1 - Device Identity (Pixel 5 props)"
    echo "  2) Phase 2 - Google Play Features (install XML)"
    echo "  3) Phase 3 - Camera Setup (v4l2loopback)"
    echo "  4) Phase 4 - Filesystem Cleanup (hide strings)"
    echo "  5) Phase 5 - Network Identity (MAC spoof)"
    echo "  6) Phase 6 - Bluetooth & Sensors (install XML)"
    echo "  7) Phase 7 - Emulator Flags (neutralize)"
    echo ""
    echo "  a) Run ALL phases"
    echo "  v) Verify current configuration"
    echo "  q) Quit"
    echo ""
}

# Phase 2 - Install Play features XML
run_phase2() {
    echo -e "${BLUE}[Phase 2] Google Play Features${NC}"
    echo "================================"
    
    # Waydroid overlay path
    OVERLAY_DIR="/var/lib/waydroid/overlay/system/etc/sysconfig"
    sudo mkdir -p "$OVERLAY_DIR"
    
    sudo cp "$CONFIG_DIR/play_features.xml" "$OVERLAY_DIR/google_features.xml"
    echo "[+] Installed play_features.xml"
    echo -e "${GREEN}[✓] Phase 2 complete${NC}"
}

# Phase 6 - Install sensor/bluetooth features
run_phase6() {
    echo -e "${BLUE}[Phase 6] Bluetooth & Sensors${NC}"
    echo "=============================="
    
    OVERLAY_DIR="/var/lib/waydroid/overlay/system/etc/sysconfig"
    sudo mkdir -p "$OVERLAY_DIR"
    
    sudo cp "$CONFIG_DIR/bluetooth_features.xml" "$OVERLAY_DIR/bluetooth_features.xml"
    sudo cp "$CONFIG_DIR/sensor_features.xml" "$OVERLAY_DIR/sensor_features.xml"
    
    # Also add bluetooth props
    PROP_FILE="/var/lib/waydroid/waydroid_base.prop"
    echo "ro.bluetooth.library_name=libbluetooth.so" | sudo tee -a "$PROP_FILE" >/dev/null
    echo "persist.bluetooth.bluetooth_audio_hal.enabled=true" | sudo tee -a "$PROP_FILE" >/dev/null
    
    echo "[+] Installed bluetooth_features.xml"
    echo "[+] Installed sensor_features.xml"
    echo -e "${GREEN}[✓] Phase 6 complete${NC}"
}

# Verification
verify_config() {
    echo -e "${BLUE}[Verification] Checking Configuration${NC}"
    echo "======================================="
    
    PROP_FILE="/var/lib/waydroid/waydroid_base.prop"
    
    echo ""
    echo "[*] Device Identity:"
    grep -E "^ro.product.(brand|model|device)=" "$PROP_FILE" 2>/dev/null | sed 's/^/    /'
    
    echo ""
    echo "[*] Build Fingerprint:"
    grep "^ro.build.fingerprint=" "$PROP_FILE" 2>/dev/null | sed 's/^/    /' | cut -c1-80
    
    echo ""
    echo "[*] Emulator Flags:"
    grep -E "^ro.(kernel.qemu|hardware|build.type)=" "$PROP_FILE" 2>/dev/null | sed 's/^/    /'
    
    echo ""
    echo "[*] Filesystem Mount:"
    if mountpoint -q /var/lib/waydroid 2>/dev/null; then
        echo "    ✓ Bind mount active (strings hidden)"
    else
        echo "    ! Standard mount (strings may be visible)"
    fi
    
    echo ""
    echo "[*] Feature XMLs:"
    OVERLAY_DIR="/var/lib/waydroid/overlay/system/etc/sysconfig"
    for xml in google_features.xml bluetooth_features.xml sensor_features.xml; do
        if [[ -f "$OVERLAY_DIR/$xml" ]]; then
            echo "    ✓ $xml installed"
        else
            echo "    ✗ $xml missing"
        fi
    done
    
    echo ""
    echo "[*] Virtual Camera:"
    if lsmod | grep -q v4l2loopback; then
        echo "    ✓ v4l2loopback loaded"
        v4l2-ctl --list-devices 2>/dev/null | grep -A1 "Virtual" | sed 's/^/    /' || echo "    ! No virtual device"
    else
        echo "    ✗ v4l2loopback not loaded"
    fi
    
    echo ""
}

# Run all phases
run_all() {
    echo -e "${YELLOW}[*] Running all hardening phases...${NC}"
    echo ""
    
    bash "$SCRIPTS_DIR/phase1_device_identity.sh"
    echo ""
    
    run_phase2
    echo ""
    
    bash "$SCRIPTS_DIR/phase3_camera_setup.sh"
    echo ""
    
    bash "$SCRIPTS_DIR/phase4_filesystem_cleanup.sh"
    echo ""
    
    bash "$SCRIPTS_DIR/phase5_network_identity.sh"
    echo ""
    
    run_phase6
    echo ""
    
    bash "$SCRIPTS_DIR/phase7_emulator_flags.sh"
    echo ""
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              All hardening phases complete!                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Restart Waydroid: waydroid session stop && waydroid session start"
    echo "  2. Verify with: adb shell getprop | grep -E 'generic|x86|waydroid'"
    echo "  3. Start OBS Virtual Camera before opening camera apps"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Choice: " choice
    echo ""
    
    case $choice in
        1) bash "$SCRIPTS_DIR/phase1_device_identity.sh" ;;
        2) run_phase2 ;;
        3) bash "$SCRIPTS_DIR/phase3_camera_setup.sh" ;;
        4) bash "$SCRIPTS_DIR/phase4_filesystem_cleanup.sh" ;;
        5) bash "$SCRIPTS_DIR/phase5_network_identity.sh" ;;
        6) run_phase6 ;;
        7) bash "$SCRIPTS_DIR/phase7_emulator_flags.sh" ;;
        a|A) run_all ;;
        v|V) verify_config ;;
        q|Q) echo "Goodbye!"; exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}" ;;
    esac
done
