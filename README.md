# pi-config — headless Raspberry Pi OS setup kit

A small kit that takes a freshly flashed Raspberry Pi OS and turns it into a secure, stable, headless machine you manage over SSH. Every file is plain text, so you can read it, understand it and change it.

---

## 1. What is in this kit

```
pi-config/
├── README.md                      ← this file
├── setup.sh                       ← the installer, run ON the Pi
├── boot/
│   ├── ssh                        ← empty file: enables SSH           (BOOT partition)
│   └── config.txt.append          ← lines to add to config.txt        (BOOT partition)
├── tools/
│   └── make-userconf.sh           ← run on your PC: creates userconf.txt
├── rootfs/                        ← mirrors "/" on the Pi; setup.sh copies it in
│   ├── etc/
│   │   ├── ssh/sshd_config.d/10-hardening.conf
│   │   ├── fail2ban/jail.d/sshd.local
│   │   ├── apt/apt.conf.d/20auto-upgrades
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

## 2. Boot vs root: where does each file go?

A Raspberry Pi SD card has **two partitions**:

```
 SD card
 ├── Partition 1: BOOT   (FAT32, "bootfs")   ← visible from Windows/macOS/Linux
 │      mounted on the Pi at /boot/firmware     read by the firmware BEFORE Linux starts
 └── Partition 2: ROOT   (ext4, "rootfs")    ← the real Linux system "/"
        only readable directly from Linux
```

| File | Goes to | When | Why there |
|---|---|---|---|
| `ssh` (empty) | **boot** | before first boot | Raspberry Pi OS looks for it at boot and enables the SSH server |
| `userconf.txt` | **boot** | before first boot | creates your user (there is no default `pi` user anymore) |
| `config.txt.append` | **boot** → content appended to `config.txt` | before first boot | `config.txt` is read by the firmware, so hardware settings must live on the boot partition |
| `pi-config/` (the whole folder) | **boot** (just as a carrier) | before first boot | FAT is readable from any PC, so it is the easiest way to move files onto the Pi |
| everything in `rootfs/` | **root** (`/`) | after first boot | `setup.sh` copies each file to its real path, with correct owner and permissions |
| `optional/home-wifi.nmconnection` | **root**: `/etc/NetworkManager/system-connections/` | before first boot, only from a Linux PC | lets the Pi join Wi-Fi with a static IP at the very first boot |
| `optional/sshd-keys-only.conf` | **root** (automatic) | by `setup.sh`, only if a key exists | disables password login safely |
| `optional/myapp.service` | **root**: `/etc/systemd/system/` | manual, when you have an app | auto-start your program |

You never need to copy `rootfs/` files by hand: `setup.sh` does it.

---

## 3. Step-by-step

### Step A — On your PC, with the SD card inserted

**Easiest route:** flash with **Raspberry Pi Imager** and use *OS customisation* (hostname, user, Wi-Fi, SSH key, locale). It does steps 1–3 below for you. Then continue from step 4.

**Manual route:**

1. **Enable SSH** — copy `boot/ssh` to the boot partition (an empty file named exactly `ssh`, no extension).
2. **Create the user** — run `tools/make-userconf.sh` (Linux, macOS, WSL or Git Bash). It writes `userconf.txt`. Copy it to the boot partition.
   (It contains `username:hashed-password`, so the password is never stored in clear text.)
3. **Wi-Fi**, depending on your OS version (see section 6):
   - **Bookworm / Trixie (NetworkManager):** the old `wpa_supplicant.conf` trick in the boot partition **is ignored**. Use Imager, **or** plug in an Ethernet cable for the first boot, **or** use `optional/home-wifi.nmconnection` from a Linux PC.
   - **Bullseye or older:** copy your `wpa_supplicant.conf` to the boot partition.
4. **Append the hardware tweaks** — open `config.txt` on the boot partition and paste the content of `boot/config.txt.append` at the **end**. Also change `dtparam=audio=on` to `dtparam=audio=off` if you do not need audio.
5. **Carry the kit** — copy the whole `pi-config/` folder to the boot partition.
6. Eject the card, put it in the Pi, power on, wait 1–2 minutes.

### Step B — On the Pi, over SSH

```bash
ssh youruser@hostname.local          # or ssh youruser@192.168.x.x

# (recommended) put your public key on the Pi, from your PC:
#   ssh-copy-id youruser@hostname.local
# Do this BEFORE running setup.sh so password login can be switched off.

cd /boot/firmware/pi-config          # older OS: /boot/pi-config
nano setup.sh                        # edit the variables at the top
sudo bash setup.sh
sudo reboot
```

(`sudo bash setup.sh` is used instead of `./setup.sh` because the FAT boot partition has no "executable" permission.)

### Step C — Verify

```bash
pi-status                         # temperature, power, RAM, disk, failed services
sudo ufw status verbose           # firewall rules
sudo fail2ban-client status sshd  # SSH ban status
systemctl status unattended-upgrades
timedatectl                       # timezone + NTP sync
ip -4 -br addr                    # your IP address
```

---

## 4. How it fits together

```
            first boot
  ┌────────────────────────────────┐
  │ Firmware reads BOOT partition  │  config.txt  (hardware settings)
  └───────────────┬────────────────┘
                  ▼
  ┌────────────────────────────────┐
  │ Linux starts, mounts ROOT      │
  │  • sees `ssh`       → starts sshd
  │  • sees userconf.txt → creates your user
  │  • NetworkManager   → joins Wi-Fi
  └───────────────┬────────────────┘
                  ▼   you: ssh in, run  sudo bash setup.sh
  ┌────────────────────────────────┐
  │ setup.sh                       │
  │  1 apt update/upgrade + tools  │
  │  2 timezone/locale/keyboard    │
  │  3 copy rootfs/ → /            │
  │  4 SSH hardening               │
  │  5 network tweaks / static IP  │
  │  6-8 mDNS, tmpfs, sysctl,      │
  │      journald, watchdog, auto-updates
  │  9 fail2ban   10 ufw firewall  │
  └────────────────────────────────┘
```

Security layers, from outside in:

```
 Internet/LAN ─► [ufw firewall] ─► [fail2ban] ─► [sshd rules] ─► [SSH key] ─► your shell
                 only port 22      bans IPs      no root login    no password
                 (rate-limited)    after 5 fails  max 4 tries      allowed
```

---

## 5. File-by-file explanation

### `setup.sh`
The installer. Edit the block at the top: timezone, locale, keyboard, Wi-Fi country, optional static IP, and on/off switches for firewall, fail2ban and watchdog. It is safe to run again; it just re-applies the same state.
Safety rule: it **only disables SSH password login if `~/.ssh/authorized_keys` exists**, and it runs `sshd -t` (config test) before reloading SSH, so a typo cannot lock you out.

### `rootfs/etc/ssh/sshd_config.d/10-hardening.conf`
Disables root login, X11 forwarding and empty passwords, limits login attempts to 4 and the login window to 30 seconds, and drops dead sessions after ~10 minutes. The `10-` prefix matters: sshd uses the **first** value it finds, so this file wins over later ones.

### `optional/sshd-keys-only.conf` → `20-keys-only.conf`
Turns off password login entirely. Brute-force guessing becomes pointless because only your private key works.

### `rootfs/etc/fail2ban/jail.d/sshd.local`
Watches the SSH log; 5 failures within 10 minutes → that IP is banned for 1 hour. `backend = systemd` is needed because modern Pi OS logs to the journal, not to `/var/log/auth.log`.

### `ufw` (configured in `setup.sh`)
Default: block all incoming, allow all outgoing. Allows SSH (rate-limited: `ufw limit`) and mDNS (UDP 5353, so `hostname.local` keeps working). **Any service you add needs a rule**, e.g. `sudo ufw allow 8080/tcp`.

### `rootfs/etc/apt/apt.conf.d/20auto-upgrades`
Refreshes the package lists daily and installs security updates automatically. No automatic reboot.

### `rootfs/etc/NetworkManager/conf.d/wifi-powersave-off.conf`
Wi-Fi power saving makes the radio sleep, which shows up as laggy or dropped SSH sessions. `2` means "disabled". Takes effect at the next reconnect/reboot.

### `rootfs/etc/systemd/journald.conf.d/size.conf`
Limits the system log to 100 MB on disk (50 MB in RAM) and keeps one month, so logs can never fill the SD card.

### `rootfs/etc/systemd/system.conf.d/watchdog.conf`
Enables the Pi's hardware watchdog. systemd "pets" it every few seconds; if the system freezes completely, the chip resets the Pi after 15 s. Good for a machine you cannot reach physically.

### `rootfs/etc/sysctl.d/99-pi.conf`
`vm.swappiness=10` makes Linux prefer RAM over swap (less SD wear). The network lines ignore ICMP redirects and source-routed packets. IPv6 disabling is there but commented out.

### `rootfs/etc/profile.d/pi-aliases.sh`
Shortcuts for SSH sessions: `ll`, `update`, `temp`, `myip`, `ports`, `logs`, `status`.

### `rootfs/usr/local/bin/pi-status`
One command that prints IP, temperature, **throttling/under-voltage flags** (decoded from `vcgencmd get_throttled`), RAM, disk and failed services. Under-voltage warnings point to a bad power supply or cable, which is the #1 cause of weird Pi behaviour.

### `rootfs/usr/local/bin/pi-backup`, `etc/pi-backup.conf`, `pi-backup.{service,timer}`
An rsync **mirror** of selected folders. It does nothing until you set `BACKUP_DEST` in `/etc/pi-backup.conf`. Then enable the daily timer:
```bash
sudo nano /etc/pi-backup.conf
sudo systemctl enable --now pi-backup.timer
systemctl list-timers pi-backup.timer
```
It is a copy, not history: if you delete a file on the Pi, the next run deletes it from the backup too. For versioned backups look at `restic` or `borg`.

### `boot/config.txt.append`
Hardware options read by the firmware. Only `disable_splash=1` is active; the rest (GPU memory, Bluetooth off, LEDs off, overclock) are commented examples. Remember: comments in `config.txt` must be on their own line.

### `optional/myapp.service`
Template systemd unit to run your own program (for example your Go backend) at boot and restart it on crash. Replace `YOUR_USER` and the paths, then follow the commands in the header.

---

## 6. Static IP and Wi-Fi: how it works

### Bookworm / Trixie (NetworkManager) — current Raspberry Pi OS
- Wi-Fi and IP are stored in NetworkManager "connection profiles" (`/etc/NetworkManager/system-connections/*.nmconnection`).
- Static IP with the script: set `SET_STATIC_IP="yes"` plus `STATIC_IP`, `GATEWAY`, `DNS_SERVERS`; it runs `nmcli connection modify …`. It applies **after reboot**, so your current SSH session is not cut mid-script.
- Manually:
  ```bash
  nmcli -p connection show                       # list profiles
  sudo nmcli con mod "PROFILE" ipv4.method manual \
       ipv4.addresses 192.168.1.50/24 ipv4.gateway 192.168.1.1 ipv4.dns "1.1.1.1,9.9.9.9"
  sudo reboot
  ```
- **Pick an IP outside your router's DHCP range** (or reserve it in the router), otherwise two devices can end up with the same address.
- Prefer a router-side DHCP reservation if you can: no config on the Pi, same result.

### Older OS (Bullseye)
- `wpa_supplicant.conf` in the boot partition **works**. Keep the `country=` line.
- Static IP lives in `/etc/dhcpcd.conf`:
  ```
  interface wlan0
  static ip_address=192.168.1.50/24
  static routers=192.168.1.1
  static domain_name_servers=1.1.1.1 9.9.9.9
  ```
- `setup.sh` detects the absence of NetworkManager and skips step 5; the rest still works.

### Keep the Wi-Fi password private
Your `wpa_supplicant.conf` and `.nmconnection` hold the password in clear text. Never post them. A hashed version for `wpa_supplicant`: `wpa_passphrase "SSID" "password"` (use the `psk=` hash it prints).

---

## 7. If something goes wrong

| Symptom | Fix |
|---|---|
| Pi never appears on the network | Wi-Fi file ignored (Bookworm). Use Imager, Ethernet, or `home-wifi.nmconnection`. Check country code and 2.4/5 GHz support. |
| `hostname.local` does not resolve | Use the IP. On Windows, install Bonjour (or use a recent Windows 11). Check `avahi-daemon` is running and UDP 5353 is allowed. |
| Locked out after hardening | Put the SD card in your PC and delete `/etc/ssh/sshd_config.d/20-keys-only.conf` (root partition, Linux), or re-flash. |
| Banned by fail2ban | From another host: `sudo fail2ban-client set sshd unbanip YOUR.IP` or wait 1 hour. |
| A service is unreachable | Firewall. `sudo ufw allow PORT/tcp`, check with `sudo ufw status`. |
| Random freezes/reboots | Run `pi-status`: look for under-voltage. Try a better power supply/cable. |
| `setup.sh: bad interpreter` or `\r` errors | The file got Windows line endings. `sed -i 's/\r$//' setup.sh` |
| Static IP wrong after reboot | `nmcli -p connection show "PROFILE"`; verify `ipv4.method manual`. |
| Want to undo something | Delete the file from `/etc/...` that you do not want (each one is independent), then reboot. |

---

## 8. Optional extras (not included on purpose)

- **Change SSH port:** `Port 2222` in a `sshd_config.d` file, then `ufw allow 2222/tcp` and fix `port =` in the fail2ban jail. Caveat: if your OS uses **`ssh.socket`** activation, the port is set in the socket unit instead (`systemctl edit ssh.socket`). Test with a second open session before closing the first one. Note that this is obscurity, not security; keys already protect you.
- **Remote access from outside home:** use a VPN such as **WireGuard** or **Tailscale** instead of opening ports on your router.
- **Reduce SD wear further:** `log2ram`, or boot from an **SSD/USB drive** (best upgrade for reliability).
- **File sharing:** `sudo apt install samba` (+ `ufw allow samba`).
- **Alerts:** send mail/Telegram/ntfy from a systemd `OnFailure=` unit when a service fails.
- **Disable Wi-Fi/Bluetooth you do not use:** `dtoverlay=disable-wifi`, `dtoverlay=disable-bt` in `config.txt`.
- **Docker:** `curl -fsSL https://get.docker.com | sh` (read the script first) and add your user to the `docker` group.

---

## 9. Quick glossary

- **Boot partition** – small FAT32 partition with firmware files and `config.txt`.
- **Root partition** – the ext4 partition holding the actual Linux system.
- **NetworkManager** – the tool that manages network connections in current Pi OS.
- **systemd** – the init system: starts services, timers, logging.
- **sshd / authorized_keys** – SSH server / list of public keys allowed to log in.
- **ufw** – "Uncomplicated Firewall", a friendly front end for the kernel firewall.
- **fail2ban** – bans IPs that repeatedly fail to authenticate.
- **watchdog** – hardware timer that reboots a frozen machine.
- **mDNS / avahi** – lets you reach the Pi by name (`hostname.local`) without a DNS server.
- **tmpfs** – a filesystem that lives in RAM (fast, no SD writes, lost on reboot).
