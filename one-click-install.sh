#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUN_AFTER_INSTALL=0

usage() {
  cat <<'USAGE'
Usage: ./one-click-install.sh [--run]

Recommended one-click path for Ubuntu 20.04 and other older Linux hosts.
It builds Codex Desktop in an Ubuntu 20.04 Docker image, installs desktop
integration, and leaves a runnable app in ./codex-app.

Options:
  --run   Launch Codex Desktop immediately after a successful build
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --run) RUN_AFTER_INSTALL=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker is required for the recommended one-click path." >&2
  echo "Install Docker first, then rerun ./one-click-install.sh" >&2
  exit 1
fi

echo "============================================" >&2
echo " Codex Desktop One-Click Installer" >&2
echo "============================================" >&2
echo "Recommended path: Ubuntu 20.04-compatible Docker build" >&2
echo >&2

"$SCRIPT_DIR/build-in-docker.sh"

echo >&2
echo "Build completed." >&2
echo "- Launch from app menu: Codex" >&2
echo "- Or desktop shortcut: ~/Desktop/Codex.desktop" >&2
echo "- Or terminal: $SCRIPT_DIR/codex-app/start.sh" >&2

if ! command -v codex >/dev/null 2>&1; then
  echo >&2
  echo "Note: host Codex CLI not found in PATH." >&2
  echo "Install it with: npm i -g @openai/codex" >&2
fi

if [ "$RUN_AFTER_INSTALL" = "1" ]; then
  exec "$SCRIPT_DIR/codex-app/start.sh"
fi
