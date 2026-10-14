# `rootfs/` — files copied into the Pi's filesystem

This folder **mirrors the layout of `/` on the Pi**. When you run `setup.sh`, it
copies every file here to the same path on the real system (creating directories
as needed) while setting `root:root` ownership and safe permissions. Executables
under `usr/local/bin/` are installed `0755` (executable); everything else `0644`.

In short: if you want a file at `/etc/foo.conf` on the Pi, you put it at
`rootfs/etc/foo.conf` in this repository.

> New to the terms? See [`../docs/GLOSSARY.md`](../docs/GLOSSARY.md).

## What gets installed, and why

| Path on the Pi | Purpose |
|---|---|
| `/etc/ssh/sshd_config.d/10-hardening.conf` | SSH hardening: no root login, no empty passwords, no X11, max 4 tries. Named `10-*` so it is read first (in SSH, the first value wins). |
| `/etc/fail2ban/jail.d/sshd.local` | Bans IPs after 5 failed SSH logins within 10 minutes (1-hour ban). |
| `/etc/apt/apt.conf.d/20auto-upgrades` | Enables the daily automatic update check. |
| `/etc/apt/apt.conf.d/50unattended-upgrades` | Installs security updates automatically; never auto-reboots. |
| `/etc/NetworkManager/conf.d/wifi-powersave-off.conf` | Disables Wi-Fi power saving to prevent SSH lag/drops. |
| `/etc/systemd/journald.conf.d/size.conf` | Caps logs (100 MB system / 50 MB runtime) to protect the SD card. |
| `/etc/systemd/system.conf.d/watchdog.conf` | Arms the hardware watchdog so a frozen Pi reboots itself. |
| `/etc/systemd/system/pi-backup.service` | One-shot service that runs the backup script. |
| `/etc/systemd/system/pi-backup.timer` | Runs the backup **daily**. Disabled until you enable it (see below). |
| `/etc/sysctl.d/99-pi.conf` | Kernel tuning: low swappiness, basic network hardening. |
| `/etc/profile.d/pi-aliases.sh` | Convenience aliases (`ll`, `update`, `temp`, `status`, …) for interactive shells. |
| `/etc/pi-backup.conf` | Configuration for the backup tool (sources + destination). |
| `/usr/local/bin/pi-status` | `pi-status` — prints a one-page health report. |
| `/usr/local/bin/pi-backup` | `pi-backup` — mirrors selected folders with `rsync`. |

Files under this folder can be extended freely: add `rootfs/etc/...` and
`rootfs/usr/local/bin/...` and `setup.sh` will install them the same way.

## The backup tool (`pi-backup`)

`pi-backup` is a thin `rsync` wrapper. It is **a mirror, not versioned history**:
the destination always matches the source (deletions propagate).

**1. Configure it** — edit `/etc/pi-backup.conf` on the Pi:

```sh
BACKUP_SOURCES="/home /etc /usr/local"
BACKUP_DEST="user@nas:/backups/pi"     # or /mnt/usb/pi-backup ; empty = disabled
```

**2. Enable the daily timer** (it is not enabled automatically):

```sh
sudo systemctl enable --now pi-backup.timer
```

**3. Run one backup now / inspect results:**

```sh
sudo systemctl start pi-backup
journalctl -u pi-backup -n 50 --no-pager
```

If `BACKUP_DEST` is empty, `pi-backup` exits without doing anything — safe by
default. Set it before enabling the timer.

## Related

- [`../README.md`](../README.md) — full setup walkthrough.
- [`../optional/README.md`](../optional/README.md) — files that are **not**
  installed automatically.
