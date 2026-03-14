# Docker Build Path

This is the recommended build path for Ubuntu 20.04 and other older Linux hosts.

If you just want the simplest entrypoint, use:

```bash
./one-click-install.sh
```

If you want the Docker path directly, use:

```bash
./build-in-docker.sh
```

## What This Path Does

- builds in an `ubuntu:20.04` container
- rebuilds native modules with `clang-18` + `libc++`
- keeps the final ABI compatible with Ubuntu 20.04 hosts
- bundles `libc++`, `libc++abi`, and `libunwind` into `codex-app/runtime-libs/`
- copies the generated app back into this repository
- refreshes host desktop integration after build

## Prerequisites

- Docker installed and usable by your current user
- network access inside Docker
- host Codex CLI available when launching the app

Check Docker:

```bash
docker --version
docker run --rm hello-world
```

Install the host CLI if needed:

```bash
npm i -g @openai/codex
```

## Output After Build

After a successful build you should have:
- `codex-app/`
- `~/.local/share/applications/codex-desktop.desktop`
- `~/.local/share/icons/hicolor/512x512/apps/codex-desktop.png`
- `~/Desktop/Codex.desktop` when a desktop folder exists

Run on host:

```bash
./codex-app/start.sh
```

## Network Overrides

If Docker Hub access is unstable:

```bash
BASE_IMAGE=m.daocloud.io/docker.io/library/ubuntu:20.04 ./build-in-docker.sh
```

If Electron download access is unstable:

```bash
ELECTRON_DOWNLOAD_URL='https://npmmirror.com/mirrors/electron/40.0.0/electron-v40.0.0-linux-x64.zip' ./build-in-docker.sh
```

## Why This Path Is Preferred

Compared with direct host builds, this path avoids:
- relying on Ubuntu 20.04 `gcc/g++ 9.4`
- producing Ubuntu 24.04-linked native modules that require newer glibc
- asking users to replace the system compiler globally
- most host-side ABI and toolchain drift problems
