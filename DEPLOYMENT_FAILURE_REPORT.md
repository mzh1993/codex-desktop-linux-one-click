# Deployment Failure and Resolution Report

Date: 2026-03-14
Repository: `codex-desktop-linux`
Environment: local Ubuntu 20.04 host

## Current conclusion

The original deployment failures were caused by local environment and toolchain constraints, not by a basic repository syntax problem.

A working and low-risk deployment path has now been validated on this machine.

Current recommended path:
- keep the host Ubuntu 20.04 system and kernel unchanged
- do not replace the host default `gcc` / `g++`
- build inside Docker with an Ubuntu 20.04 base image
- rebuild native modules in the container with `clang-18` + `libc++`
- run the generated desktop app on the host via `codex-app/start.sh`

This path avoids both host compiler incompatibility and newer-glibc runtime breakage.

## Final validated result

The following outcome was validated on the host:
- `codex-app/` was generated successfully
- `codex-app/start.sh` launched the desktop app on the host
- a `Codex` window was observed during launch validation
- `~/.local/share/applications/codex-desktop.desktop` was created/refreshed

Important runtime note:
- the host still needs a working `codex` CLI in `PATH`
- if launched from a shell that exports `ELECTRON_RUN_AS_NODE=1`, the launcher must clear that variable before starting Electron
- the current `start.sh` already handles this

## Recommended deployment path for this machine

Use the Docker-based Ubuntu 20.04-compatible build path.

Primary command:

```bash
./build-in-docker.sh
```

If Docker Hub access is unstable on this network, use a mirror base image:

```bash
BASE_IMAGE=m.daocloud.io/docker.io/library/ubuntu:20.04 ./build-in-docker.sh
```

If Electron download access is unstable, a mirror can also be supplied:

```bash
ELECTRON_DOWNLOAD_URL='https://npmmirror.com/mirrors/electron/40.0.0/electron-v40.0.0-linux-x64.zip' ./build-in-docker.sh
```

Run on the host after build:

```bash
./codex-app/start.sh
```

## Why this is the recommended path

This is the best path for this Ubuntu 20.04 machine because it:
- avoids a kernel upgrade
- avoids a distro upgrade
- avoids changing the host default compiler
- keeps newer compiler/runtime requirements isolated inside Docker
- produces host-runnable native modules compatible with Ubuntu 20.04

This is safer than trying to modernize the host toolchain for one project.

## Historical blockers encountered during deployment

The items below are still useful as a troubleshooting record, but they are no longer the final recommendation.

### 1. System `p7zip` was too old for the current Codex DMG

Observed behavior:
- the host `7z` could not open the official `Codex.dmg`
- installation stopped at the DMG extraction step

Root cause:
- the Ubuntu 20.04-era `p7zip` on this machine was too old for the DMG format used by the current Codex desktop package

Mitigation applied in this repo:
- `install.sh` now prefers a bundled modern `7zz` when available
- a newer 7-Zip binary was placed at `.tools/7z2409/7zz`
- installer logic now tolerates the non-zero extraction result caused by the DMG's macOS `/Applications` symlink, as long as `Codex.app` was actually extracted

Status:
- mitigated
- no longer a blocker on this repo

### 2. Host GCC 9.4 was too old for Electron 40 native module rebuilds

Observed environment:
- host compiler: `g++ (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0`

Observed failures:
- `g++ 9.4` did not accept the expected `-std=gnu++20` / `-std=c++20` flow reliably for this dependency stack
- after a temporary compatibility remap to `c++2a`, the build still failed on missing modern standard library headers
- the final blocking error included:

```text
fatal error: compare: No such file or directory
```

Root cause:
- Electron `40.0.0` native module rebuilds require a newer C++20-capable compiler and standard library than the host GCC 9.4 environment provides

Important note about the temporary flag mapping:
- the earlier compiler flag compatibility mapping for old GCC was only an intermediate troubleshooting experiment
- it helped confirm the real limitation was the host toolchain itself
- it is not the current recommended solution

Status:
- confirmed as a real host limitation
- superseded by the Docker Ubuntu 20.04 + `clang-18` build path

### 3. `apt` was temporarily blocked by malformed third-party source configuration

Observed issue during host-toolchain troubleshooting:
- a malformed third-party APT source entry caused `apt` operations to fail before package resolution

Impact at the time:
- host-side package installation and package availability checks were interrupted
- this blocked the earlier idea of installing a newer compiler directly on the host

Interpretation:
- this was a host package-management problem
- it was not caused by the Codex Desktop repository itself

Status:
- historical environment issue only
- not part of the final recommended deployment path

### 4. Ubuntu 24.04 container builds produced a glibc runtime mismatch on Ubuntu 20.04

A later experiment did produce `codex-app/`, but the host could not run it.

Observed runtime error:

```text
Error: /lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.38' not found
```

Root cause:
- native modules rebuilt inside a newer container ended up depending on newer glibc symbols than the Ubuntu 20.04 host provides

Practical conclusion:
- building on Ubuntu 24.04 was not sufficient if the output had to run on Ubuntu 20.04
- this was a runtime ABI mismatch, not an Electron windowing problem

Status:
- superseded by rebuilding in an Ubuntu 20.04-based container

## Repository changes made during troubleshooting

The repository was updated so the deployment path now matches the host constraints better.

### `install.sh`

Changes made:
- prefer bundled modern `7zz`
- handle DMG extraction warnings more safely
- rebuild Linux native modules
- bundle required runtime libraries into `codex-app/runtime-libs/`
- generate a launcher that sets `LD_LIBRARY_PATH`
- clear `ELECTRON_RUN_AS_NODE` before launching Electron
- continue to support host-side use after container build output is copied back

### `build-in-docker.sh`

Changes made:
- default to an Ubuntu 20.04 base image
- run the container as the current host user
- use repo-local Docker home state
- refresh the host desktop entry after build

### `Dockerfile`

Changes made:
- use `ubuntu:20.04`
- install `clang-18`, `libc++-18-dev`, and `libc++abi-18-dev`
- rebuild native modules against an Ubuntu 20.04-compatible libc baseline
- support bundling `libc++`, `libc++abi`, and `libunwind` runtime libraries

### Documentation

Updated files:
- `README.md`
- `DOCKER_USAGE.md`
- `DEPLOYMENT_FAILURE_REPORT.md`

These now describe the working Ubuntu 20.04-compatible Docker path instead of presenting host GCC upgrade as the primary solution.

## Files most relevant to the final working path

- `Dockerfile`
- `build-in-docker.sh`
- `install.sh`
- `README.md`
- `DOCKER_USAGE.md`
- `codex-app/start.sh`
- `codex-app/runtime-libs/`
- `~/.local/share/applications/codex-desktop.desktop`

## Operational notes

- The Docker build may print a container-internal warning that `codex` CLI is not available inside the container.
- This does not block the final host launch, because the desktop app uses the host CLI when `codex-app/start.sh` is executed on the host.
- If the app is started from a shell session created by Codex CLI itself, clearing `ELECTRON_RUN_AS_NODE` is necessary; this is already handled in the launcher.

## Final recommendation

For this machine, the recommended path is:
- do not upgrade the Ubuntu 20.04 kernel just for Codex Desktop
- do not switch the host default compiler globally
- do not treat the old GCC compatibility wrapper as the deployment fix
- keep the host stable and use the validated Ubuntu 20.04 Docker build path

In short:

```bash
./build-in-docker.sh
./codex-app/start.sh
```
