# Raspberry Pi Zero 2 W

> **When to use this guide:** the Zero 2 W is a 64-bit quad-core board in the
> tiny Zero form factor — great for compact always-on nodes. For the model index
> see [`../README.md`](../README.md); for any unfamiliar term see
> [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md).

## Hardware Specifications
- **SiP (System-in-Package):** Raspberry Pi RP3A0 (quad-core ARM Cortex-A53 @ 1.0 GHz, packaged with 512 MB LPDDR2 SDRAM)
- **Architecture:** 64-bit ARMv8-A
- **GPU:** VideoCore IV, mini-HDMI
- **Networking:** 2.4 GHz 802.11 b/g/n Wi-Fi, Bluetooth 4.2 / BLE
- **Ports:** 1x micro-USB (power), 1x micro-USB (OTG data), CSI-2 camera connector
- **Power Supply:** **5V / 1.5A–2.0A** via micro-USB

## Headless Best Practices
- **64-bit Capability:** Unlike the original Zero W, the Zero 2 W runs standard 64-bit Debian Bookworm and Trixie kernels (`arm64`), granting access to modern 64-bit container images and software.
- **RAM Constraints:** With 512 MB total RAM, low memory footprints and swap reduction (via `vm.swappiness=10` in this kit) are vital. Allocating `gpu_mem=16` is strongly recommended for headless mode.
- **USB OTG Gadget:** Supports virtual network interface mode (like Zero W) using `dtoverlay=dwc2`.
- **Thermals:** The quad-core Cortex-A53 in such a small footprint can heat up rapidly under sustained 100% CPU utilization. A low-profile stick-on heatsink is recommended if doing moderate overclocking or heavy computing.

## Related

- [`../README.md`](../README.md) — model index and how auto-detection works.
- [`config.txt.append`](config.txt.append) — boot tweaks appended by `setup.sh`.
- [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md) — term definitions.
