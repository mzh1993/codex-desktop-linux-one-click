# Release v0.1.0

## What This Release Solves

This release packages a practical way to run Codex Desktop on Ubuntu 20.04 and other older Linux hosts without upgrading the kernel or replacing the system compiler.

## Highlights

- one-click install entrypoint via `./one-click-install.sh`
- Ubuntu 20.04-compatible Docker build path
- native module rebuild with `clang-18` + `libc++`
- bundled runtime libraries for older glibc hosts
- Linux black-screen fix for `Ubuntu 20.04 + X11 + NVIDIA`
- app icon, desktop launcher, GNOME `Add to Favorites`, and desktop shortcut support

## Recommended Usage

```bash
./one-click-install.sh
```

Or launch immediately after install:

```bash
./one-click-install.sh --run
```

## Notes

- host `codex` CLI still needs to exist in `PATH` when launching the desktop app
- this repository is designed to automate conversion for a user's own copy of the official app
- `Codex.dmg` and generated `codex-app/` are intentionally not included as source-controlled artifacts

## Main Documents

- `README.md`
- `README_ZH.md`
- `SOLUTION_REVIEW_ZH.md`
- `PUBLISHING_CHECKLIST_ZH.md`
- `DEPLOYMENT_FAILURE_REPORT.md`
