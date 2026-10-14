# Glossary

Plain-language definitions of every term and acronym used in this kit. Terms are
grouped by topic; within each group they are alphabetical. If a term is missing,
open an issue — the goal is that a reader with basic computer-science knowledge
can understand the whole repository without external searching.

> **How to read acronyms in this file:** the bold name is what you will see in the
> code/config; the text after it explains what it is and why it matters here.

---

## 1. Raspberry Pi hardware

| Term | Meaning |
|---|---|
| **SoC** (System on Chip) | A single chip that contains the CPU, GPU and many controllers. On a Pi, most of the "computer" is inside one Broadcom chip. |
| **BCM2835 / 2836 / 2837 / 2711 / 2712** | Broadcom SoC part numbers used across Pi generations (Pi 1/Zero → Pi 5). The number tells you the CPU family and capabilities. |
| **ARM11 / Cortex-A7 / A53 / A72 / A76** | CPU core designs. Higher/later names are generally faster: ARM11 (Pi 1) < Cortex-A7 (Pi 2 v1.1) < A53 (Pi 3/Zero 2 W) < A72 (Pi 4) < A76 (Pi 5). |
| **ARMv6 / v7 / v8** | CPU instruction-set architecture versions. `armv6l` (Pi 1/Zero) is 32-bit only; ARMv7 is 32-bit; ARMv8-A is 64-bit capable. |
| **armhf / arm64** | Debian/Raspberry Pi OS architecture names: `armhf` = 32-bit userland, `arm64` = 64-bit. |
| **GPU / VideoCore** | The graphics processor. Even on a "headless" Pi it still exists and can hold a slice of RAM. |
| **headless** | Running the Pi with **no monitor, keyboard or mouse** — you control it over the network (SSH). |
| **PoP** (Package on Package) | RAM stacked physically on top of the SoC to save board space (used by Pi Zero). |
| **PMIC** (Power Management IC) | The chip that regulates power. The Pi 5's PMIC has its own temperature sensor (`vcgencmd measure_temp pmic`). |
| **RP1** | The custom I/O chip on the Pi 5 that handles USB, Ethernet, GPIO and cameras (a "southbridge"). |
| **RP3A0** | The SiP used by the Pi Zero 2 W (quad-core CPU + 512 MB RAM in one package). |
| **SiP** (System in Package) | Like an SoC but combining several dies/packages into one physical module. |
| **HAT** (Hardware Attached on Top) | An add-on board that plugs onto the Pi's 40-pin header (e.g. the official M.2 NVMe HAT+). |
| **PWM** (Pulse-Width Modulation) | A way to control fan speed smoothly by switching power on/off rapidly. |
| **PSU** (Power Supply Unit) | The power adapter. Using an undersized PSU causes "under-voltage" throttling. |
| **PD** (Power Delivery) | The USB-C standard that lets a Pi 5 negotiate up to 5V/5A (27W) with a compatible supply. |
| **thermal throttling** | The CPU slowing itself down when it gets too hot (~80–85 °C) to avoid damage. |
| **silicon lottery** | The fact that two identical chips may overclock differently due to manufacturing variation. |

---

## 2. Boot & firmware

| Term | Meaning |
|---|---|
| **boot partition** (a.k.a. `bootfs`) | The small FAT32 partition at the start of the SD card/SSD. It is readable from Windows/macOS/Linux and holds `config.txt`, `cmdline.txt` and the firmware. Mounted at `/boot/firmware` on Bookworm/Trixie (`/boot` on Bullseye). |
| **rootfs** | The main ext4 partition containing the Linux system, mounted at `/`. |
| **config.txt** | Firmware settings read **before** Linux starts (e.g. `gpu_mem`, CPU voltage, GPU/CPU overclocking, enabling/disabling hardware). |
| **cmdline.txt** | Kernel arguments, all on a **single line** (e.g. `quiet`, `root=...`, `rootwait`). |
| **conditional filter** `[pi5]`, `[pi4]`, `[pi3]`, `[pi2]`, `[pi1]`, `[pi0]`, `[pi02]` | Section headers in `config.txt` that apply only to matching models. `[all]` applies to every model. `[pi0]` matches all Zero models (including Zero 2 W); `[pi02]` matches only the Zero 2 W. A model can read several filters. |
| **dtoverlay** | A firmware directive that loads a "device-tree overlay" to enable or disable/rewire hardware (e.g. `dtoverlay=disable-bt` turns off Bluetooth). |
| **dtparam** | A firmware directive that sets a device-tree *parameter* (e.g. `dtparam=bluetooth=off` on Pi 5). |
| **device tree** | A data structure that describes the hardware to the Linux kernel so it knows what devices exist. |
| **PARTUUID** | A unique identifier for a disk partition, used in `cmdline.txt` (`root=PARTUUID=...`) to say which partition is `/`. |
| **EEPROM** | Small rewritable firmware chip on Pi 4/5 that runs before the OS and controls USB/NVMe boot order (`rpi-eeprom-update`). |
| **OTP** (One-Time Programmable) | A fuse-like memory bit that, once set, cannot be unset (e.g. enabling USB boot on an early Pi 3). |
| **UART** (Universal Asynchronous Receiver/Transmitter) | A simple serial port. `PL011` is the hardware UART; the `mini-UART` is a lower-quality software-ish substitute. Disabling Bluetooth `dtoverlay=disable-bt` frees the good `PL011` (`/dev/ttyAMA0`) for GPIO serial. |
| **mini-HDMI / micro-HDMI** | Physically smaller HDMI connectors used on the Zero and Pi 4/5 respectively. |
| **CSI** (Camera Serial Interface) | The ribbon-cable connector for the Raspberry Pi camera. |
| **quiet** | A `cmdline.txt` flag that hides most kernel boot messages on the console. |

---

## 3. Memory & performance

| Term | Meaning |
|---|---|
| **gpu_mem** | How much RAM to reserve for the GPU. On headless Pi 1–4 you set `gpu_mem=16` to give RAM back to Linux. **Ignored on Pi 5.** |
| **CMA** (Contiguous Memory Allocator) | A Linux mechanism that hands memory to devices only when needed. Pi 5 uses this instead of a fixed `gpu_mem`. |
| **over_voltage** | How much to raise the CPU voltage when overclocking, given as an integer "step" on Pi 1–4. |
| **over_voltage_delta** | Pi 5 equivalent of `over_voltage`, but specified directly in microvolts (µV), e.g. `25000` = 25 mV. |
| **arm_freq / core_freq / gpu_freq / sdram_freq** | Clock speeds (MHz) for CPU / VideoCore / GPU / RAM that you may raise when overclocking. |
| **swap** | Disk space used as overflow RAM. On SD cards it causes wear, so this kit keeps it minimal. |
| **swappiness** | Kernel setting (0–100) for how eagerly Linux uses swap. `vm.swappiness=10` means "only when necessary". |
| **tmpfs** | A filesystem that lives in RAM. This kit mounts `/tmp` as tmpfs for speed and to reduce SD-card writes. |
| **sysctl** | The tool/files (`/etc/sysctl.d/*.conf`) that tune kernel runtime parameters, such as network hardening and swappiness. |

---

## 4. Networking

| Term | Meaning |
|---|---|
| **SSH** (Secure Shell) | Encrypted remote login. You connect with `ssh user@host`. |
| **sshd** | The SSH **server** (daemon) that listens for incoming SSH connections. |
| **NetworkManager** (`nmcli`) | The default network manager on Bookworm/Trixie. Profiles live in `/etc/NetworkManager/system-connections/`. |
| **dhcpcd** | The older network manager used on Bullseye; static IPs were configured in `/etc/dhcpcd.conf`. |
| **DHCP** | Automatic IP assignment from your router. |
| **static IP** | An address you fix yourself so the Pi is always reachable at the same address. |
| **mDNS / Avahi** | Lets you reach the Pi by name (`hostname.local`) without knowing its IP. Uses UDP port 5353. |
| **UFW** (Uncomplicated Firewall) | A simple front-end to the Linux firewall; this kit denies incoming traffic except SSH and mDNS. |
| **fail2ban** | Watches log files and temporarily bans IPs that repeatedly fail to log in (brute-force defence). |
| **Wi-Fi power saving** | A radio feature that sleeps the Wi-Fi chip between packets; disabling it (`wifi.powersave = 2`) avoids SSH lag and dropped sessions. |
| **BLE** (Bluetooth Low Energy) | The low-power Bluetooth mode used by sensors and beacons. |
| **e-marked cable** | A USB-C cable with an embedded chip for high power. Early Pi 4 boards had a design flaw making some e-marked cables unreliable. |

---

## 5. Storage

| Term | Meaning |
|---|---|
| **SD / microSD** | The flash card the OS normally boots from. Convenient but the usual failure point on 24/7 systems. |
| **NVMe** | A fast SSD protocol over PCIe; on Pi 5 via an M.2 HAT+ it reaches hundreds of MB/s. |
| **M.2 / 2230 / 2242** | The small SSD form factor and its length in mm (22 mm wide; 30 or 42 mm long). |
| **PCIe** (Peripheral Component Interconnect Express) | The high-speed bus the Pi 5 exposes for NVMe. Gen 3 is faster than the default Gen 2. |
| **USB 3.0 boot** | Booting the OS from a USB SSD instead of the SD card (Pi 4/5 via EEPROM boot order). |
| **UAS** (USB Attached SCSI) | A faster USB storage protocol; some SSD enclosures work best with it. |
| **rsync** | A tool that copies/synchronises files, transferring only the differences. Used by `pi-backup`. |
| **ext4 / FAT32** | Filesystem formats: `ext4` for Linux `rootfs`, `FAT32` for the cross-platform `bootfs`. |

---

## 6. Security & system services

| Term | Meaning |
|---|---|
| **hardening** | Tightening default settings to reduce attack surface (e.g. disabling root SSH login, limiting login attempts). |
| **public-key authentication** | Logging in with a key pair instead of a password; more secure and can disable passwords entirely. |
| **X11 forwarding** | Forwarding graphical apps over SSH; disabled here because the Pi is headless. |
| **watchdog** | A hardware timer that reboots the Pi automatically if the system freezes. |
| **systemd** | The init system that starts/manages services (`systemctl`) and timers. |
| **service (unit)** | A background program systemd runs (e.g. `pi-backup.service`). |
| **timer (unit)** | A systemd schedule that runs a service on a calendar (e.g. `pi-backup.timer`, daily). |
| **journald / journalctl** | The systemd logging system and its viewer (`journalctl -u <service>`). |
| **unattended-upgrades** | Automatically installs security updates without prompting. |
| **Automatic-Reboot** | Whether unattended-upgrades reboots after a kernel update. Kept `false` for predictable headless servers. |
| **unattended** | Running without a person at the console — the whole point of a headless server setup. |

---

## 7. USB gadget mode (Pi Zero / Zero 2 W)

| Term | Meaning |
|---|---|
| **OTG** (On-The-Go) | A USB port that can act as a device as well as a host. |
| **gadget mode** | Making the Pi pretend to be a USB device (e.g. a network card) when plugged into a PC. |
| **dwc2** | The USB controller driver that enables gadget mode (`dtoverlay=dwc2`). |
| **g_ether** | The Linux driver that makes the Pi appear as a USB Ethernet card (`modules-load=dwc2,g_ether`). |
| **rootwait** | A kernel argument telling it to wait for the root filesystem to appear before mounting it. |
