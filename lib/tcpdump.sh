#!/usr/bin/env bash
# =====================================================================
#  Tcpdump capture  —  RUN THIS ON THE VULNBOX (Situation 1: you have shell).
#  Captures rotating pcaps on the service interface and, on each rotation,
#  either uploads to pkappa2 or leaves the file for Tulip (rsync/pull it).
#
#  Needs: tcpdump + sudo on the Vulnbox.  Only capture AUTHORISED interfaces.
# =====================================================================
set -euo pipefail

IFACE="${IFACE:-game}"                 # <-- the service interface (find with: ip -br addr)
INTERVAL="${INTERVAL:-30}"             # seconds per pcap file
PCAP_DIR="${PCAP_DIR:-$PWD/pcaps}"
MODE="${MODE:-move}"                   # move | pkappa

# only needed when MODE=pkappa :
PKAPPA_URL="${PKAPPA_URL:-http://PWNBOX_IP:8080}"
PKAPPA_PCAP_PASSWORD="${PKAPPA_PCAP_PASSWORD:-changeme}"

mkdir -p "$PCAP_DIR"

# per-file completion hook that tcpdump calls (-z) when a pcap finishes
HOOK="$(mktemp /tmp/_pcap_complete.XXXX.sh)"
cat > "$HOOK" <<EOF
#!/usr/bin/env bash
f="\$1"
if [ "$MODE" = pkappa ]; then
  curl -s -u "admin:$PKAPPA_PCAP_PASSWORD" \
       --data-binary "@\$f" "$PKAPPA_URL/upload/\$(basename "\$f")" && rm -f "\$f"
fi
# MODE=move: the pcap just stays in $PCAP_DIR — pull it to the Pwnbox:
#   (on Pwnbox)  rsync -av --remove-source-files vulnbox:$PCAP_DIR/ ~/tulip/pcaps/
EOF
chmod +x "$HOOK"

echo "[*] IFACE=$IFACE  INTERVAL=${INTERVAL}s  DIR=$PCAP_DIR  MODE=$MODE"
echo "[*] capturing (exclude SSH)... Ctrl+C to stop"
sudo tcpdump -n -i "$IFACE" "(tcp or udp) and not port 22" \
  -G "$INTERVAL" -w "$PCAP_DIR/${IFACE}_%Y%m%d_%H%M%S.pcap" \
  -z "$HOOK" -Z root
