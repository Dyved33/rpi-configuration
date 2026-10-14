# Raspberry Pi 4 Model B / Pi 400

> **When to use this guide:** this is the workhorse 64-bit Pi generation, with
> USB 3.0 and true Gigabit Ethernet — the most common choice for a headless
> server. For the model index see [`../README.md`](../README.md); for any
> unfamiliar term see [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md).

## Hardware Specifications
- **SoC:** Broadcom BCM2711 quad-core Cortex-A72 (ARM v8) @ 1.5 GHz (Pi 4 rev 1.4/1.5 & Pi 400 default to 1.8 GHz)
- **RAM:** 1 GB, 2 GB, 4 GB, or 8 GB LPDDR4-3200 SDRAM
- **GPU:** VideoCore VI, dual micro-HDMI ports (up to 4Kp60)
- **Networking:** True Gigabit Ethernet (dedicated PCIe bus, full throughput), dual-band 2.4/5 GHz 802.11ac Wi-Fi, Bluetooth 5.0 / BLE
- **USB:** 2x USB 3.0 ports, 2x USB 2.0 ports
- **Power Supply:** **5V / 3.0A USB-C (15W)**.
  - *Hardware note:* Early Pi 4 boards (revision 1.1) had a non-compliant CC resistor design that caused issues with electronically-marked (e-marked) USB-C smart cables. Use a standard non-e-marked USB-C cable or an official Raspberry Pi 15.3W power supply.
- **Storage:** microSD card, USB 3.0 SSD/HDD boot supported via onboard EEPROM.

## Headless Best Practices
- **GPU Memory Allocation:** Setting `gpu_mem=16` functions properly on Pi 4 and gives the full memory space back to the Linux kernel and user space.
- **USB 3.0 Boot (SSD Upgrade):** Booting directly from an SSD over USB 3.0 provides 4x–10x faster random I/O and avoids SD card wear.
  1. Update bootloader EEPROM: `sudo rpi-eeprom-update -a`
  2. Configure boot order: `sudo raspi-config` → Advanced Options → Boot Order → NVMe/USB Boot.
- **Thermals & Cooling:** BCM2711 dissipates significantly more heat than previous generations. A passive aluminum enclosure or active fan is strongly advised to prevent thermal throttling at 80°C.

## Overclocking Reference
| Target | `arm_freq` | `over_voltage` | `gpu_freq` | Cooling Needed |
|---|---|---|---|---|
| Stock | 1500–1800 MHz | 0 | 500 MHz | Passive heatsink |
| Safe Daily | 2000 MHz | 6 | 600 MHz | Active cooling (fan) |
| High | 2147 MHz | 8 | 750 MHz | High-efficiency active cooling |

## Related

- [`../README.md`](../README.md) — model index and how auto-detection works.
- [`config.txt.append`](config.txt.append) — boot tweaks appended by `setup.sh`.
- [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md) — term definitions.
