# Raspberry Pi 3 (Model B & Model B+)

## Hardware Specifications
- **SoC:**
  - **Pi 3 Model B:** Broadcom BCM2837 quad-core Cortex-A53 @ 1.2 GHz
  - **Pi 3 Model B+:** Broadcom BCM2837B0 quad-core Cortex-A53 @ 1.4 GHz (with metal thermal shield)
- **RAM:** 1 GB LPDDR2
- **GPU:** VideoCore IV
- **Networking:**
  - **3B:** 10/100 Ethernet (USB 2.0 bus), 2.4 GHz 802.11n Wi-Fi, Bluetooth 4.1 / BLE
  - **3B+:** Gigabit Ethernet over USB 2.0 (capped at ~300 Mbps), dual-band 2.4/5 GHz 802.11ac Wi-Fi, Bluetooth 4.2 / BLE
- **Power Supply:** **5V / 2.5A** micro-USB
- **Storage:** microSD card (USB boot supported out of the box on 3B+, or via OTP bit on 3B)

## Headless Best Practices
- **64-bit Architecture:** Fully supported by Debian Bookworm/Trixie `arm64`. Recommended for modern Docker and Go binaries.
- **Bluetooth & Serial Console:** Disabling Bluetooth via `dtoverlay=disable-bt` restores the primary hardware UART (`ttyAMA0` / PL011) to the GPIO pins, replacing the software mini-UART.
- **Thermal Behavior:** The 3B can reach thermal throttling (80°C) under sustained load without a heatsink. The 3B+ includes improved power circuitry and heat distribution, but passive cooling is still advised for 24/7 headless servers.
