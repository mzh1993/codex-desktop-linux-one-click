# Codex Desktop for Linux

Run [OpenAI Codex Desktop](https://openai.com/codex/) on Linux, including older hosts such as Ubuntu 20.04.

The official Codex Desktop app is macOS-only. This repository automates the conversion of the official macOS `.dmg` into a Linux desktop app by rebuilding the native modules, downloading Linux Electron, and wiring up desktop integration.

## Recommended One-Click Path

For Ubuntu 20.04 and other older Linux hosts, use the Docker-based one-click path:

```bash
chmod +x one-click-install.sh
./one-click-install.sh
```

This path:
- builds inside an Ubuntu 20.04-compatible container
- rebuilds native modules with `clang-18` + `libc++`
- bundles required runtime libraries for older hosts
- installs an app launcher, icon, and desktop shortcut on the host

If you want the app to launch immediately after install:

```bash
./one-click-install.sh --run
```

## Why This Repo Exists

Older Linux hosts often fail to run Codex Desktop through a naive port because of several environment issues:
- old `p7zip` cannot unpack the current DMG format
- Ubuntu 20.04 `gcc/g++ 9.4` is too old for Electron 40 native rebuilds
- building inside Ubuntu 24.04 produces native modules that require newer glibc than Ubuntu 20.04 provides
- `Ubuntu 20.04 + X11 + NVIDIA` can show a black window unless the Electron background behavior is patched for Linux

This repository bakes those fixes into the install flow.

## What Is Verified

This repository was validated on a local Ubuntu 20.04 host with:
- host runtime target: Ubuntu 20.04
- build path: Docker `ubuntu:20.04`
- native rebuild toolchain: `clang-18` + `libc++`
- runtime fix: bundled `libc++`, `libc++abi`, `libunwind`
- display fix: Linux opaque-window patch for the Electron shell
- desktop integration: app menu entry, icon, GNOME `Add to Favorites`, desktop shortcut

See `SOLUTION_REVIEW_ZH.md` and `DEPLOYMENT_FAILURE_REPORT.md` for the full troubleshooting history.

## Prerequisites

### Recommended path

For `./one-click-install.sh` and `./build-in-docker.sh`:
- Docker
- network access inside Docker
- host Codex CLI available in `PATH` when you actually launch the app

Install the host CLI if needed:

```bash
npm i -g @openai/codex
```

### Manual host build path

Use `install.sh` only if your host toolchain is already modern enough.

Host dependencies:
- Node.js 20+
- npm
- Python 3
- `curl`
- `unzip`
- build tools (`gcc`, `g++`, `make`)
- `7z` or bundled `7zz`

## Installation Options

### Option A: One-click recommended path

```bash
git clone <your-fork-url>
cd codex-desktop-linux
./one-click-install.sh
```

### Option B: Docker build path directly

```bash
chmod +x build-in-docker.sh
./build-in-docker.sh
```

### Option C: Manual host build path

```bash
chmod +x install.sh
./install.sh
```

Or provide your own DMG:

```bash
./install.sh /path/to/Codex.dmg
```

## Output

After a successful build, the generated app is placed in:

```bash
codex-app/
```

You can launch it with:

```bash
./codex-app/start.sh
```

The install flow also creates:
- app menu entry: `~/.local/share/applications/codex-desktop.desktop`
- icon: `~/.local/share/icons/hicolor/512x512/apps/codex-desktop.png`
- desktop shortcut: `~/Desktop/Codex.desktop` when a desktop folder exists

The launcher sets `StartupWMClass=Codex`, so GNOME can pin it correctly through `Add to Favorites`.

## Mirrors and Network Overrides

If Docker Hub access is unstable:

```bash
BASE_IMAGE=m.daocloud.io/docker.io/library/ubuntu:20.04 ./one-click-install.sh
```

If Electron download access is unstable:

```bash
ELECTRON_DOWNLOAD_URL='https://npmmirror.com/mirrors/electron/40.0.0/electron-v40.0.0-linux-x64.zip' ./one-click-install.sh
```

## Troubleshooting

- `CODEX_CLI_PATH` or missing `codex`: install the CLI with `npm i -g @openai/codex`
- Blank or black window on Ubuntu 20.04 + X11 + NVIDIA: rebuild with the current repo version; the Linux opaque-window patch is already included
- Do not use `--disable-gpu` with the current bundle; this app expects GPU access
- Sandbox errors: `start.sh` already adds `--no-sandbox`
- Launching from a Codex CLI shell: `start.sh` already clears `ELECTRON_RUN_AS_NODE`
- Port `5175` conflicts: check with `lsof -i :5175`

## Repository Notes

- `one-click-install.sh` is the main user-facing entrypoint
- `build-in-docker.sh` is the stable old-Linux build path
- `install.sh` contains the low-level DMG conversion flow
- `GITHUB_METADATA_ZH.md` contains suggested repo naming, description, and topics
- `RELEASE_NOTES_v0.1.0.md` is a ready-to-use first release draft
- `assets/codex-desktop.png` is a community-made Linux launcher icon included for desktop integration
- `.gitignore` excludes `Codex.dmg`, `codex-app/`, and local Docker state so you can publish the repo without redistributing app binaries

## Disclaimer

This is an unofficial community project. Codex Desktop is a product of OpenAI. This repository is designed to automate conversion for a user's own copy of the official app and should not be used to redistribute OpenAI desktop binaries.

## License

MIT
