#!/usr/bin/env bash
# Run ON THE PI:   sudo bash setup.sh
set -euo pipefail

############ EDIT THESE BEFORE RUNNING ############
HOSTNAME="raspberrypi"            # unique name for this Pi (e.g. pi-sensor, pi-nas)
TIMEZONE="Europe/Rome"
LOCALE="en_GB.UTF-8"
KEYBOARD_LAYOUT="it"
WIFI_COUNTRY="IT"

# Static IP through NetworkManager (Bookworm/Trixie). "no" if you already did it.
SET_STATIC_IP="no"
NET_DEVICE="wlan0"
STATIC_IP="192.168.1.50/24"
GATEWAY="192.168.1.1"
DNS_SERVERS="1.1.1.1 9.9.9.9"

ENABLE_UFW="yes"          # firewall: deny incoming except SSH (+mDNS)
ENABLE_FAIL2BAN="yes"     # ban IPs that fail SSH logins repeatedly
ENABLE_WATCHDOG="yes"     # auto-reboot on freeze
EXTRA_PACKAGES="htop tmux git vim rsync curl ncdu"
###################################################

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log()  { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*" >&2; }

[ "$(id -u)" -eq 0 ] || { echo "Run with: sudo bash setup.sh"; exit 1; }
[ -d "$SRC/rootfs" ] || { echo "rootfs/ folder not found next to setup.sh"; exit 1; }
TARGET_USER="${SUDO_USER:-}"

# --- Detect Pi model ---
PI_MODEL="unknown"
if [ -f /proc/device-tree/model ]; then
  PI_MODEL_FULL="$(tr -d '\0' < /proc/device-tree/model)"
  case "$PI_MODEL_FULL" in
    *"Pi 5"*)        PI_MODEL="pi5"       ;;
    *"Pi 4"*|*"Pi 400"*) PI_MODEL="pi4"  ;;
    *"Pi 3"*)        PI_MODEL="pi3"       ;;
    *"Pi 2"*)        PI_MODEL="pi2"       ;;
    *"Pi Model"*|*"Pi 1"*) PI_MODEL="pi1" ;;
    *"Pi Zero 2"*)   PI_MODEL="pi-zero-2w" ;;
    *"Pi Zero"*)     PI_MODEL="pi-zero-w" ;;
  esac
  echo "Detected model: $PI_MODEL_FULL  →  config group: $PI_MODEL"
else
  warn "Could not read /proc/device-tree/model — model-specific config.txt will be skipped"
fi

log "1/11 Updating system and installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y full-upgrade
apt-get -y install ufw fail2ban unattended-upgrades avahi-daemon $EXTRA_PACKAGES

log "2/11 Hostname"
if [ -n "$HOSTNAME" ] && [ "$HOSTNAME" != "$(hostname)" ]; then
  hostnamectl set-hostname "$HOSTNAME"
  # Update /etc/hosts so 127.0.1.1 points to the new name
  sed -i "s/127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
  echo "  hostname set to $HOSTNAME"
else
  echo "  hostname unchanged: $(hostname)"
fi

log "3/11 Timezone, locale, keyboard, Wi-Fi country"
timedatectl set-timezone "$TIMEZONE" || warn "timezone failed"
if command -v raspi-config >/dev/null; then
  raspi-config nonint do_change_locale "$LOCALE"               || warn "locale failed"
  raspi-config nonint do_configure_keyboard "$KEYBOARD_LAYOUT" || warn "keyboard failed"
  raspi-config nonint do_wifi_country "$WIFI_COUNTRY"          || warn "wifi country failed"
fi
timedatectl set-ntp true || true

log "4/11 Installing config files from rootfs/ into /"
while IFS= read -r -d '' f; do
  rel="${f#./}"
  mode=0644
  case "$rel" in usr/local/bin/*) mode=0755 ;; esac
  install -D -m "$mode" -o root -g root "$SRC/rootfs/$rel" "/$rel"
  sed -i 's/\r$//' "/$rel"      # strip Windows line endings if any
  echo "  /$rel"
done < <(cd "$SRC/rootfs" && find . -type f -print0)
[ "$ENABLE_WATCHDOG" = "yes" ] || rm -f /etc/systemd/system.conf.d/watchdog.conf
[ "$ENABLE_FAIL2BAN" = "yes" ] || rm -f /etc/fail2ban/jail.d/sshd.local

# Apply model-specific config.txt if the model folder exists
if [ "$PI_MODEL" != "unknown" ] && [ -f "$SRC/models/$PI_MODEL/config.txt.append" ]; then
  BOOT_CONFIG=""
  for bc in /boot/firmware/config.txt /boot/config.txt; do
    [ -f "$bc" ] && { BOOT_CONFIG="$bc"; break; }
  done
  if [ -n "$BOOT_CONFIG" ]; then
    if ! grep -q "pi-config: $PI_MODEL" "$BOOT_CONFIG" 2>/dev/null; then
      printf '\n# --- pi-config: %s ---\n' "$PI_MODEL" >> "$BOOT_CONFIG"
      cat "$SRC/models/$PI_MODEL/config.txt.append" >> "$BOOT_CONFIG"
      echo "  appended models/$PI_MODEL/config.txt.append to $BOOT_CONFIG"
    else
      echo "  model config already present in $BOOT_CONFIG (skipping)"
    fi
  else
    warn "Could not find config.txt (tried /boot/firmware/ and /boot/)"
  fi
else
  if [ "$PI_MODEL" = "unknown" ]; then
    warn "Model unknown — skipping model-specific config.txt"
  else
    warn "No model folder found at $SRC/models/$PI_MODEL/ — skipping model-specific config"
  fi
fi

log "5/11 SSH hardening"
KEYS_OK="no"
if [ -n "$TARGET_USER" ]; then
  HOME_DIR="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  if [ -s "$HOME_DIR/.ssh/authorized_keys" ]; then KEYS_OK="yes"; fi
fi
if [ "$KEYS_OK" = "yes" ]; then
  install -D -m 0644 "$SRC/optional/sshd-keys-only.conf" /etc/ssh/sshd_config.d/20-keys-only.conf
  echo "  authorized_keys found -> password login DISABLED"
else
  warn "No ~/.ssh/authorized_keys for '$TARGET_USER' -> password login stays ON. Add your key, then re-run this script."
fi
if sshd -t; then
  systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
else
  warn "sshd config test FAILED — removing my SSH files, nothing reloaded"
  rm -f /etc/ssh/sshd_config.d/10-hardening.conf /etc/ssh/sshd_config.d/20-keys-only.conf
fi

log "6/11 Network: Wi-Fi power saving off, optional static IP"
if command -v nmcli >/dev/null; then
  systemctl reload NetworkManager || true
  if [ "$SET_STATIC_IP" = "yes" ]; then
    CONN="$(nmcli -g GENERAL.CONNECTION device show "$NET_DEVICE" || true)"
    if [ -n "$CONN" ]; then
      nmcli connection modify "$CONN" ipv4.method manual \
        ipv4.addresses "$STATIC_IP" ipv4.gateway "$GATEWAY" ipv4.dns "${DNS_SERVERS// /,}"
      echo "  static IP $STATIC_IP set on '$CONN' (applies after reboot)"
    else
      warn "No active connection on $NET_DEVICE — static IP skipped"
    fi
  fi
else
  warn "NetworkManager not found (older OS?) — see README, section 'Older OS (Bullseye)'"
fi

log "7/11 mDNS (hostname.local)"
systemctl enable --now avahi-daemon

log "8/11 /tmp in RAM, sysctl, journald, watchdog"
# Mount /tmp as tmpfs — try the systemd unit first, fall back to fstab
if ! findmnt -n -t tmpfs /tmp >/dev/null 2>&1; then
  if systemctl enable tmp.mount 2>/dev/null; then
    echo "  tmp.mount enabled"
  else
    # tmp.mount not available (Bookworm/Trixie) — use fstab instead
    if ! grep -q 'tmpfs.*/tmp' /etc/fstab 2>/dev/null; then
      echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,size=128M 0 0" >> /etc/fstab
      echo "  /tmp tmpfs added to /etc/fstab (active after reboot)"
    fi
  fi
fi
sysctl --system >/dev/null
systemctl restart systemd-journald
systemctl daemon-reexec

log "9/11 Automatic security updates"
systemctl enable --now unattended-upgrades

log "10/11 fail2ban"
if [ "$ENABLE_FAIL2BAN" = "yes" ]; then systemctl enable fail2ban; systemctl restart fail2ban; fi

log "11/11 Firewall (ufw)"
if [ "$ENABLE_UFW" = "yes" ]; then
  ufw default deny incoming
  ufw default allow outgoing
  ufw limit 22/tcp
  ufw allow 5353/udp
  ufw --force enable
  echo "  Need other ports? e.g.: sudo ufw allow 8080/tcp"
fi

log "DONE. Reboot to apply everything:  sudo reboot"
echo "After reboot check:  pi-status   |   sudo ufw status   |   sudo fail2ban-client status sshd"
