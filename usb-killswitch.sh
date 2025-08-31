#!/bin/bash
#
# USB Kill-Switch Security Tool — bitroox
# License: MIT
#

# ---------- UI Colors ----------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"
BOLD="\033[1m"

log() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $1"
}

# ---------- RAM Wipe ----------
wipe_ram() {
  echo -e "${YELLOW}${BOLD}[!] Wiping RAM (best effort)...${RESET}"

  sync
  swapoff -a 2>/dev/null || true

  for i in {1..3}; do
    dd if=/dev/zero of=/dev/shm/wipe.$$ bs=1M status=none || true
    rm -f /dev/shm/wipe.$$ 2>/dev/null
  done

  echo -e "${GREEN}[+] RAM wipe attempt completed.${RESET}"
}

# ---------- Shutdown ----------
poweroff_now() {
  echo -e "${RED}${BOLD}[POWER] Shutting down now…${RESET}"

  if command -v systemctl >/dev/null 2>&1; then
    systemctl poweroff -i && return
  fi

  if command -v shutdown >/dev/null 2>&1; then
    shutdown -h now && return
  fi

  if command -v poweroff >/dev/null 2>&1; then
    poweroff -f && return
  fi

  log "Shutdown command failed. Forcing kernel halt."
  sync
  echo o > /proc/sysrq-trigger 2>/dev/null || halt -f
}

# ---------- USB Monitor ----------
monitor_usb() {
  local action=$1
  log "Waiting for USB device insertion..."
  device=$(lsblk -J | jq -r '.blockdevices[] | select(.tran=="usb") | .name' | head -n1)

  if [ -z "$device" ]; then
    udevadm monitor --udev --subsystem-match=usb | while read -r line; do
      if echo "$line" | grep -q "add"; then
        device=$(lsblk -J | jq -r '.blockdevices[] | select(.tran=="usb") | .name' | head -n1)
        [ -n "$device" ] && break
      fi
    done
  fi

  log "USB device detected: /dev/$device"

  udevadm monitor --udev --subsystem-match=usb | while read -r line; do
    if echo "$line" | grep -q "remove"; then
      echo -e "${RED}${BOLD}[TRIGGER] USB device removed!${RESET}"
      case $action in
        kill) poweroff_now ;;
        secure) wipe_ram && poweroff_now ;;
        diag) log "Diagnostics: Trigger detected but no shutdown." ;;
      esac
    fi
  done
}

# ---------- Menu ----------
show_menu() {
  clear
  echo -e "${GREEN}${BOLD}"
  echo "==========================================="
  echo "        USB Kill-Switch Security Tool      "
  echo "                  bitroox                  "
  echo "==========================================="
  echo -e "${RESET}"
  echo "1) Kill-Switch Mode (shutdown on removal)"
  echo "2) Secure Mode (wipe RAM + shutdown)"
  echo "3) Diagnostics Mode (test only)"
  echo "4) Exit"
  echo
  echo -ne "Select option [1-4]: "
}

# ---------- Main ----------
while true; do
  show_menu
  read -r choice
  case $choice in
    1) monitor_usb "kill" ;;
    2) monitor_usb "secure" ;;
    3) monitor_usb "diag" ;;
    4) echo "Exiting..."; exit 0 ;;
    *) error "Invalid choice"; sleep 1 ;;
  esac
done
