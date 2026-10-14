# `models/` — per-model hardware notes and boot tweaks

Each subfolder targets one Raspberry Pi family and contains:

- **`README.md`** — specifications, headless best practices, cooling, and
  overclocking guidance for that model.
- **`config.txt.append`** — a ready-to-append `config.txt` fragment. `setup.sh`
  detects your Pi automatically and appends the matching fragment.

> New to the terms? See [`../docs/GLOSSARY.md`](../docs/GLOSSARY.md).

## Index

| Folder | Targets | SoC | Typical headless note |
|---|---|---|---|
| [`pi5/`](pi5/README.md) | Raspberry Pi 5 | BCM2712 | `gpu_mem` ignored (uses CMA); Bluetooth off via `dtparam`, not `dtoverlay`. |
| [`pi4/`](pi4/README.md) | Pi 4 Model B, Pi 400 | BCM2711 | `gpu_mem=16`; USB 3.0 SSD boot via EEPROM. |
| [`pi3/`](pi3/README.md) | Pi 3 Model B / B+ | BCM2837 / B0 | 64-bit capable; `disable-bt` frees the good UART. |
| [`pi2/`](pi2/README.md) | Pi 2 Model B | BCM2836 / 2837 | Wired Ethernet only (no onboard Wi-Fi). |
| [`pi1/`](pi1/README.md) | Pi 1 Model A/A+/B/B+ | BCM2835 | 32-bit `armv6l` only; `gpu_mem=16` saves 48 MB. |
| [`pi-zero-w/`](pi-zero-w/README.md) | Pi Zero, Zero W | BCM2835 | USB OTG gadget mode; `gpu_mem=16`. |
| [`pi-zero-2w/`](pi-zero-2w/README.md) | Pi Zero 2 W | RP3A0 | 64-bit capable; 512 MB RAM — keep memory small. |

## How the model sections work

In `config.txt`, a header in square brackets applies to matching hardware only:

| Filter | Applies to |
|---|---|
| `[all]` | Every model |
| `[pi5]` | Pi 5 / 500, Compute Module 5 |
| `[pi4]` | Pi 4B, Pi 400, Compute Module 4 / 4S |
| `[pi3]` | Pi 3B / 3B+ / 3A+, Compute Module 3 / 3+ |
| `[pi2]` | Pi 2 Model B |
| `[pi1]` | Pi 1 A / A+ / B / B+, Compute Module 1 |
| `[pi0]` | Zero, Zero W **and** Zero 2 W |
| `[pi02]` | Zero 2 W only |

So a line under `[pi4]` is ignored by a Pi 5, and vice versa. This is why the
`config.txt.append` files can safely contain tweaks for one model only.

> **Watch out:** newer models read settings from **several** filters. For example
> the Zero 2 W reads `[pi0]`, `[pi0w]` *and* `[pi02]`, and the Pi 400 reads both
> `[pi4]` and `[pi400]`. To target a single model, use the most specific filter
> (`[pi02]`, `[pi400]`, …) or the `[board-type=…]` filter.

## How auto-detection works

`setup.sh` reads `/proc/device-tree/model` (e.g. `Raspberry Pi 4 Model B Rev 1.4`),
maps that string to a folder name, and appends `models/<folder>/config.txt.append`
to `/boot/firmware/config.txt` (`/boot/config.txt` on Bullseye). It adds a marker
line so re-running the script does not append the same settings twice.

## Overclocking caution

Every model README includes an overclocking table. Overclocking is **optional and
risky**: it requires adequate cooling and a strong power supply, and can reduce
hardware lifespan or cause instability. The `config.txt.append` files ship with
all overclocking lines **commented out** on purpose — enable them only if you
understand the trade-offs.

## Related

- [`../boot/README.md`](../boot/README.md) — BOOT-partition basics.
- [`../README.md`](../README.md) — full setup walkthrough.
