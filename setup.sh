#!/usr/bin/env bash
# Run ON THE PI:   sudo bash setup.sh
set -euo pipefail

############ EDIT THESE BEFORE RUNNING ############
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

log "1/10 Updating system and installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y full-upgrade
apt-get -y install ufw fail2ban unattended-upgrades avahi-daemon $EXTRA_PACKAGES

log "2/10 Timezone, locale, keyboard, Wi-Fi country"
timedatectl set-timezone "$TIMEZONE" || warn "timezone failed"
if command -v raspi-config >/dev/null; then
  raspi-config nonint do_change_locale "$LOCALE"               || warn "locale failed"
  raspi-config nonint do_configure_keyboard "$KEYBOARD_LAYOUT" || warn "keyboard failed"
  raspi-config nonint do_wifi_country "$WIFI_COUNTRY"          || warn "wifi country failed"
fi
timedatectl set-ntp true || true

log "3/10 Installing config files from rootfs/ into /"
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

log "4/10 SSH hardening"
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

log "5/10 Network: Wi-Fi power saving off, optional static IP"
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

log "6/10 mDNS (hostname.local)"
systemctl enable --now avahi-daemon

log "7/10 /tmp in RAM, sysctl, journald, watchdog"
if ! findmnt -n -t tmpfs /tmp >/dev/null 2>&1; then systemctl enable tmp.mount || true; fi
sysctl --system >/dev/null
systemctl restart systemd-journald
systemctl daemon-reexec

log "8/10 Automatic security updates"
systemctl enable --now unattended-upgrades

log "9/10 fail2ban"
if [ "$ENABLE_FAIL2BAN" = "yes" ]; then systemctl enable fail2ban; systemctl restart fail2ban; fi

log "10/10 Firewall (ufw)"
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
