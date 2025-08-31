#!/usr/bin/env bash
# =====================================================================
#  USB Kill-Switch — Wipe+Shutdown Fixed (GitHub-ready)
#  Tag: bitrrox
#  License: MIT
#
#  Modes:
#    1) Kill-Switch (shutdown on key removal)
#    2) Secure Mode (best-effort RAM wipe → shutdown)
#    3) Diagnostics/Test (monitor only)
#  Notes:
#    - No extra dependencies. Uses core Linux utils only.
#    - RAM wipe from user-space is best-effort (not absolute).
# =====================================================================

set -euo pipefail

APP_NAME="USB Kill-Switch Security Tool"
APP_TAG="[bitrrox]"
APP_VER="v1.0.0"

# -------------------- Colors / UI --------------------
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
  RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"; YELLOW="$(tput setaf 3)"
  BLUE="$(tput setaf 4)"; MAGENTA="$(tput setaf 5)"; CYAN="$(tput setaf 6)"
  BOLD="$(tput bold)"; RESET="$(tput sgr0)"
else
  RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"
  MAGENTA="\e[35m"; CYAN="\e[36m"; BOLD="\e[1m"; RESET="\e[0m"
fi

log()  { echo -e "${CYAN}[USB-KILLSWITCH]${RESET} $*" | logger -t usb-killswitch; echo -e "${CYAN}[USB-KILLSWITCH]${RESET} $*"; }
info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
ok()   { echo -e "${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
err()  { echo -e "${RED}[ERR]${RESET}  $*"; }

banner() {
  clear
  local left="${APP_NAME} ${APP_VER}"
  local right="${APP_TAG}"
  echo -e "${MAGENTA}${BOLD}┌────────────────────────────────────────────────────────────┐${RESET}"
  printf       "${MAGENTA}${BOLD}│ %-50s %-8s │\n${RESET}" "  ${left}" "${right}"
  echo -e "${MAGENTA}${BOLD}└────────────────────────────────────────────────────────────┘${RESET}"
  echo
}

pause() { read -rp "$(echo -e "${GREEN}Press [Enter] to continue...${RESET}")"; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Run as root. Try: ${BOLD}sudo $0${RESET}"
    exit 1
  fi
}

check_core_utils() {
  local miss=()
  for c in lsblk blkid dd awk logger sync swapoff; do
    command -v "$c" >/dev/null 2>&1 || miss+=("$c")
  done
  if ((${#miss[@]})); then
    err "Missing core utilities: ${miss[*]}"
    exit 1
  fi
}

# -------------------- USB helpers --------------------
get_first_usb_node() { lsblk -ndo NAME,TRAN | awk '$2=="usb"{print $1; exit}'; }
get_uuid_of()       { blkid -s UUID -o value "/dev/$1" 2>/dev/null || true; }

KEY_DEV=""; KEY_UUID=""

wait_for_usb() {
  log "Waiting for a USB device to be plugged in..."
  KEY_DEV=""; KEY_UUID=""
  while [[ -z "$KEY_DEV" ]]; do
    KEY_DEV="$(get_first_usb_node || true)"
    sleep 1
  done
  KEY_UUID="$(get_uuid_of "$KEY_DEV")"
  if [[ -n "$KEY_UUID" ]]; then
    ok "Key detected: ${BOLD}/dev/$KEY_DEV${RESET}  UUID=${YELLOW}$KEY_UUID${RESET}"
  else
    ok "Key detected: ${BOLD}/dev/$KEY_DEV${RESET}  (no UUID)"
  fi
}

is_connected() {
  if [[ -n "$KEY_UUID" ]]; then
    [[ -e "/dev/disk/by-uuid/$KEY_UUID" ]]
  else
    [[ -e "/dev/$KEY_DEV" ]]
  fi
}

monitor_until_removed() {
  info "Monitoring key… unplug to trigger."
  while is_connected; do sleep 0.5; done
  return 0
}

# -------------------- Wipe (best-effort) --------------------
spinner() { # spinner "message" & pid=$! ; wait $pid
  local msg="$1"; shift
  local marks='|/-\' i=0
  echo -ne "${BLUE}${msg}${RESET} "
  while kill -0 "$1" 2>/dev/null; do printf "\b%s" "${marks:i++%${#marks}:1}"; sleep 0.1; done
  echo -ne "\b"; echo -e "${GREEN}done${RESET}"
}

wipe_ram() {
  warn "Initiating best-effort RAM wipe (zero → random → zero)…"
  swapoff -a 2>/dev/null || true

  mkdir -p /dev/shm
  local file="/dev/shm/.ramwipe.$$"
  : > "$file"

  for pass in zero random zero; do
    case "$pass" in
      zero)   src="/dev/zero" ;;
      random) src="/dev/urandom" ;;
    esac
    info "Pass: ${pass}"
    (
      while dd if="$src" of="$file" bs=64M oflag=append conv=notrunc status=none 2>/dev/null; do :; done
      rm -f "$file" || true
      sync || true
      echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
      : > "$file"
    ) &
    spinner "Filling memory…" $!
  done

  rm -f "$file" || true
  ok "RAM wipe pass complete (best-effort)."
}

# -------------------- Guaranteed shutdown --------------------
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
  sync || true
  if [[ -w /proc/sysrq-trigger ]]; then
    echo o > /proc/sysrq-trigger 2>/dev/null && return
  fi
  command -v halt >/dev/null 2>&1 && halt -f
}

# -------------------- Flows --------------------
kill_switch_flow() {
  banner
  echo -e "${GREEN}[MODE] Kill-Switch:${RESET} Shutdown on key removal."
  wait_for_usb
  monitor_until_removed
  echo -e "${RED}${BOLD}[TRIGGERED] Key removed!${RESET}"
  poweroff_now
}

secure_mode_flow() {
  banner
  echo -e "${BLUE}[MODE] Secure Mode:${RESET} Wipe RAM → Shutdown on key removal."
  wait_for_usb
  monitor_until_removed
  echo -e "${RED}${BOLD}[TRIGGERED] Key removed! Preparing secure shutdown…${RESET}"
  wipe_ram
  poweroff_now
}

diagnostics_flow() {
  banner
  echo -e "${YELLOW}[MODE] Diagnostics/Test:${RESET} Monitor only; no shutdown."
  wait_for_usb
  info "Monitoring (test)… unplug the device to simulate."
  monitor_until_removed
  ok "USB removed (test mode). System NOT shut down."
  pause
}

# -------------------- Menu --------------------
menu() {
  while true; do
    banner
    echo -e "${CYAN}Select an option:${RESET}"
    echo -e "  ${GREEN}1)${RESET} Kill-Switch        ${BOLD}(Shutdown on Removal)${RESET}"
    echo -e "  ${BLUE}2)${RESET} Secure Mode       ${BOLD}(Wipe RAM → Shutdown)${RESET}"
    echo -e "  ${YELLOW}3)${RESET} Diagnostics/Test  ${BOLD}(Monitor Only)${RESET}"
    echo -e "  ${RED}4)${RESET} Exit"
    echo
    read -rp "$(echo -e "${BOLD}Enter choice [1-4]: ${RESET}")" choice
    case "$choice" in
      1) kill_switch_flow ;;
      2) secure_mode_flow ;;
      3) diagnostics_flow ;;
      4) echo -e "${MAGENTA}Goodbye. Stay safe!${RESET}"; exit 0 ;;
      *) err "Invalid choice. Try again."; sleep 1 ;;
    esac
  done
}

# -------------------- Main --------------------
trap 'stty echo 2>/dev/null || true' EXIT
require_root
check_core_utils
menu
o

