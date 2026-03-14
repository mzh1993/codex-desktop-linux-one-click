# Codex Desktop Linux One-Click

Run Codex Desktop on Ubuntu 20.04 and other older Linux hosts without upgrading the kernel, replacing the system compiler, or changing the host distro.

This repository is an unofficial compatibility build path for people who want a desktop Codex experience on older Linux machines, especially hosts where system upgrades are risky or simply not allowed.

## Why this repo exists

Older Linux environments can fail to run Codex Desktop cleanly because of a few common issues:

- native modules built against newer glibc expectations
- Electron runtime mismatch on older hosts
- black or transparent main window on Ubuntu 20.04 + X11 + NVIDIA
- missing desktop launcher and icon integration after manual conversion

This repository turns that into a one-command workflow.

## Best fit

Use this repository if you want:

- Ubuntu 20.04 compatibility
- a low-risk path that avoids kernel and distro upgrades
- a desktop launcher, icon, and GNOME favorites integration
- a reproducible build flow you can rerun on similar machines

## What the one-click flow does

- builds inside Docker with `ubuntu:20.04`
- downloads the official `Codex.dmg`
- extracts the macOS app bundle with bundled 7-Zip
- rebuilds `better-sqlite3` and `node-pty` with `clang-18` + `libc++`
- keeps the native output compatible with Ubuntu 20.04 glibc
- bundles required runtime libraries into `codex-app/runtime-libs/`
- patches the Linux Electron window background to avoid the common black-window issue on older Ubuntu + X11 + NVIDIA setups
- installs an app launcher, icon, GNOME favorites-compatible entry, and a desktop shortcut

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

## Requirements

Build-time:

- Docker
- working network access inside Docker

Run-time:

- host `codex` CLI in `PATH`

Install the CLI if needed:

```bash
npm i -g @openai/codex
```

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

## Main scripts

- `one-click-install.sh` - recommended entrypoint
- `build-in-docker.sh` - Docker build path used by the one-click script
- `install.sh` - low-level conversion and patch flow

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

- this repository is designed to automate conversion for a user's own copy of the official app
- `Codex.dmg` and generated `codex-app/` are intentionally ignored from source control
- `start.sh` already clears `ELECTRON_RUN_AS_NODE` and adds `--no-sandbox`
- do not add `--disable-gpu` with the current bundle
- this is an unofficial community workaround, not an official Linux release from OpenAI

## License

MIT
