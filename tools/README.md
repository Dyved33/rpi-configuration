# `tools/` — host-side helper scripts

Scripts in this folder are meant to be run on **your own PC** (Linux, macOS,
WSL, or Git Bash) *before* you first boot the Pi — not on the Pi itself.

> New to the terms? See [`../docs/GLOSSARY.md`](../docs/GLOSSARY.md).

## `make-userconf.sh`

Creates a `userconf.txt` file that Raspberry Pi OS reads from the BOOT partition
on first boot to create your initial user account. This lets you set up a
brand-new Pi **without a monitor or keyboard**.

```sh
bash tools/make-userconf.sh
# -> asks for a username and password, then writes ./userconf.txt
```

Then copy `userconf.txt` to the BOOT partition (alongside the empty `ssh` file).

**Details:**

- The password is hashed with `openssl passwd -6` (SHA-512), never stored in
  plain text. `openssl` must be installed on your PC.
- Supported on **Bullseye and Bookworm**. On **Trixie and newer**, the
  recommended method is to set the user and SSH key with **Raspberry Pi Imager**
  (gear icon / `Ctrl+Shift+X`) instead.
- `userconf.txt` is git-ignored because it contains credentials.

## Related

- [`../boot/README.md`](../boot/README.md) — what goes on the BOOT partition.
- [`../README.md`](../README.md) — full setup walkthrough.
