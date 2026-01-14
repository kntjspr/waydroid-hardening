#!/bin/bash
# Phase 1: Device Identity Spoofing - Pixel 5 (redfin)
# Eliminates generic, emulator, and waydroid fingerprints

set -e

PROP_FILE="/var/lib/waydroid/waydroid_base.prop"

echo "[Phase 1] Device Identity Spoofing - Pixel 5"
echo "============================================="

# Backup existing prop file
if [[ -f "$PROP_FILE" ]]; then
    sudo cp "$PROP_FILE" "${PROP_FILE}.backup.$(date +%s)"
    echo "[+] Backed up existing prop file"
fi

# Pixel 5 (redfin) properties
props=(
    # Product identity
    "ro.product.brand=google"
    "ro.product.manufacturer=Google"
    "ro.system.build.product=redfin"
    "ro.product.name=redfin"
    "ro.product.device=redfin"
    "ro.product.model=Pixel 5"
    
    # Build flavor and fingerprints
    "ro.system.build.flavor=redfin-user"
    "ro.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys"
    "ro.system.build.description=redfin-user 11 RQ3A.211001.001 eng.electr.20230318.111310 release-keys"
    "ro.bootimage.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001:user/release-keys"
    "ro.build.display.id=google/redfin/redfin:11/RQ3A.211001.001:user/release-keys"
    "ro.build.tags=release-keys"
    
    # Vendor fingerprints
    "ro.vendor.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001:user/release-keys"
    "ro.vendor.build.type=user"
    "ro.odm.build.tags=release-keys"
    
    # Additional device properties
    "ro.product.first_api_level=30"
    "ro.product.board=redfin"
    "ro.board.platform=lito"
    "ro.hardware.chipname=SM7250"
)

# Remove existing conflicting properties
for prop in "${props[@]}"; do
    key="${prop%%=*}"
    sudo sed -i "/^${key}=/d" "$PROP_FILE" 2>/dev/null || true
done

# Append new properties
for prop in "${props[@]}"; do
    echo "$prop" | sudo tee -a "$PROP_FILE" >/dev/null
done

echo "[+] Applied ${#props[@]} Pixel 5 properties"

# Verification
echo ""
echo "[*] Verification:"
echo "    Brand: $(grep -m1 'ro.product.brand=' "$PROP_FILE" | cut -d= -f2)"
echo "    Model: $(grep -m1 'ro.product.model=' "$PROP_FILE" | cut -d= -f2)"
echo "    Device: $(grep -m1 'ro.product.device=' "$PROP_FILE" | cut -d= -f2)"

echo ""
echo "[✓] Phase 1 complete"
