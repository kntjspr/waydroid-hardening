#!/bin/bash
# Phase 7: Emulator Flag Neutralization
# Kills explicit emulator booleans and identifiers

set -e

PROP_FILE="/var/lib/waydroid/waydroid_base.prop"

echo "[Phase 7] Emulator Flag Neutralization"
echo "======================================="

# Emulator neutralization properties
props=(
    # Anti-emulator flags
    "ro.kernel.qemu=0"
    "ro.hardware=qcom"
    "ro.boot.hardware=qcom"
    "ro.build.characteristics=nosdcard"
    
    # Hide virtual machine indicators
    "ro.boot.selinux=enforcing"
    "ro.boot.vbmeta.device_state=locked"
    "ro.boot.verifiedbootstate=green"
    "ro.boot.flash.locked=1"
    "ro.boot.veritymode=enforcing"
    "ro.secure=1"
    "ro.debuggable=0"
    "ro.adb.secure=1"
    
    # Remove test-keys indicator
    "ro.build.type=user"
    
    # Fake baseband (prevents "no baseband" detection)
    "gsm.version.baseband=g7250-00011-201029-B-6933369"
    "gsm.version.ril-impl=android samsung-ril 1.0"
)

# Remove existing entries
for prop in "${props[@]}"; do
    key="${prop%%=*}"
    sudo sed -i "/^${key}=/d" "$PROP_FILE" 2>/dev/null || true
done

# Append new properties
for prop in "${props[@]}"; do
    echo "$prop" | sudo tee -a "$PROP_FILE" >/dev/null
done

echo "[+] Applied ${#props[@]} anti-emulator properties"

# Bluetooth soft-spoof properties
bluetooth_props=(
    "ro.bluetooth.library_name=libbluetooth.so"
    "persist.bluetooth.bluetooth_audio_hal.enabled=true"
    "bluetooth.device.class_of_device=90,2,12"
    "bluetooth.profile.a2dp.source.enabled=true"
    "bluetooth.profile.hfp.ag.enabled=true"
)

for prop in "${bluetooth_props[@]}"; do
    key="${prop%%=*}"
    sudo sed -i "/^${key}=/d" "$PROP_FILE" 2>/dev/null || true
    echo "$prop" | sudo tee -a "$PROP_FILE" >/dev/null
done

echo "[+] Applied ${#bluetooth_props[@]} Bluetooth properties"

# Verification
echo ""
echo "[*] Verification:"
echo "    qemu flag: $(grep -m1 'ro.kernel.qemu=' "$PROP_FILE" | cut -d= -f2)"
echo "    hardware: $(grep -m1 'ro.hardware=' "$PROP_FILE" | cut -d= -f2)"
echo "    build type: $(grep -m1 'ro.build.type=' "$PROP_FILE" | cut -d= -f2)"

echo ""
echo "[*] Verifying absence of emulator files..."
EMULATOR_FILES=(
    "/system/bin/qemud"
    "/dev/qemu_pipe"
    "/dev/socket/qemud"
    "/sys/qemu_trace"
)

for file in "${EMULATOR_FILES[@]}"; do
    if [[ -e "$file" ]]; then
        echo "    [!] Found emulator file: $file"
    fi
done
echo "    [+] Emulator file check complete"

echo ""
echo "[✓] Phase 7 complete"
