#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-codex-desktop-linux-builder}"
CONTAINER_WORKDIR="/workspace"
CONTAINER_HOME="$CONTAINER_WORKDIR/.docker-home"
DOCKER_BIN="${DOCKER_BIN:-docker}"
BASE_IMAGE="${BASE_IMAGE:-ubuntu:20.04}"
ELECTRON_DOWNLOAD_URL="${ELECTRON_DOWNLOAD_URL:-}"

if ! command -v "$DOCKER_BIN" >/dev/null 2>&1; then
  echo "Error: docker not found. Install Docker or set DOCKER_BIN." >&2
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/install.sh" ]; then
  echo "Error: install.sh not found in $SCRIPT_DIR" >&2
  exit 1
fi

DOCKER_RUN_TTY=()
if [ -t 0 ] && [ -t 1 ]; then
  DOCKER_RUN_TTY=(-it)
fi

mkdir -p "$SCRIPT_DIR/.docker-home"

install_host_icon() {
  local icon_source="$SCRIPT_DIR/assets/codex-desktop.png"
  local icon_base_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
  local themed_icon_dir="$icon_base_dir/512x512/apps"

  if [ ! -f "$icon_source" ]; then
    echo "Warning: icon source not found: $icon_source" >&2
    return
  fi

  mkdir -p "$SCRIPT_DIR/codex-app" "$themed_icon_dir"
  cp "$icon_source" "$SCRIPT_DIR/codex-app/codex-desktop.png"
  cp "$icon_source" "$themed_icon_dir/codex-desktop.png"

  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$icon_base_dir" >/dev/null 2>&1 || true
  fi

  echo "Host icon updated: $themed_icon_dir/codex-desktop.png" >&2
}

create_host_desktop_entry() {
  local applications_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  local desktop_file="$applications_dir/codex-desktop.desktop"
  mkdir -p "$applications_dir"

  cat > "$desktop_file" <<EOF2
[Desktop Entry]
Type=Application
Name=Codex
Comment=OpenAI Codex Desktop on Linux
Exec=$SCRIPT_DIR/codex-app/start.sh %U
Icon=codex-desktop
Terminal=false
Categories=Development;
Keywords=OpenAI;Codex;AI;Coding;Assistant;
StartupNotify=true
StartupWMClass=Codex
EOF2

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
  fi

  echo "Desktop entry updated: $desktop_file" >&2
}

create_host_desktop_shortcut() {
  local applications_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  local source_file="$applications_dir/codex-desktop.desktop"
  local desktop_dir=""
  local shortcut_file=""

  desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
  [ -n "$desktop_dir" ] || desktop_dir="$HOME/Desktop"

  mkdir -p "$desktop_dir"
  shortcut_file="$desktop_dir/Codex.desktop"
  cp "$source_file" "$shortcut_file"
  chmod +x "$shortcut_file"

  if command -v gio >/dev/null 2>&1; then
    if ! gio set "$shortcut_file" metadata::trusted true >/dev/null 2>&1; then
      gio set "$shortcut_file" metadata::trusted yes >/dev/null 2>&1 || true
    fi
  fi

  echo "Desktop shortcut updated: $shortcut_file" >&2
}

echo "Building image with BASE_IMAGE=$BASE_IMAGE" >&2
env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u all_proxy -u no_proxy -u NO_PROXY \
  "$DOCKER_BIN" build \
  --build-arg BASE_IMAGE="$BASE_IMAGE" \
  --build-arg http_proxy= \
  --build-arg https_proxy= \
  --build-arg HTTP_PROXY= \
  --build-arg HTTPS_PROXY= \
  --build-arg ALL_PROXY= \
  --build-arg all_proxy= \
  --build-arg no_proxy= \
  --build-arg NO_PROXY= \
  -t "$IMAGE_NAME" \
  "$SCRIPT_DIR"

RUN_ENV=(
  -e http_proxy=
  -e https_proxy=
  -e HTTP_PROXY=
  -e HTTPS_PROXY=
  -e ALL_PROXY=
  -e all_proxy=
  -e no_proxy=
  -e NO_PROXY=
  -e HOME="$CONTAINER_HOME"
  -e CODEX_INSTALL_DIR="$CONTAINER_WORKDIR/codex-app"
  -e CODEX_SKIP_DESKTOP_ENTRY=1
)

if [ -n "$ELECTRON_DOWNLOAD_URL" ]; then
  RUN_ENV+=( -e ELECTRON_DOWNLOAD_URL="$ELECTRON_DOWNLOAD_URL" )
fi

env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u all_proxy -u no_proxy -u NO_PROXY \
  "$DOCKER_BIN" run --rm "${DOCKER_RUN_TTY[@]}" \
  --user "$(id -u):$(id -g)" \
  "${RUN_ENV[@]}" \
  -v "$SCRIPT_DIR:$CONTAINER_WORKDIR" \
  -w "$CONTAINER_WORKDIR" \
  "$IMAGE_NAME" \
  bash -lc 'mkdir -p "$HOME" && ./install.sh'

chmod +x "$SCRIPT_DIR/codex-app/start.sh"
install_host_icon
create_host_desktop_entry
create_host_desktop_shortcut

echo "Docker build finished. Run: $SCRIPT_DIR/codex-app/start.sh" >&2
