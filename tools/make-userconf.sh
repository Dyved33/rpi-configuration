#!/usr/bin/env bash
# Run on your PC (Linux, macOS, WSL or Git Bash). Creates ./userconf.txt
# in the current directory; copy the result to the BOOT partition of the SD card.
#
# Note: userconf.txt is supported on Bullseye & Bookworm. On newer distributions
# (Trixie+), the official and recommended method is pre-configuring credentials
# via Raspberry Pi Imager. Requires `openssl` on your PC.
set -euo pipefail
read -rp  "Username for the Pi: " U
read -rsp "Password: " P; echo
read -rsp "Repeat password: " P2; echo
[ "$P" = "$P2" ] || { echo "Passwords do not match."; exit 1; }
HASH="$(printf '%s' "$P" | openssl passwd -6 -stdin)"
printf '%s:%s\n' "$U" "$HASH" > userconf.txt
echo "Created userconf.txt -> copy it to the boot partition."
