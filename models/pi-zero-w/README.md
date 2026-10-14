# Raspberry Pi Zero / Zero W

> **When to use this guide:** tiny, cheap, low-power boards, ideal for embedded
> or single-cable (USB gadget) setups. For the model index see
> [`../README.md`](../README.md); for any unfamiliar term see
> [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md).

## Hardware Specifications
- **SoC:** Broadcom BCM2835 (ARMv6)
- **CPU:** ARM1176JZF-S single-core @ 1.0 GHz
- **RAM:** 512 MB LPDDR2 (packaged on top of the SoC / PoP)
- **GPU:** VideoCore IV, mini-HDMI
- **Networking:**
  - **Zero:** No onboard network.
  - **Zero W:** 2.4 GHz 802.11n Wi-Fi, Bluetooth 4.1 / BLE
- **Ports:** 1x micro-USB (power only), 1x micro-USB (OTG data), CSI camera connector
- **Power Supply:** 5V / 1.2A via micro-USB

## Headless Best Practices
- **USB OTG Ethernet Gadget:** You can access the Zero directly over a single micro-USB cable plugged into a PC/laptop without any local Wi-Fi or router:
  1. Add `dtoverlay=dwc2` to `/boot/firmware/config.txt`.
  2. Add `modules-load=dwc2,g_ether` after `rootwait` in `/boot/firmware/cmdline.txt`.
  3. Connect the PC to the inner micro-USB port (labeled "USB", not "PWR"). The Pi enumerates as a USB virtual network card.
- **GPU Memory (`gpu_mem=16`):** Essential for maximizing available RAM for system processes.
- **OS Support:** 32-bit `armv6l` ONLY.

## Related

- [`../README.md`](../README.md) — model index and how auto-detection works.
- [`config.txt.append`](config.txt.append) — boot tweaks appended by `setup.sh`.
- [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md) — term definitions.
