#!/usr/bin/env bash

# Get script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

CONFIG_DIR="/etc/ctos"
INSTALL_DIR="/opt/ctos"

graceful_exit() {
    echo
    echo -e "[EXIT] Process interrupted or failed."
    exit 1
}

trap graceful_exit ERR SIGINT SIGTERM

echo

GREETER_CONFIG="$CONFIG_DIR/greeter.config.json"

if [ ! -f "$GREETER_CONFIG" ]; then
    echo "[SETUP]"
    DEFAULT_USER=$(whoami)
    read -p "ENTER TARGET USER [$DEFAULT_USER]: " SELECTED_USER
    SELECTED_USER=${SELECTED_USER:-$DEFAULT_USER}

    read -p "ENTER PRIMARY MONITOR: " SELECTED_MONITOR
    SELECTED_MONITOR=${SELECTED_MONITOR}

    echo
    echo "[BASIC SETTINGS]"
    echo "USER: $SELECTED_USER"
    echo "MONITOR: $SELECTED_MONITOR"
    echo

    read -p "PROCEED WITH INSTALLATION? (y/n) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo
        echo "[EXIT] INSTALLATION ABORTED."
        exit 1
    fi

    sudo mkdir -p "$CONFIG_DIR"

    cat <<EOF | sudo tee "$GREETER_CONFIG" > /dev/null
{
  "\$schema": "https://raw.githubusercontent.com/TSM-061/ctOS/main/schema/greeter-schema.json",
  "user": "$SELECTED_USER",
  "monitor": "$SELECTED_MONITOR",
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
      "exit": ["hyprctl", "dispatch", "exit"],
      "launch": ["uwsm", "start", "hyprland.desktop"]
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
    echo
    echo "[ITEM] GREETER CONFIG...ADDED"
    echo "   FILE: $GREETER_CONFIG"
    echo
else 
    echo
    echo "[ITEM] GREETER CONFIG...EXISTS (skipped)"  
    echo "  FOUND: $GREETER_CONFIG"  
fi

sudo mkdir -p "$INSTALL_DIR"

echo -n "[ITEM] QUICKSHELL CONFIG..."
sudo rsync -ahq \
  --exclude=".git" \
  --exclude=".assets" \
  --chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r \
  "$SCRIPT_DIR/" "$INSTALL_DIR"
echo "UPDATED"
echo "    DIR: $INSTALL_DIR"
echo


echo
echo "[EXIT] SUCCESSFULLY COMPLETED."