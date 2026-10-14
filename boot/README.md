# `boot/` — files for the BOOT partition

This folder contains files that live on the **first (FAT32) partition** of the
SD card or SSD — the one your PC can read even on Windows/macOS. The Raspberry Pi
firmware reads these files **before Linux starts**, so they are used to enable
services and tune the hardware at boot time.

> New to the terms? See [`../docs/GLOSSARY.md`](../docs/GLOSSARY.md) (sections
> "Boot & firmware" and "USB gadget mode").

## Contents

| File | What it is | Where it goes |
|---|---|---|
| `ssh` | An **empty** file. Its mere presence tells Raspberry Pi OS to start the SSH server on first boot. | Copy to the root of the BOOT partition. |
| `config.txt.append` | A **universal** `config.txt` template showing all common headless tweaks. | Append its contents to the existing `config.txt` on BOOT. |
| `cmdline.txt.example` | Documentation for headless kernel arguments — **not** used automatically. | Read it, then edit `cmdline.txt` by hand. |

## Why two "config" files?

- `config.txt` is read by the **firmware** (before the kernel). It controls boot
  behaviour and hardware. Values go in model-specific sections like `[pi4]`.
- `cmdline.txt` is passed to the **Linux kernel**. Everything must be on **one
  single line** — no newlines, no comments.

## `config.txt.append` vs `models/*/config.txt.append`

- This file (`boot/config.txt.append`) is a **universal reference**: all options
  for all models, mostly commented out. Use it if you are editing manually.
- Each `models/<model>/config.txt.append` is a **pre-tuned** file for one model.
  `setup.sh` detects your Pi and appends the matching one automatically.

You normally do **not** need to touch this folder if you run `setup.sh`, except
for the empty `ssh` file (needed the very first time you boot).

## Safety notes

- `config.txt` **comments must be on their own line** (a `#` after a value is not
  treated as a comment). `cmdline.txt` allows **no** comments at all.
- After editing `config.txt`/`cmdline.txt`, reboot to apply changes.
- If the Pi fails to boot after an edit, mount the BOOT partition on a PC and
  undo the change.

## Related

- [`../models/README.md`](../models/README.md) — per-model boot configuration.
- [`../README.md`](../README.md) — full setup walkthrough.
