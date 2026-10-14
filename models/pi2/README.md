# Raspberry Pi 2 Model B

> **When to use this guide:** the Pi 2 is an older, wired-only board — useful for
> simple always-on tasks. For the model index see [`../README.md`](../README.md);
> for any unfamiliar term see [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md).

## Hardware Specifications
- **SoC:** 
  - **v1.1:** Broadcom BCM2836 (ARMv7) quad-core Cortex-A7 @ 900 MHz
  - **v1.2:** Broadcom BCM2837 (ARMv8 / 64-bit capable) quad-core Cortex-A53 @ 900 MHz
- **RAM:** 1 GB LPDDR2
- **GPU:** VideoCore IV
- **Networking:** 10/100 Ethernet (shared USB 2.0 bus). No built-in Wi-Fi or Bluetooth.
- **Power Supply:** 5V / 1.8A–2.0A via micro-USB
- **Storage:** microSD card

## Headless Best Practices
- **GPU Memory (`gpu_mem=16`):** Frees up memory for headless server services.
- **OS Support:**
  - **v1.1:** 32-bit `armhf` only.
  - **v1.2:** Supports 64-bit `arm64` kernels and userland (though 1 GB RAM can be tight for 64-bit overhead).
- **Network:** Requires wired Ethernet connection or supported USB Wi-Fi adapter.

## Related

- [`../README.md`](../README.md) — model index and how auto-detection works.
- [`config.txt.append`](config.txt.append) — boot tweaks appended by `setup.sh`.
- [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md) — term definitions.
