# pi-config — headless Raspberry Pi OS setup kit

A clean, modular kit that takes a freshly flashed Raspberry Pi OS (supporting **Bookworm**, **Trixie**, and legacy **Bullseye**) and turns it into a secure, stable, headless machine managed over SSH. Every file is plain text, fully documented, and engineered for reliability.

Supports all major hardware models: **Raspberry Pi 5, Pi 4 / 400, Pi 3, Pi 2, Pi 1, and Pi Zero / Zero 2 W**.

---

## 1. What is in this kit

```
pi-config/
├── README.md                      ← this file
├── setup.sh                       ← the installer, run ON the Pi (with auto-hardware detection)
├── models/                        ← dedicated folders per model (config + README)
│   ├── pi5/                       ← Raspberry Pi 5 (BCM2712, PCIe NVMe, 27W PD)
│   ├── pi4/                       ← Raspberry Pi 4 / 400 (BCM2711, USB 3.0 SSD)
│   ├── pi3/                       ← Raspberry Pi 3 Model B / B+ (BCM2837/B0)
│   ├── pi2/                       ← Raspberry Pi 2 Model B (BCM2836 / BCM2837)
│   ├── pi1/                       ← Raspberry Pi 1 Model A/B/A+/B+ (BCM2835)
│   ├── pi-zero-w/                 ← Raspberry Pi Zero & Zero W (OTG Gadget support)
│   └── pi-zero-2w/                ← Raspberry Pi Zero 2 W (64-bit quad-core)
├── boot/
│   ├── ssh                        ← empty file: enables SSH           (BOOT partition)
│   ├── config.txt.append          ← universal conditional config      (BOOT partition)
│   └── cmdline.txt.example        ← headless kernel arguments reference (quiet boot, OTG)
├── tools/
│   └── make-userconf.sh           ← run on PC: creates userconf.txt (Bullseye/Bookworm)
├── rootfs/                        ← mirrors "/" on the Pi; setup.sh copies it in
│   ├── etc/
│   │   ├── ssh/sshd_config.d/10-hardening.conf
│   │   ├── fail2ban/jail.d/sshd.local
│   │   ├── apt/apt.conf.d/
│   │   │   ├── 20auto-upgrades
│   │   │   └── 50unattended-upgrades
│   │   ├── NetworkManager/conf.d/wifi-powersave-off.conf
│   │   ├── systemd/journald.conf.d/size.conf
│   │   ├── systemd/system.conf.d/watchdog.conf
│   │   ├── systemd/system/pi-backup.{service,timer}
│   │   ├── sysctl.d/99-pi.conf
│   │   ├── profile.d/pi-aliases.sh
│   │   └── pi-backup.conf
│   └── usr/local/bin/{pi-status,pi-backup}
└── optional/                      ← NOT installed automatically
    ├── sshd-keys-only.conf        ← disables SSH passwords (installed only if you have a key)
    ├── home-wifi.nmconnection     ← offline Wi-Fi + static IP profile
    └── myapp.service              ← template to run your own program at boot
```

---

## 2. Hardware Compatibility & Specifications

| Model | SoC / Cores | Default Clock | Headless RAM Strategy | Power Supply Req. | Fast Storage Upgrade | Bluetooth Disable Parameter |
|---|---|---|---|---|---|---|
| **Pi 5** | BCM2712 (4x A76) | 2.4 GHz | Dynamic CMA (ignores `gpu_mem`) | **5V / 5.0A (27W PD)** | M.2 NVMe HAT+ (PCIe Gen 2/3) | `dtparam=bluetooth=off` |
| **Pi 4 / 400** | BCM2711 (4x A72) | 1.5–1.8 GHz | `gpu_mem=16` | **5V / 3.0A (15W USB-C)** | USB 3.0 SSD Boot (EEPROM) | `dtoverlay=disable-bt` |
| **Pi 3 Model B/B+** | BCM2837/B0 (4x A53) | 1.2–1.4 GHz | `gpu_mem=16` | **5V / 2.5A (micro-USB)** | USB 2.0 Boot / microSD | `dtoverlay=disable-bt` |
| **Pi 2 Model B** | BCM2836/7 (4x A7/A53)| 900 MHz | `gpu_mem=16` | **5V / 1.8A–2.0A** | microSD | N/A (No onboard BT) |
| **Pi 1 (A/B/A+/B+)** | BCM2835 (1x ARM11) | 700 MHz | `gpu_mem=16` | **5V / 1.2A** | SD / microSD | N/A (No onboard BT) |
| **Pi Zero 2 W** | RP3A0 (4x A53) | 1.0 GHz | `gpu_mem=16` | **5V / 1.5A–2.0A** | USB OTG Gadget / microSD | `dtoverlay=disable-bt` |
| **Pi Zero / Zero W** | BCM2835 (1x ARM11) | 1.0 GHz | `gpu_mem=16` | **5V / 1.2A** | USB OTG Gadget / microSD | `dtoverlay=disable-bt` |

For individual model pinouts, overclock tables, and hardware quirks, inspect each folder in `models/<model>/README.md`.

---

## 3. Boot vs root: where does each file go?

A Raspberry Pi storage medium (microSD card or SSD) contains **two partitions**:

```
 SD card / SSD
 ├── Partition 1: BOOT   (FAT32, "bootfs")   ← readable from Windows/macOS/Linux
 │      mounted on the Pi at /boot/firmware (or /boot on Bullseye); read BEFORE Linux starts
 └── Partition 2: ROOT   (ext4, "rootfs")    ← the real Linux system "/"
        readable natively from Linux
```

| File | Destination | When | Why there |
|---|---|---|---|
| `ssh` (empty) | **boot** | before first boot | Firmware flags Raspberry Pi OS to launch SSH server immediately |
| `userconf.txt` | **boot** | before first boot | Injects initial user/password safely (deprecated in Trixie+ in favor of Imager) |
| `config.txt.append` | **boot** → append to `config.txt` | before first boot | Read by firmware before kernel load (or auto-applied by `setup.sh`) |
| `cmdline.txt.example` | **boot** → reference for `cmdline.txt` | before first boot | Single-line kernel arguments (quiet boot, OTG gadget) |
| `pi-config/` (entire folder)| **boot** (carrier) | before first boot | FAT32 is cross-platform; easiest path to transfer onto the Pi offline |
| everything in `rootfs/` | **root** (`/`) | after first boot | Installed into `/` with strict permissions and ownership by `setup.sh` |
| `optional/home-wifi.nmconnection` | **root**: `/etc/NetworkManager/system-connections/` | before first boot | Offline headless static Wi-Fi configuration (requires `chmod 600`) |
| `optional/sshd-keys-only.conf` | **root** | after key verification | Installed by `setup.sh` only if `~/.ssh/authorized_keys` exists |

---

## 4. Step-by-step Setup

### Step A — On your PC
**Preferred method:** Flash Raspberry Pi OS using **Raspberry Pi Imager** (`Ctrl + Shift + X` or the gear icon) to set:
- Target hostname
- Username and SSH public key
- Wi-Fi credentials and locale

**Manual offline setup:**
1. **Enable SSH:** Copy `boot/ssh` to the boot partition.
2. **Create user:** On Linux/macOS/WSL run `tools/make-userconf.sh` and place `userconf.txt` in boot.
3. **Carry kit:** Copy the entire `pi-config/` repository folder to the boot partition.
4. Insert the card into your Pi and power on.

### Step B — Over SSH on the Pi
Connect to the machine:
```bash
ssh youruser@hostname.local  # or ssh youruser@<ip>
```
Run the automated installer:
```bash
cd /boot/firmware/pi-config   # on Bullseye: cd /boot/pi-config
nano setup.sh                 # adjust HOSTNAME, TIMEZONE, or optional STATIC_IP at top
sudo bash setup.sh
sudo reboot
```

`setup.sh` will:
1. Automatically detect your Raspberry Pi model (Pi 5, 4, 3, etc.).
2. Apply the matching model-specific `config.txt.append` configuration.
3. Configure the designated `HOSTNAME` in `/etc/hostname` and `/etc/hosts`.
4. Install and configure systemd hardening, watchdog timers, journal size limits, and RAM-backed `/tmp` (with automatic fallback to `/etc/fstab`).
5. Configure `fail2ban`, `ufw` firewall, and unattended security upgrades.

### Step C — Verification
```bash
pi-status                         # CPU temp, PMIC temp (Pi 5), throttled flags, RAM & disk
sudo ufw status verbose           # firewall verification
sudo fail2ban-client status sshd  # intrusion prevention status
systemctl status unattended-upgrades
```

---

## 5. Security & System Architecture

```
 External Network ─► [ufw firewall] ─► [fail2ban] ─► [sshd rules] ─► [SSH Key Only]
                     rate-limited 22   temp-bans     no root login   passwords disabled
                     mDNS (5353/udp)   5 failures    max 4 tries     (if authorized_keys present)
```

- **Watchdog Protection:** `/etc/systemd/system.conf.d/watchdog.conf` arms the hardware watchdog timer (`RuntimeWatchdogSec=15`, `RebootWatchdogSec=2min`, `ShutdownWatchdogSec=2min`). If the kernel locks up, the hardware resets itself.
- **Unattended Security Updates:** Configured via `20auto-upgrades` and `50unattended-upgrades` to pull automated daily security patches without disruptive reboots.
- **Log Conservation:** `size.conf` restricts systemd journal logs to a maximum of 100 MB on disk to prevent SD card wear and exhaustion.
- **Network Resilience:** Wi-Fi power saving is disabled by default via `wifi-powersave-off.conf` (`wifi.powersave = 2`), preventing SSH latency spikes and dropped sessions.

---

## 6. Static IP & NetworkManager

Raspberry Pi OS **Bookworm** and **Trixie** use **NetworkManager** by default.
- Set `SET_STATIC_IP="yes"` inside `setup.sh` along with your IP details.
- To configure manually with `nmcli`:
  ```bash
  sudo nmcli con mod "preconfigured" ipv4.method manual \
       ipv4.addresses 192.168.1.50/24 ipv4.gateway 192.168.1.1 ipv4.dns "1.1.1.1,9.9.9.9"
  sudo reboot
  ```
- **Bullseye (dhcpcd):** If running older systems, configure static allocations in `/etc/dhcpcd.conf`.

---

## 7. High-Reliability Boot Options (USB 3.0 & NVMe)

SD cards remain the primary point of failure on headless 24/7 nodes. For thesis-grade production reliability:
- **Raspberry Pi 5 (NVMe Boot):** Use the official M.2 HAT+ and run `sudo raspi-config` → Advanced → Boot Order → NVMe/USB Boot. See [models/pi5/README.md](file:///home/david/rpi-configuration/models/pi5/README.md).
- **Raspberry Pi 4 (USB 3.0 SSD Boot):** Attach an external USB 3.0 SSD enclosure (UAS compatible) and update bootloader EEPROM. See [models/pi4/README.md](file:///home/david/rpi-configuration/models/pi4/README.md).
