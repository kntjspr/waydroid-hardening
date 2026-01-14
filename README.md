# Waydroid Hardening Suite


## What This Defeats

| Detection Type | Status |
|---------------|--------|
| Build/property checks | Yes |
| Filesystem string checks | Yes |
| Feature/capability checks |Yes|
| Camera/sensor absence | Yes |
| Network/MAC detection | Yes |
| **Hardware attestation** | No |
| **Play Integrity STRONG** | No |

## Quick Start

```bash
# Make scripts executable
chmod +x harden_waydroid.sh scripts/*.sh

# Run all hardening phases
sudo ./harden_waydroid.sh
# Select 'a' for all phases

# Restart Waydroid
waydroid session stop
waydroid session start
```

## Phases

| Phase | Purpose | Script |
|-------|---------|--------|
| 1 | Device Identity → Pixel 5 | `scripts/phase1_device_identity.sh` |
| 2 | Google Play Features | `config/play_features.xml` |
| 3 | Camera via OBS/v4l2loopback | `scripts/phase3_camera_setup.sh` |
| 4 | Hide filesystem strings | `scripts/phase4_filesystem_cleanup.sh` |
| 5 | Vendor-valid MAC address | `scripts/phase5_network_identity.sh` |
| 6 | Bluetooth & Sensor features | `config/*.xml` |
| 7 | Neutralize emulator flags | `scripts/phase7_emulator_flags.sh` |

## Prerequisites

- Waydroid installed and initialized
- `v4l2loopback` (auto-installed by Phase 3)
- OBS Studio (for virtual camera)
- Root/sudo access

## Verification

After running, verify inside Waydroid:

```bash
# Should return empty (no emulator strings)
adb shell getprop | grep -iE "generic|x86|waydroid|emulator"

# Should show Pixel 5
adb shell getprop ro.product.model

# Should show hidden mounts
adb shell grep -i waydroid /proc/self/mounts
```

## Camera Setup

1. Install OBS Studio
2. Run Phase 3 to configure v4l2loopback
3. In OBS: **Tools → Start Virtual Camera**
4. Open camera app in Waydroid


## Credits
Some of the code are from here: https://github.com/Quackdoc/waydroid-scripts

Check out this repo for GApps, Magisk and more: https://github.com/casualsnek/waydroid_script
