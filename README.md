# Codex Desktop Linux One-Click

One-click Codex Desktop for Ubuntu 20.04 and other older Linux hosts, without upgrading the kernel or replacing the system compiler.

This repository converts the official macOS Codex Desktop app into a Linux desktop app, rebuilds the native modules in an Ubuntu 20.04-compatible environment, applies the Linux black-window fix, and installs desktop integration on the host.

## Quick Start

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

## What The One-Click Path Does

- builds inside Docker with `ubuntu:20.04`
- rebuilds native modules with `clang-18` + `libc++`
- keeps the output compatible with Ubuntu 20.04 glibc
- bundles required runtime libraries into `codex-app/runtime-libs/`
- patches the Linux Electron window background to avoid the common black-window issue on older Ubuntu + X11 + NVIDIA setups
- installs an app launcher, icon, GNOME favorites-compatible entry, and a desktop shortcut

## Requirements

For the recommended path:
- Docker
- network access inside Docker
- host `codex` CLI in `PATH` when launching the desktop app

Install the CLI if needed:

```bash
npm i -g @openai/codex
```

## Main Scripts

- `one-click-install.sh` - recommended entrypoint
- `build-in-docker.sh` - Docker build path used by the one-click script
- `install.sh` - low-level DMG conversion and patch flow

## Output

After a successful build:
- app directory: `codex-app/`
- launcher: `~/.local/share/applications/codex-desktop.desktop`
- icon: `~/.local/share/icons/hicolor/512x512/apps/codex-desktop.png`
- desktop shortcut: `~/Desktop/Codex.desktop` when a desktop folder exists

Run manually:

```bash
./codex-app/start.sh
```

## Network Overrides

If Docker Hub access is unstable:

```bash
BASE_IMAGE=m.daocloud.io/docker.io/library/ubuntu:20.04 ./one-click-install.sh
```

If Electron download access is unstable:

```bash
ELECTRON_DOWNLOAD_URL='https://npmmirror.com/mirrors/electron/40.0.0/electron-v40.0.0-linux-x64.zip' ./one-click-install.sh
```

## Notes

- this repository is designed to automate conversion for a user's own copy of the official app
- `Codex.dmg` and generated `codex-app/` are intentionally ignored from source control
- `start.sh` already clears `ELECTRON_RUN_AS_NODE` and adds `--no-sandbox`
- do not use `--disable-gpu` with the current bundle

## License

MIT
