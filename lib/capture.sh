#!/usr/bin/env bash
# =====================================================================
#  Self-contained capture script — pushed to the VULNBOX by 'auto'.
#  Rotates pcaps and moves each completed one into ready/ for the pwnbox
#  to rsync-pull. Uses the system tcpdump, or a staged one in ~/adduck_bin.
#  Args:  capture.sh <iface> [interval_seconds]
# =====================================================================
IFACE="${1:-eth0}"
INTERVAL="${2:-30}"
BASE="$HOME/adduck_pcaps"
READY="$BASE/ready"
mkdir -p "$READY"

# completion hook: move the finished pcap into ready/ (never a half-written one)
HOOK="$BASE/_hook.sh"
printf '#!/bin/sh\nmv "$1" "%s/" 2>/dev/null\n' "$READY" > "$HOOK"
chmod +x "$HOOK"

# tcpdump: system one, else a staged copy in ~/adduck_bin (+ its libpcap)
TD="tcpdump"
LP=""
if ! command -v tcpdump >/dev/null 2>&1; then
  TD="$HOME/adduck_bin/tcpdump"
  [ -d "$HOME/adduck_bin" ] && LP="LD_LIBRARY_PATH=$HOME/adduck_bin"
fi

# root needs no sudo; a normal user needs passwordless sudo for this to work detached
SUDO="sudo"
[ "$(id -u)" = "0" ] && SUDO=""

CMD=("$TD" -n -i "$IFACE" '(tcp or udp) and not port 22'
     -G "$INTERVAL" -w "$BASE/cap_%Y%m%d_%H%M%S.pcap" -z "$HOOK" -Z root)
[ -n "$LP" ]   && CMD=(env "$LP" "${CMD[@]}")
[ -n "$SUDO" ] && CMD=("$SUDO" "${CMD[@]}")

echo "[capture] iface=$IFACE interval=${INTERVAL}s -> $READY"
exec "${CMD[@]}"
