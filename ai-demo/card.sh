#!/usr/bin/env bash
# Title cards and pane headers for the herdr demo. Source it, don't run it.
# card <title> <subtitle> <line>...  clears the pane, prints a big title card, waits for Enter.
# header <text>                      prints a one-line pane header.
# Plain ANSI only; falls back to unstyled text when stdout is not a terminal.
if [ -t 1 ]; then
  C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'; C_CYAN=$'\e[36m'; C_RESET=$'\e[0m'
else
  C_BOLD=""; C_DIM=""; C_CYAN=""; C_RESET=""
fi

header() {
  printf '%s== %s ==%s\n\n' "$C_CYAN$C_BOLD" "$1" "$C_RESET"
}

card() {
  local title=$1 subtitle=$2 line rows pad
  shift 2
  rows=${LINES:-$(tput lines 2>/dev/null || echo 24)}
  # Rough vertical centering: card is 6 rows plus one per line.
  pad=$(( (rows - 6 - $#) / 3 ))
  [ "$pad" -lt 1 ] && pad=1
  if [ -t 1 ]; then clear; fi
  for _ in $(seq "$pad"); do echo; done
  printf '  %s%s%s\n' "$C_CYAN$C_BOLD" "$title" "$C_RESET"
  printf '  %s%s%s\n\n' "$C_BOLD" "$subtitle" "$C_RESET"
  for line in "$@"; do
    printf '    %s\n' "$line"
  done
  echo
  if [ -t 0 ]; then
    read -r -p "  ${C_DIM}Press Enter to start... ${C_RESET}"
  fi
  if [ -t 1 ]; then clear; fi
}
