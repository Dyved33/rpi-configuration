# Raspberry Pi 1 (Model A, A+, B, B+)

> **When to use this guide:** the original Pi — 32-bit `armv6l` only and limited
> RAM. Best for very light, low-power or legacy tasks. For the model index see
> [`../README.md`](../README.md); for any unfamiliar term see
> [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md).

## Hardware Specifications
- **SoC:** Broadcom BCM2835 (ARMv6)
- **CPU:** ARM1176JZF-S single-core @ 700 MHz
- **RAM:** 256 MB (Model A) or 512 MB (Model B, A+, B+)
- **GPU:** VideoCore IV
- **Networking:** 10/100 Ethernet (Model B/B+ only, shared USB 2.0 bus). No built-in Wi-Fi or Bluetooth.
- **Power Supply:** 5V / 1.2A via micro-USB (Model B+ recommended: 5V / 1.5A)
- **Storage:** Full-size SD card (Model A/B) or microSD (Model A+/B+)

## Headless Best Practices
- **GPU Memory (`gpu_mem=16`):** Since total RAM is 256–512 MB, saving 48 MB by giving the GPU only 16 MB is critical.
- **Architecture & OS:** 32-bit `armv6l` ONLY (`armhf`). Raspberry Pi OS Bullseye was the last tier with full support; Bookworm has limited support on armv6l.
- **Networking:** Requires an Ethernet cable (Model B/B+) or a supported USB Wi-Fi dongle.

## Overclocking Reference
| Preset | `arm_freq` | `core_freq` | `sdram_freq` | `over_voltage` |
|---|---|---|---|---|
| Stock | 700 MHz | 250 MHz | 400 MHz | 0 |
| Medium | 900 MHz | 250 MHz | 450 MHz | 2 |
| Turbo | 1000 MHz | 500 MHz | 600 MHz | 6 |

## Related

- [`../README.md`](../README.md) — model index and how auto-detection works.
- [`config.txt.append`](config.txt.append) — boot tweaks appended by `setup.sh`.
- [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md) — term definitions.
