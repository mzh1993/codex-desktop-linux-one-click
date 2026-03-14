# Codex Desktop Linux One-Click

> Unofficial one-click Codex Desktop compatibility build for Ubuntu 20.04 and other older Linux hosts.
>
> The goal is simple: get a usable desktop Codex experience **without upgrading the kernel, replacing the distro, or touching the host toolchain**.

![Ubuntu 20.04 Compatible](https://img.shields.io/badge/Ubuntu-20.04%20compatible-E95420)
![Docker Build](https://img.shields.io/badge/build-Docker-2496ED)
![No Kernel Upgrade](https://img.shields.io/badge/host-no%20kernel%20upgrade-2E8B57)
![License MIT](https://img.shields.io/badge/license-MIT-black)

## Why this project matters

A lot of Linux users are blocked in exactly the same way:

- the machine is stable, but old
- the business environment does not allow distro or kernel upgrades
- native modules break on older glibc targets
- Electron behaves badly on Ubuntu 20.04 + X11 + NVIDIA
- manual conversion leaves no clean launcher, icon, or desktop integration

This repository packages the full workaround into a reproducible one-command flow.

## What you get

- Ubuntu 20.04-friendly build path
- no kernel upgrade required
- no host compiler replacement required
- one-click Docker build
- rebuilt native modules for better old-system compatibility
- Linux black-window fix for the desktop app
- launcher, icon, desktop shortcut, and GNOME favorites support

## Best fit

This repo is a strong fit if you want to run Codex Desktop on:

- Ubuntu 20.04
- older Linux workstations
- controlled production or enterprise machines
- hosts where changing the base OS is higher risk than containerizing the build

## Quick start

```bash
git clone https://github.com/mzh1993/codex-desktop-linux-one-click.git
cd codex-desktop-linux-one-click
chmod +x one-click-install.sh
./one-click-install.sh
```

Launch immediately after build:

```bash
./one-click-install.sh --run
```

## How it works

The one-click path does all of this for you:

- builds inside Docker with `ubuntu:20.04`
- downloads the official `Codex.dmg`
- extracts the macOS app bundle with bundled 7-Zip
- rebuilds `better-sqlite3` and `node-pty` with `clang-18` + `libc++`
- keeps the native output compatible with Ubuntu 20.04 glibc
- bundles runtime libraries into `codex-app/runtime-libs/`
- patches the Linux Electron window background to avoid the common black-window issue on older Ubuntu + X11 + NVIDIA setups
- installs an app launcher, icon, GNOME favorites-compatible entry, and a desktop shortcut

## Requirements

Build-time:

- Docker
- working network access inside Docker

Run-time:

- host `codex` CLI available in `PATH`

Install the CLI if needed:

```bash
npm i -g @openai/codex
```

## Output after install

After a successful run, you get:

- app directory: `codex-app/`
- launcher: `~/.local/share/applications/codex-desktop.desktop`
- icon: `~/.local/share/icons/hicolor/512x512/apps/codex-desktop.png`
- desktop shortcut: `~/Desktop/Codex.desktop` when a desktop folder exists

Run manually at any time:

```bash
./codex-app/start.sh
```

## Main scripts

- `one-click-install.sh` - recommended public entrypoint
- `build-in-docker.sh` - Ubuntu 20.04 Docker build flow
- `install.sh` - low-level conversion, rebuild, patch, and packaging logic

## Useful overrides

If Docker Hub access is unstable:

```bash
BASE_IMAGE=m.daocloud.io/docker.io/library/ubuntu:20.04 ./one-click-install.sh
```

If Electron download access is unstable:

```bash
ELECTRON_DOWNLOAD_URL='https://npmmirror.com/mirrors/electron/40.0.0/electron-v40.0.0-linux-x64.zip' ./one-click-install.sh
```

## Notes

- this project automates conversion for a user's own copy of the official app
- `Codex.dmg` and generated `codex-app/` are intentionally ignored from source control
- `start.sh` already clears `ELECTRON_RUN_AS_NODE` and adds `--no-sandbox`
- do not add `--disable-gpu` with the current bundle
- this is an unofficial community workaround, not an official Linux release from OpenAI

## License

MIT
