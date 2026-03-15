#!/bin/bash
set -Eeuo pipefail

# ============================================================================
# Codex Desktop for Linux - Installer
# Converts the official macOS Codex Desktop app to run on Linux
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${CODEX_INSTALL_DIR:-$SCRIPT_DIR/codex-app}"
ELECTRON_VERSION="40.0.0"
WORK_DIR="$(mktemp -d)"
ARCH="$(uname -m)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
  echo -e "${GREEN}[INFO]${NC} $*" >&2
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
  exit 1
}

cleanup() {
  rm -rf "$WORK_DIR"
}

trap cleanup EXIT
trap 'error "Failed at line $LINENO (exit code $?)"' ERR

SEVEN_Z_CMD=""

resolve_7z() {
  if [ -n "${SEVEN_Z_CMD:-}" ]; then
    return
  fi

  local candidate
  for candidate in "$SCRIPT_DIR/.tools/7z2409/7zz" "$(command -v 7zz 2>/dev/null || true)" "$(command -v 7z 2>/dev/null || true)"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      SEVEN_Z_CMD="$candidate"
      return
    fi
  done

  error "No compatible 7-Zip binary found. Put a recent 7zz at $SCRIPT_DIR/.tools/7z2409/7zz or install 7zip."
}

check_deps() {
  local missing=()

  for cmd in node npm npx python3 curl unzip; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done

  if [ ${#missing[@]} -ne 0 ]; then
    error "Missing dependencies: ${missing[*]}
Install them first:
  sudo apt install nodejs npm python3 p7zip-full curl unzip build-essential  # Debian/Ubuntu
  sudo dnf install nodejs npm python3 p7zip curl unzip && sudo dnf groupinstall 'Development Tools'  # Fedora
  sudo pacman -S nodejs npm python p7zip curl unzip base-devel  # Arch"
  fi

  NODE_MAJOR=$(node -v | cut -d. -f1 | tr -d v)
  if [ "$NODE_MAJOR" -lt 20 ]; then
    error "Node.js 20+ required (found $(node -v))"
  fi

  resolve_7z

  if ! command -v make &>/dev/null || ! command -v g++ &>/dev/null; then
    error "Build tools (make, g++) required:
  sudo apt install build-essential  # Debian/Ubuntu
  sudo dnf groupinstall 'Development Tools'  # Fedora
  sudo pacman -S base-devel  # Arch"
  fi

  info "All dependencies found"
  info "Using 7-Zip: $SEVEN_Z_CMD"
}

get_dmg() {
  local dmg_dest="$SCRIPT_DIR/Codex.dmg"

  if [ -s "$dmg_dest" ]; then
    info "Using cached DMG: $dmg_dest ($(du -h "$dmg_dest" | cut -f1))"
    echo "$dmg_dest"
    return
  fi

  info "Downloading Codex Desktop DMG..."
  local dmg_url="https://persistent.oaistatic.com/codex-app-prod/Codex.dmg"
  info "URL: $dmg_url"

  if ! curl -L --progress-bar --max-time 600 --connect-timeout 30 -o "$dmg_dest" "$dmg_url"; then
    rm -f "$dmg_dest"
    error "Download failed. Download manually and place as: $dmg_dest"
  fi

  if [ ! -s "$dmg_dest" ]; then
    rm -f "$dmg_dest"
    error "Download produced empty file. Download manually and place as: $dmg_dest"
  fi

  info "Saved: $dmg_dest ($(du -h "$dmg_dest" | cut -f1))"
  echo "$dmg_dest"
}

extract_dmg() {
  local dmg_path="$1"

  info "Extracting DMG with 7z..."
  local extract_status=0
  "$SEVEN_Z_CMD" x -y "$dmg_path" -o"$WORK_DIR/dmg-extract" >&2 || extract_status=$?

  local app_dir
  app_dir=$(find "$WORK_DIR/dmg-extract" -maxdepth 4 -name "*.app" -type d | head -1)
  [ -n "$app_dir" ] || error "Failed to extract DMG contents from $dmg_path"

  if [ "$extract_status" -ne 0 ]; then
    warn "7-Zip reported non-zero exit code ($extract_status), but the app bundle was extracted successfully"
  fi

  info "Found: $(basename "$app_dir")"
  echo "$app_dir"
}

verify_native_modules() {
  local native_root="$1"
  local max_glibc="${CODEX_TARGET_GLIBC_MAX:-}"
  local expect_static="${CODEX_EXPECT_STATIC_LIBSTDCXX:-0}"
  local checked=0
  local failed=0

  while IFS= read -r -d '' node_file; do
    checked=$((checked + 1))

    local ldd_out
    ldd_out="$(ldd "$node_file" 2>&1 || true)"

    if [ "$expect_static" = "1" ] && grep -Eq 'libstdc\+\+\.so\.6|libgcc_s\.so\.1' <<<"$ldd_out"; then
      warn "Native module still links dynamically to libstdc++/libgcc: $node_file"
      failed=1
    fi

    if [ "$max_glibc" = "2.31" ] && command -v strings >/dev/null 2>&1; then
      if strings "$node_file" | grep -Eq 'GLIBC_2\.(3[2-9]|[4-9][0-9])'; then
        warn "Native module requires glibc newer than 2.31: $node_file"
        failed=1
      fi
    fi
  done < <(find "$native_root/node_modules" \( -path '*/build/Release/*.node' -o -path '*/bin/*/*.node' \) -print0)

  if [ "$checked" -eq 0 ]; then
    warn "No rebuilt native modules found for ABI validation"
    return
  fi

  [ "$failed" -eq 0 ] || error "Native module compatibility validation failed"
  info "Native module ABI validation passed"
}

bundle_runtime_libraries() {
  if [ "${CODEX_BUNDLE_LIBCXX:-0}" != "1" ]; then
    return
  fi

  local runtime_dir="$INSTALL_DIR/runtime-libs"
  local libs=(libc++.so.1 libc++abi.so.1 libunwind.so.1)
  local lib
  local resolved

  mkdir -p "$runtime_dir"

  for lib in "${libs[@]}"; do
    resolved="$(ldconfig -p 2>/dev/null | awk -v lib="$lib" '$1 == lib { print $NF; exit }')"
    [ -n "$resolved" ] || error "Could not resolve runtime library: $lib"
    cp -L "$resolved" "$runtime_dir/"
  done

  info "Bundled runtime libraries into $runtime_dir"
}

build_native_modules() {
  local app_extracted="$1"
  local bs3_ver
  local npty_ver

  bs3_ver=$(node -p "require('$app_extracted/node_modules/better-sqlite3/package.json').version" 2>/dev/null || echo "")
  npty_ver=$(node -p "require('$app_extracted/node_modules/node-pty/package.json').version" 2>/dev/null || echo "")

  [ -n "$bs3_ver" ] || error "Could not detect better-sqlite3 version"
  [ -n "$npty_ver" ] || error "Could not detect node-pty version"

  info "Native modules: better-sqlite3@$bs3_ver, node-pty@$npty_ver"

  local build_dir="$WORK_DIR/native-build"
  mkdir -p "$build_dir"
  cd "$build_dir"
  echo '{"private":true}' > package.json

  info "Installing fresh sources from npm..."
  npm install "electron@$ELECTRON_VERSION" --save-dev --ignore-scripts >&2
  npm install "better-sqlite3@$bs3_ver" "node-pty@$npty_ver" --ignore-scripts >&2

  local base_cxx="${CXX:-g++}"
  cat > "$build_dir/cxx-compat" <<EOF
#!/bin/bash
REAL_CXX="$base_cxx"
args=()
for arg in "\$@"; do
  case "\$arg" in
    -std=gnu++20) args+=("-std=gnu++2a") ;;
    -std=c++20) args+=("-std=c++2a") ;;
    *) args+=("\$arg") ;;
  esac
done
exec "\$REAL_CXX" "\${args[@]}"
EOF
  chmod +x "$build_dir/cxx-compat"

  info "Compiling for Electron v$ELECTRON_VERSION (this takes ~1 min)..."
  CXX="$build_dir/cxx-compat" npx --yes @electron/rebuild -v "$ELECTRON_VERSION" --force >&2
  verify_native_modules "$build_dir"
  info "Native modules built successfully"

  rm -rf "$app_extracted/node_modules/better-sqlite3" "$app_extracted/node_modules/node-pty"
  cp -r "$build_dir/node_modules/better-sqlite3" "$app_extracted/node_modules/"
  cp -r "$build_dir/node_modules/node-pty" "$app_extracted/node_modules/"
}

patch_linux_window_background() {
  local extracted_dir="$1"
  local bundle_file=""

  bundle_file="$(grep -RIl 'function mu({platform:r,appearance:e,opaqueWindowsEnabled:t,prefersDarkColors:i})' "$extracted_dir/.vite/build" 2>/dev/null | head -1 || true)"
  [ -n "$bundle_file" ] || error "Could not locate Electron main bundle for Linux window background patch"

  python3 - "$bundle_file" <<'PY_PATCH'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
old = 'function mu({platform:r,appearance:e,opaqueWindowsEnabled:t,prefersDarkColors:i}){return r==="win32"&&e!=="hotkeyWindowHome"&&e!=="hotkeyWindowThread"?t?{backgroundColor:i?HT:qT,backgroundMaterial:"none"}:{backgroundColor:So,backgroundMaterial:"mica"}:{backgroundColor:So,backgroundMaterial:null}}'
new = 'function mu({platform:r,appearance:e,opaqueWindowsEnabled:t,prefersDarkColors:i}){return r==="win32"&&e!=="hotkeyWindowHome"&&e!=="hotkeyWindowThread"?t?{backgroundColor:i?HT:qT,backgroundMaterial:"none"}:{backgroundColor:So,backgroundMaterial:"mica"}:r==="linux"&&e!=="hotkeyWindowHome"&&e!=="hotkeyWindowThread"?{backgroundColor:i?HT:qT,backgroundMaterial:null}:{backgroundColor:So,backgroundMaterial:null}}'

if new in text:
    raise SystemExit(0)
if old not in text:
    raise SystemExit("Could not find Linux window background function to patch")

path.write_text(text.replace(old, new, 1), encoding="utf-8")
PY_PATCH

  info "Applied Linux opaque window background patch"
}

patch_asar() {
  local app_dir="$1"
  local resources_dir="$app_dir/Contents/Resources"

  [ -f "$resources_dir/app.asar" ] || error "app.asar not found in $resources_dir"

  info "Extracting app.asar..."
  cd "$WORK_DIR"
  npx --yes asar extract "$resources_dir/app.asar" app-extracted

  if [ -d "$resources_dir/app.asar.unpacked" ]; then
    cp -r "$resources_dir/app.asar.unpacked" "$WORK_DIR/"
    cp -r "$resources_dir/app.asar.unpacked/"* app-extracted/ 2>/dev/null || true
  fi

  rm -rf "$WORK_DIR/app-extracted/node_modules/sparkle-darwin" 2>/dev/null || true
  find "$WORK_DIR/app-extracted" -name "sparkle.node" -delete 2>/dev/null || true

  patch_linux_window_background "$WORK_DIR/app-extracted"
  build_native_modules "$WORK_DIR/app-extracted"

  info "Repacking app.asar..."
  cd "$WORK_DIR"
  npx asar pack app-extracted app.asar --unpack "{*.node,*.so,*.dylib}" 2>/dev/null
  info "app.asar patched"
}

download_electron() {
  info "Downloading Electron v${ELECTRON_VERSION} for Linux..."

  local electron_arch
  case "$ARCH" in
    x86_64) electron_arch="x64" ;;
    aarch64) electron_arch="arm64" ;;
    armv7l) electron_arch="armv7l" ;;
    *) error "Unsupported architecture: $ARCH" ;;
  esac

  local default_url="https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}/electron-v${ELECTRON_VERSION}-linux-${electron_arch}.zip"
  local url="${ELECTRON_DOWNLOAD_URL:-$default_url}"
  info "Electron URL: $url"
  curl -L --progress-bar -o "$WORK_DIR/electron.zip" "$url"

  mkdir -p "$INSTALL_DIR"
  cd "$INSTALL_DIR"
  unzip -qo "$WORK_DIR/electron.zip"
  info "Electron ready"
}

extract_webview() {
  local app_dir="$1"
  mkdir -p "$INSTALL_DIR/content/webview"

  local asar_extracted="$WORK_DIR/app-extracted"
  if [ -d "$asar_extracted/webview" ]; then
    cp -r "$asar_extracted/webview/"* "$INSTALL_DIR/content/webview/"
    info "Webview files copied"
  else
    warn "Webview directory not found in asar - app may not work"
  fi
}

install_app() {
  cp "$WORK_DIR/app.asar" "$INSTALL_DIR/resources/"
  if [ -d "$WORK_DIR/app.asar.unpacked" ]; then
    cp -r "$WORK_DIR/app.asar.unpacked" "$INSTALL_DIR/resources/"
  fi
  info "app.asar installed"
}

install_app_icon() {
  local icon_source="$SCRIPT_DIR/assets/codex-desktop.png"
  local icon_base_dir="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
  local themed_icon_dir="$icon_base_dir/512x512/apps"

  if [ ! -f "$icon_source" ]; then
    warn "App icon source not found: $icon_source"
    return
  fi

  mkdir -p "$INSTALL_DIR" "$themed_icon_dir"
  cp "$icon_source" "$INSTALL_DIR/codex-desktop.png"
  cp "$icon_source" "$themed_icon_dir/codex-desktop.png"

  if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$icon_base_dir" >/dev/null 2>&1 || true
  fi

  info "App icon installed"
}

create_desktop_entry() {
  if [ "${CODEX_SKIP_DESKTOP_ENTRY:-0}" = "1" ]; then
    info "Skipping desktop entry creation"
    return
  fi

  local applications_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  local desktop_file="$applications_dir/codex-desktop.desktop"
  mkdir -p "$applications_dir"

  cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=Codex
Comment=OpenAI Codex Desktop on Linux (portal-safe launcher)
Exec=$INSTALL_DIR/start.sh %U
Path=$INSTALL_DIR
Icon=codex-desktop
Terminal=false
Categories=Development;
Keywords=OpenAI;Codex;AI;Coding;Assistant;
StartupNotify=true
StartupWMClass=Codex
EOF

  info "Desktop entry created: $desktop_file"
}

create_desktop_shortcut() {
  if [ "${CODEX_SKIP_DESKTOP_SHORTCUT:-0}" = "1" ]; then
    info "Skipping desktop shortcut creation"
    return
  fi

  local applications_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  local source_file="$applications_dir/codex-desktop.desktop"
  local desktop_dir=""
  local shortcut_file=""

  desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
  [ -n "$desktop_dir" ] || desktop_dir="$HOME/Desktop"

  mkdir -p "$desktop_dir"
  shortcut_file="$desktop_dir/Codex.desktop"

  if [ -f "$source_file" ]; then
    cp "$source_file" "$shortcut_file"
  else
    cat > "$shortcut_file" <<EOF
[Desktop Entry]
Type=Application
Name=Codex
Comment=OpenAI Codex Desktop on Linux (portal-safe launcher)
Exec=$INSTALL_DIR/start.sh %U
Path=$INSTALL_DIR
Icon=codex-desktop
Terminal=false
Categories=Development;
Keywords=OpenAI;Codex;AI;Coding;Assistant;
StartupNotify=true
StartupWMClass=Codex
EOF
  fi

  chmod +x "$shortcut_file"

  if command -v gio &>/dev/null; then
    if ! gio set "$shortcut_file" metadata::trusted true >/dev/null 2>&1; then
      gio set "$shortcut_file" metadata::trusted yes >/dev/null 2>&1 || true
    fi
  fi

  info "Desktop shortcut created: $shortcut_file"
}

create_start_script() {
  cat > "$INSTALL_DIR/start.sh" <<'SCRIPT'
#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBVIEW_DIR="$SCRIPT_DIR/content/webview"
RUNTIME_LIB_DIR="$SCRIPT_DIR/runtime-libs"

if [ -d "$RUNTIME_LIB_DIR" ] && [ "$(ls -A "$RUNTIME_LIB_DIR" 2>/dev/null)" ]; then
  export LD_LIBRARY_PATH="$RUNTIME_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

pkill -f "http.server 5175" 2>/dev/null || true
sleep 0.3

if [ -d "$WEBVIEW_DIR" ] && [ "$(ls -A "$WEBVIEW_DIR" 2>/dev/null)" ]; then
  cd "$WEBVIEW_DIR"
  python3 -m http.server 5175 &> /dev/null &
  HTTP_PID=$!
  trap 'kill "$HTTP_PID" 2>/dev/null || true' EXIT
fi

export CODEX_CLI_PATH="${CODEX_CLI_PATH:-$(which codex 2>/dev/null || true)}"
if [ -z "$CODEX_CLI_PATH" ]; then
  echo "Error: Codex CLI not found. Install with: npm i -g @openai/codex" >&2
  exit 1
fi

unset ELECTRON_RUN_AS_NODE
export GTK_USE_PORTAL="${GTK_USE_PORTAL:-0}"

cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/electron" --no-sandbox --xdg-portal-required-version=999 "$@"
SCRIPT

  chmod +x "$INSTALL_DIR/start.sh"
  info "Start script created"
}

main() {
  echo "============================================" >&2
  echo " Codex Desktop for Linux - Installer" >&2
  echo "============================================" >&2
  echo "" >&2

  check_deps

  local dmg_path=""
  if [ $# -ge 1 ] && [ -f "$1" ]; then
    dmg_path="$(realpath "$1")"
    info "Using provided DMG: $dmg_path"
  else
    dmg_path=$(get_dmg)
  fi

  local app_dir
  app_dir=$(extract_dmg "$dmg_path")

  patch_asar "$app_dir"
  download_electron
  extract_webview "$app_dir"
  install_app
  bundle_runtime_libraries
  create_start_script
  install_app_icon
  create_desktop_entry
  create_desktop_shortcut

  if ! command -v codex &>/dev/null; then
    warn "Codex CLI not found. Install it: npm i -g @openai/codex"
  fi

  echo "" >&2
  echo "============================================" >&2
  info "Installation complete!"
  echo " Run: $INSTALL_DIR/start.sh" >&2
  echo "============================================" >&2
}

main "$@"
