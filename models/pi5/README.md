# Raspberry Pi 5

> **When to use this guide:** the Pi 5 is the current flagship — the fastest Pi,
> with PCIe/NVMe support and a 27W USB-C power requirement. For the model index
> see [`../README.md`](../README.md); for any unfamiliar term see
> [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md).

## Hardware Specifications
- **SoC:** Broadcom BCM2712 quad-core ARM Cortex-A76 (ARMv8.2-A) @ 2.4 GHz (cryptography extensions supported)
- **RAM:** 2 GB, 4 GB, or 8 GB LPDDR4X-4267 SDRAM
- **GPU:** VideoCore VII, dual 4Kp60 HDMI outputs with HDR support
- **I/O Controller:** Custom RP1 southbridge handling USB, Gigabit Ethernet, GPIO, and cameras/displays
- **Power Management:** Dialog DA9091 PMIC with dedicated on-die thermal sensor
- **Power Supply:** **5V / 5.0A USB-C Power Delivery (27W)**.
  - *Power behavior:* If booted with a standard 5V/3A (15W) power adapter, the Pi 5 will boot normally but limits total USB downstream current to 600 mA (instead of 1.6A) and displays a firmware warning.
- **Storage:** microSD card, high-speed PCIe 2.0 / 3.0 M.2 NVMe SSD via FPC connector (official M.2 HAT+), or USB 3.0.

## Headless Best Practices
- **GPU Memory Allocation:** Setting `gpu_mem` has no effect on Pi 5. VideoCore VII relies entirely on Linux CMA dynamic memory management.
- **Bluetooth Control:** On Pi 5, Bluetooth is wired differently than Pi 3/4. Do **not** use `dtoverlay=disable-bt`. Instead use `dtparam=bluetooth=off`.
- **PMIC Health Monitoring:** Pi 5 includes a dedicated temperature sensor for the power management chip. Run `vcgencmd measure_temp pmic` or use `pi-status`.

## NVMe SSD Boot (M.2 HAT+)
Running a headless system or database off an NVMe drive provides sustained 400–800 MB/s transfer speeds and prevents SD card wear.
1. Connect the M.2 NVMe HAT+ with an M.2 2230 or 2242 NVMe drive.
2. Update the bootloader EEPROM:
   ```bash
   sudo rpi-eeprom-update -a
   ```
3. Set the boot order to prefer NVMe:
   ```bash
   sudo raspi-config
   # Advanced Options -> Boot Order -> NVMe/USB Boot
   ```
   Or edit the EEPROM directly (`sudo rpi-eeprom-config --edit`) and set `BOOT_ORDER=0xf416`.
4. (Optional) Enable PCIe Gen 3 speeds by adding `dtparam=pciex1_gen=3` to `/boot/firmware/config.txt`.

## Thermals & Cooling
Under heavy multi-threaded workloads, the Cortex-A76 cores draw up to 12W and will throttle without cooling.
The official **Raspberry Pi Active Cooler** (anodized aluminum heatsink with a 4-pin PWM blower fan) plugs directly into the dedicated fan header and is automatically regulated by the kernel based on SoC temperatures.

## Overclocking Reference
> **Important:** The Pi 5 does not accept integer step units for `over_voltage`. It uses `over_voltage_delta` specified in microvolts ($\mu\text{V}$).

| Target | `arm_freq` | `over_voltage_delta` | Cooling Requirement |
|---|---|---|---|
| Stock | 2400 MHz | 0 | Active Cooler / Heatsink |
| Moderate | 2800 MHz | 25000 (25 mV) | Raspberry Pi Active Cooler |
| High | 3000 MHz | 50000 (50 mV) | High performance active cooler |

## Related

- [`../README.md`](../README.md) — model index and how auto-detection works.
- [`config.txt.append`](config.txt.append) — boot tweaks appended by `setup.sh`.
- [`../../docs/GLOSSARY.md`](../../docs/GLOSSARY.md) — term definitions.
