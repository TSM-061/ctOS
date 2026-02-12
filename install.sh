#!/usr/bin/env bash

# Get script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

NAMESPACE="ctos"

# main directories
CONFIG_DIR="/etc/$NAMESPACE"
INSTALL_DIR="/opt/$NAMESPACE"

declare -l COMPOSITOR="" # lowercase only

# configs
GREETER_CONFIG_FILEPATH="$CONFIG_DIR/greeter.config.json"

FRESH_INSTALL=1
if [[ -d "$CONFIG_DIR" ]]; then
  FRESH_INSTALL=0
fi

graceful_exit() {
  echo
  echo
  echo -e "[EXIT] Process interrupted or failed."
  exit 1
}

detect_compositor() {

  COMPOSITOR="$XDG_CURRENT_DESKTOP"

  if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
    echo
    echo "[ERROR] CTOS only supports Wayland sessions."
    exit 1
  fi
}

generate_greeter_config() {
  local user="$1"
  local monitor="$2"

  cat <<EOF
{
  "\$schema": "https://raw.githubusercontent.com/TSM-061/ctOS/main/schema/greeter.schema.json",
  "user": "$user",
  "monitor": "$monitor",
  "fontFamily": "JetBrainsMono Nerd Font",
  "fakeIdentity": {
    "id": "XYZ-843",
    "class": "L5_PROV",
    "fullName": "Blume Admin"
  },
  "fakeStatus": {
    "env": "Workstation",
    "node": "109.389.013.301"
  },
  "modes": {
    "greetd": {
      "animations": "all",
      "exit": ["uwsm", "stop"],
      "launch":["uwsm", "start", "$COMPOSITOR.desktop"] 
    },
    "lockd": {
      "animations": "reduced"
    },
    "test": {
      "animations": "all"
    }
  }
}
EOF
}

ensure_exists() {
  local input="$1" # either filepath or string
  local target_path="$2"

  if [[ -f "$target_path" ]]; then
    echo "[ITEM]   found: $target_path (skipping)"
    return 0
  fi

  mkdir -p "$(dirname "$target_path")"

  local contents=""

  if [[ -d "$(dirname "$input")" ]]; then
    if [[ ! -f "$input" ]]; then
      echo
      echo "[!][ERROR] file not found '$input'"
      exit 1
    else
      contents=$(cat "$input")
    fi
  else
    contents="$input"
  fi

  if [[ -z "$contents" ]]; then
    echo
    echo "[!][ERROR] empty input"
    exit 1
  fi

  echo "$contents" | sudo tee "$target_path" >/dev/null

  if [[ $? -eq 0 ]]; then
    echo "[ITEM] added: $target_path"
    return 0
  fi

  echo "error: $target_path"
}

function detect_monitor() {
  case "$COMPOSITOR" in
  "hyprland")
    DEFAULT_MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null)
    ;;
  "niri")
    DEFAULT_MONITOR=$(niri msg -j outputs 2>/dev/null | jq -r 'keys[0]' 2>/dev/null)
    ;;
  esac
}

function run_setup_wizard() {
  echo
  echo "[CTOS INSTALLER]"
  echo

  DEFAULT_USER=$(whoami)
  read -p "[Q] ENTER TARGET USER [$DEFAULT_USER]: " SELECTED_USER
  SELECTED_USER=${SELECTED_USER:-$DEFAULT_USER}

  detect_monitor
  MONITOR_PROMPT=${DEFAULT_MONITOR:+ [$DEFAULT_MONITOR]}
  read -p "[Q] ENTER PRIMARY MONITOR$MONITOR_PROMPT: " SELECTED_MONITOR
  SELECTED_MONITOR=${SELECTED_MONITOR:-$DEFAULT_MONITOR}

  echo
  echo "[BASIC SETTINGS]"
  echo "COMPOSITOR=${COMPOSITOR:-n/a}"
  echo "USER=$SELECTED_USER"
  echo "MONITOR=$SELECTED_MONITOR"
  echo

  read -rp "[Q] Proceed with installation? (y/n) "

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "[EXIT] Installation aborted."
    exit 1
  fi

}

function install_greeter_compositor_config() {
  local scaffold_dir="$SCRIPT_DIR/Greeter/examples/"

  declare -A templates=(
    ["hyprland"]="$scaffold_dir/greeter.hyprland.conf"
    ["niri"]="$scaffold_dir/greeter.niri.kdl"
  )

  local config_src=${templates[$COMPOSITOR]}

  local config_dest="$CONFIG_DIR/$(basename "$config_src")"

  if [[ -z "$config_src" ]]; then
    echo "[ITEM]     n/a: $CONFIG_DIR/greeter.<compositor>.<filetype>"
    echo
    echo "  [!] Note: You can ignore above item being n/a if you are using cage."
    echo "      https://github.com/TSM-061/ctOS/tree/main/Greeter#other-environments"
    echo
  fi

  if [[ -n "$config_src" ]]; then
    ensure_exists "$config_src" "$config_dest"
    return 0
  fi
}

function sync_project_files() {
  sudo mkdir -p "$INSTALL_DIR"

  sudo rsync -ahq \
    --exclude=".git" \
    --exclude=".assets" \
    --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r \
    "$SCRIPT_DIR/" "$INSTALL_DIR"

  if [[ "$FRESH_INSTALL" -eq 1 ]]; then
    echo "[ITEM]   added: $INSTALL_DIR"
  else
    echo "[ITEM] updated: $INSTALL_DIR"
  fi
}

# --------------------------------------------------------------------------------
# SECTION Main
# --------------------------------------------------------------------------------

trap graceful_exit ERR SIGINT SIGTERM

detect_compositor

if [[ "$FRESH_INSTALL" -eq 1 || ! -f "$GREETER_CONFIG_FILEPATH" ]]; then
  run_setup_wizard
  sudo mkdir -p "$CONFIG_DIR"
fi

echo

ensure_exists "$(generate_greeter_config "$SELECTED_USER" "$SELECTED_MONITOR")" "$GREETER_CONFIG_FILEPATH"

install_greeter_compositor_config

sync_project_files

if [[ "$FRESH_INSTALL" -eq 1 ]]; then
  echo
  echo "[WARN] This installation assumes you are using 'uwsm', if not "
  echo "       change the launch/exit commands in $(basename "$GREETER_CONFIG_FILEPATH")."
fi

echo
echo "[EXIT] SUCCESSFULLY COMPLETED."
