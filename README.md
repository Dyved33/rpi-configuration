# rpi-configuration — headless Raspberry Pi OS setup kit

Takes a freshly flashed **Raspberry Pi OS** (Bookworm, Trixie, or legacy
Bullseye) and turns it into a secure, stable, **headless** machine you manage
over SSH. Every file is plain text and documented, so you can read it, change it,
and reuse it in your own projects.

Supported hardware: **Pi 5, Pi 4 / 400, Pi 3, Pi 2, Pi 1, and Pi Zero / Zero 2 W.**

> **Who is this for?** Anyone comfortable with the command line and basic
> Linux/network concepts. If a term is unfamiliar, check
> [`docs/GLOSSARY.md`](docs/GLOSSARY.md) — it explains every acronym used here.
>
> **What "headless" means:** the Pi runs without a monitor, keyboard, or mouse.
> You reach it over the network with `ssh`. This kit's job is to make that setup
> safe, reproducible, and easy to re-create.

---

## Quick start (TL;DR)

1. **Flash** Raspberry Pi OS with **Raspberry Pi Imager** and, in the advanced
   settings (gear icon / `Ctrl+Shift+X`), set hostname, username, SSH public key,
   Wi-Fi, and locale.
2. **Copy this repository** onto the card's **BOOT** partition.
3. SSH in and run the installer:
   ```bash
   ssh youruser@yourhost.local
   cd /boot/firmware/rpi-configuration    # /boot/rpi-configuration on Bullseye
   cp setup.conf.example setup.conf       # optional but recommended
   sudo nano setup.conf                   # set hostname, timezone, etc.
   sudo bash setup.sh
   sudo reboot
   ```

That's it — the Pi comes back hardened, with a firewall, automatic security
updates, a watchdog, and helper commands (`pi-status`, `pi-backup`). Read on for
the details.

---

## 1. What is in this kit

```
rpi-configuration/
├── README.md                      ← this file
├── LICENSE                        ← MIT license (free to reuse)
├── setup.sh                       ← installer, run ON the Pi (auto-detects the model)
├── setup.conf.example             ← copy to setup.conf and edit your settings
├── docs/
│   └── GLOSSARY.md                ← plain-language definitions of all terms
├── models/                        ← per-model specs, notes and boot tweaks
│   ├── README.md                  ← model index + how auto-detection works
│   ├── pi5/                       ← BCM2712, PCIe NVMe, 27W PD
│   ├── pi4/                       ← BCM2711, USB 3.0 SSD boot
│   ├── pi3/                       ← BCM2837 / B0
│   ├── pi2/                       ← BCM2836 / BCM2837
│   ├── pi1/                       ← BCM2835, 32-bit only
│   ├── pi-zero-w/                 ← Zero & Zero W (OTG gadget)
│   └── pi-zero-2w/                ← Zero 2 W (64-bit quad-core)
├── boot/                          ← files for the BOOT partition
│   ├── README.md
│   ├── ssh                        ← empty file: enables SSH on first boot
│   ├── config.txt.append          ← universal (all models) firmware template
│   └── cmdline.txt.example        ← headless kernel arguments (reference)
├── tools/
│   ├── README.md
│   └── make-userconf.sh           ← run on your PC: create userconf.txt
├── rootfs/                        ← mirrors "/" on the Pi; setup.sh copies it in
│   ├── README.md                  ← what each installed file does
│   ├── etc/…                      ← system config (SSH, firewall, logs, …)
│   └── usr/local/bin/             ← pi-status, pi-backup
└── optional/                      ← NOT installed automatically
    ├── README.md
    ├── sshd-keys-only.conf        ← disable SSH passwords (if you have a key)
    ├── home-wifi.nmconnection     ← offline Wi-Fi + static IP profile
    └── myapp.service              ← template to run your own program at boot
```

Each folder has its own `README.md` explaining exactly what it contains — start
there when you want to change part of the kit.

---

## 2. Hardware compatibility

| Model | SoC / CPU | Default clock | Headless RAM | Power supply | Fast storage | Bluetooth off via |
|---|---|---|---|---|---|---|
| **Pi 5** | BCM2712 (4× A76) | 2.4 GHz | dynamic CMA (ignores `gpu_mem`) | **5V / 5.0A (27W PD)** | M.2 NVMe HAT+ (PCIe Gen 2/3) | `dtparam=bluetooth=off` |
| **Pi 4 / 400** | BCM2711 (4× A72) | 1.5–1.8 GHz | `gpu_mem=16` | **5V / 3.0A (15W USB-C)** | USB 3.0 SSD boot (EEPROM) | `dtoverlay=disable-bt` |
| **Pi 3 B / B+** | BCM2837 / B0 (4× A53) | 1.2–1.4 GHz | `gpu_mem=16` | **5V / 2.5A (micro-USB)** | USB 2.0 boot / microSD | `dtoverlay=disable-bt` |
| **Pi 2 B** | BCM2836 / 7 (4× A7/A53) | 900 MHz | `gpu_mem=16` | **5V / 1.8–2.0A** | microSD | N/A (no onboard BT) |
| **Pi 1 (A/B/A+/B+)** | BCM2835 (1× ARM11) | 700 MHz | `gpu_mem=16` | **5V / 1.2A** | SD / microSD | N/A (no onboard BT) |
| **Pi Zero 2 W** | RP3A0 (4× A53) | 1.0 GHz | `gpu_mem=16` | **5V / 1.5–2.0A** | USB OTG gadget / microSD | `dtoverlay=disable-bt` |
| **Pi Zero / Zero W** | BCM2835 (1× ARM11) | 1.0 GHz | `gpu_mem=16` | **5V / 1.2A** | USB OTG gadget / microSD | `dtoverlay=disable-bt` |

For pinouts, cooling advice, and overclocking tables, see
[`models/README.md`](models/README.md) and the per-model READMEs.

---

## 3. Boot vs root: where does each file go?

A Raspberry Pi storage medium (microSD or SSD) has **two partitions**:

```
 SD card / SSD
 ├── Partition 1: BOOT   (FAT32, "bootfs")   ← readable from Windows/macOS/Linux
 │      mounted at /boot/firmware (Bookworm/Trixie) or /boot (Bullseye)
 │      read by the firmware BEFORE Linux starts
 └── Partition 2: ROOT   (ext4, "rootfs")    ← the Linux system, mounted at /
        readable natively only from Linux
```

| File | Destination | When | Why there |
|---|---|---|---|
| `boot/ssh` (empty) | **BOOT** | before first boot | Tells Raspberry Pi OS to start SSH immediately. |
| `userconf.txt` | **BOOT** | before first boot | Creates the initial user/password (Bullseye/Bookworm; use Imager on Trixie+). |
| `boot/config.txt.append` | **BOOT** → append to `config.txt` | before first boot | Firmware settings; read before the kernel loads. |
| `boot/cmdline.txt.example` | **BOOT** → reference for `cmdline.txt` | before first boot | Single-line kernel arguments (quiet boot, USB gadget). |
| the whole `rpi-configuration/` folder | **BOOT** | before first boot | FAT32 is cross-platform, so it is the easiest way to carry the kit onto the Pi offline. |
| everything in `rootfs/` | **ROOT** (`/`) | after first boot | Installed into `/` with strict permissions by `setup.sh`. |
| `optional/home-wifi.nmconnection` | **ROOT**: `/etc/NetworkManager/system-connections/` | before first boot | Offline headless Wi-Fi + static IP (needs `chmod 600`). |
| `optional/sshd-keys-only.conf` | **ROOT**: `/etc/ssh/sshd_config.d/` | after key check | Installed by `setup.sh` only if `~/.ssh/authorized_keys` exists. |

---

## 4. Step-by-step setup

### Step A — on your PC

**Preferred method:** flash Raspberry Pi OS with **Raspberry Pi Imager** and open
the advanced settings (`Ctrl + Shift + X` or the gear icon) to set the hostname,
username, SSH public key, Wi-Fi, and locale. This is the official, most reliable
path and is required on Trixie and newer.

**Manual offline method:**

1. **Enable SSH:** copy `boot/ssh` to the BOOT partition.
2. **Create a user:** on Linux/macOS/WSL run `tools/make-userconf.sh` and place
   the resulting `userconf.txt` in BOOT (Bullseye/Bookworm only).
3. **Carry the kit:** copy the whole `rpi-configuration/` folder to BOOT.
4. Insert the card into the Pi and power it on.

### Step B — over SSH, on the Pi

```bash
ssh youruser@yourhost.local          # or ssh youruser@<ip>
cd /boot/firmware/rpi-configuration   # /boot/rpi-configuration on Bullseye
cp setup.conf.example setup.conf      # optional: keep your edits out of setup.sh
sudo nano setup.conf                  # HOSTNAME, TIMEZONE, STATIC_IP, packages…
sudo bash setup.sh
sudo reboot
```

`setup.sh` will:

1. Update the system and install the base packages.
2. **Auto-detect your Pi model** and append the matching
   `models/<model>/config.txt.append`.
3. Set the `HOSTNAME` in `/etc/hostname` and `/etc/hosts`.
4. Install the config files from `rootfs/` into `/`.
5. Configure SSH hardening, the firewall (`ufw`), `fail2ban`, the watchdog,
   journal size limits, and a RAM-backed `/tmp`.
6. Enable unattended security updates.

> **Editing settings:** you can either create `setup.conf` (recommended, keeps
> the installer clean) **or** edit the default block at the top of `setup.sh`.
> Values in `setup.conf` override the built-in defaults.

### Step C — verify

```bash
pi-status                          # CPU/PMIC temps, throttling flags, RAM, disk
sudo ufw status verbose            # firewall rules
sudo fail2ban-client status sshd   # intrusion-prevention status
systemctl status unattended-upgrades
```

---

## 5. Security & system architecture

```
 External network ─► [ufw firewall] ─► [fail2ban] ─► [sshd rules] ─► [SSH key only]
                      rate-limited 22   temp-bans     no root login   passwords disabled
                      mDNS (5353/udp)   5 failures    max 4 tries     (if a key is present)
```

- **Watchdog** (`/etc/systemd/system.conf.d/watchdog.conf`): arms the hardware
  watchdog (`RuntimeWatchdogSec=15`). If the kernel locks up, the Pi hard-reboots.
- **Unattended security updates** (`20auto-upgrades`, `50unattended-upgrades`):
  daily security patches, no automatic reboots.
- **Log limits** (`size.conf`): journal capped at 100 MB to protect the SD card.
- **Network resilience** (`wifi-powersave-off.conf`): disables Wi-Fi power saving
  to avoid SSH latency spikes and dropped sessions.

---

## 6. Backups: `pi-backup`

`pi-backup` mirrors selected folders with `rsync` (a **mirror**, not versioned
history). It ships **disabled** until you configure a destination:

```bash
sudo nano /etc/pi-backup.conf         # set BACKUP_SOURCES and BACKUP_DEST
sudo systemctl enable --now pi-backup.timer   # run it daily
sudo systemctl start pi-backup                # or run once now
journalctl -u pi-backup -n 50 --no-pager      # check the result
```

Full details are in [`rootfs/README.md`](rootfs/README.md).

---

## 7. Static IP & networking

Raspberry Pi OS **Bookworm** and **Trixie** use **NetworkManager** by default.

- Easiest way: set `SET_STATIC_IP="yes"` in `setup.conf` (or `setup.sh`) along
  with the IP details.
- Manually with `nmcli`:
  ```bash
  sudo nmcli con mod "preconfigured" ipv4.method manual \
       ipv4.addresses 192.168.1.50/24 ipv4.gateway 192.168.1.1 ipv4.dns "1.1.1.1,9.9.9.9"
  sudo reboot
  ```
- **Bullseye (`dhcpcd`):** configure static addresses in `/etc/dhcpcd.conf`
  instead. See [`optional/home-wifi.nmconnection`](optional/home-wifi.nmconnection)
  for the offline NetworkManager profile.

---

## 8. High-reliability boot (USB 3.0 & NVMe)

SD cards are the most common point of failure on 24/7 nodes. For production use:

- **Pi 5 (NVMe boot):** official M.2 HAT+ → `sudo raspi-config` → Advanced →
  Boot Order → NVMe/USB Boot. See [`models/pi5/README.md`](models/pi5/README.md).
- **Pi 4 (USB 3.0 SSD boot):** attach a UAS-compatible USB 3.0 SSD enclosure and
  update the bootloader EEPROM. See [`models/pi4/README.md`](models/pi4/README.md).

---

## 9. Reusing this kit in other projects

The repository is designed to be forked, trimmed, or embedded:

- **Bring your own config:** drop files into `rootfs/etc/...` or
  `rootfs/usr/local/bin/...`; `setup.sh` installs them with the right ownership
  and permissions. `usr/local/bin/*` is made executable automatically.
- **Bring your own boot tweaks:** add a `models/<model>/config.txt.append`; the
  auto-detection and idempotent marker handling already apply.
- **Tune without forking:** copy `setup.conf.example` to `setup.conf` and edit.
- **Run your own service:** start from [`optional/myapp.service`](optional/myapp.service).
- **License:** MIT — see [`LICENSE`](LICENSE). Reuse, modify and redistribute freely.

If you only need part of the kit, copy the relevant folder — each one is
self-contained and documented on its own.

---

## 10. Glossary & further reading

- [`docs/GLOSSARY.md`](docs/GLOSSARY.md) — every acronym and term explained.
- [`models/README.md`](models/README.md) — per-model details and overclocking.
- [`boot/README.md`](boot/README.md) — what lives on the BOOT partition.
- [`rootfs/README.md`](rootfs/README.md) — every file installed into `/`.
- [`tools/README.md`](tools/README.md) — host-side helper scripts.
- [`optional/README.md`](optional/README.md) — extras installed by hand.

## License

MIT — see [`LICENSE`](LICENSE).
