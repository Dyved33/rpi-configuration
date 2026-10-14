# `optional/` — extras you install by hand

Nothing in this folder is installed automatically by `setup.sh`. These are
templates and profiles you copy into place **only when you need them**.

> New to the terms? See [`../docs/GLOSSARY.md`](../docs/GLOSSARY.md).

## Contents

| File | Use it when… | How to install |
|---|---|---|
| `sshd-keys-only.conf` | You have an SSH public key and want to **disable password logins**. | `setup.sh` installs this **only if** `~/.ssh/authorized_keys` exists. To do it manually: `sudo cp sshd-keys-only.conf /etc/ssh/sshd_config.d/20-keys-only.conf && sudo sshd -t && sudo systemctl reload ssh`. |
| `home-wifi.nmconnection` | You need Wi-Fi **and** a static IP set up **offline**, before first boot. | Fill in the placeholders, then copy it to `<rootfs>/etc/NetworkManager/system-connections/` and `chmod 600` it (see below). |
| `myapp.service` | You want your own program (script, server, …) to start at boot and restart if it crashes. | Edit the `YOUR_USER`/paths, then `sudo cp myapp.service /etc/systemd/system/myapp.service && sudo systemctl daemon-reload && sudo systemctl enable --now myapp`. |

## `home-wifi.nmconnection` — offline Wi-Fi + static IP

NetworkManager ignores this file unless it has the correct permissions, so the
steps matter:

1. Mount the SD card's **rootfs** (ext4) partition on your Linux PC.
2. Edit the file: set `uuid` (run `uuidgen`), `ssid`, `psk`, and the `ipv4`
   address/gateway/DNS values.
3. Copy it to `<rootfs>/etc/NetworkManager/system-connections/home-wifi.nmconnection`.
4. Set ownership/permissions:
   ```sh
   sudo chown root:root <that file>
   sudo chmod 600 <that file>          # NetworkManager refuses world-readable profiles
   ```

You can also create the same profile after boot with `nmcli` — see the
"Static IP & NetworkManager" section of the root README.

## `myapp.service` — run your program at boot

A minimal, reasonably hardened systemd unit template:

- `After=/Wants=network-online.target` — start only once the network is up.
- `Restart=on-failure` + `RestartSec=5` — restart automatically if it exits badly.
- `NoNewPrivileges=true` — a basic sandboxing measure.

Follow the pointer in the file itself for logging:
`journalctl -u myapp -f`.

## Related

- [`../rootfs/README.md`](../rootfs/README.md) — files installed automatically.
- [`../README.md`](../README.md) — full setup walkthrough.
