#!/usr/bin/env bash
# =====================================================================
#  (1) RUN ON THE VULNBOX.
#  Auto-detects the values the Pwnbox dashboard needs, starts a rotating
#  capture, and drops completed pcaps into  <base>/ready/  for the Pwnbox
#  to rsync-pull. Needs tcpdump + sudo. Capture AUTHORISED interfaces only.
# =====================================================================
set -uo pipefail

echo "=== adducksetup : tcpdump (VULNBOX) ==="
echo
echo "[*] this box's interfaces + IPs  (your VM_IP is one of these):"
ip -br addr 2>/dev/null | awk '{printf "    %-10s %s\n",$1,$3}' || hostname -I
echo
echo "[*] listening TCP ports  (your services are among these; ignore 22/ssh):"
ss -tlnp 2>/dev/null | awk 'NR>1{print "    "$4}' | sort -u || echo "    (ss unavailable)"
echo

read -rp "capture interface (e.g. eth0 / game): " IFACE
IFACE="${IFACE:-eth0}"
INTERVAL="${INTERVAL:-30}"
BASE="${BASE:-$HOME/adduck_pcaps}"
READY="$BASE/ready"
mkdir -p "$READY"

# tcpdump calls this hook (-z) when each rotated pcap finishes:
# move the completed file into ready/ so rsync never grabs a half-written one.
HOOK="$(mktemp /tmp/adduck_hook.XXXX.sh)"
cat > "$HOOK" <<EOF
#!/usr/bin/env bash
mv "\$1" "$READY/" 2>/dev/null || true
EOF
chmod +x "$HOOK"

MYUSER="$(whoami)"
cat <<EOF

############## COPY THIS TO THE PWNBOX ##############
  vulnbox user@ip :  ${MYUSER}@<pick the IP from the list above>
  pcap ready dir  :  $READY
  capture iface   :  $IFACE
  service IPs/ports: pick the service ports from the list above
  ---- these come from the ORGANISER, not this box ----
  FLAG_REGEX, TICK_LENGTH, TICK_START
####################################################

On the Pwnbox: run setup.sh, pick 2 (tulip) or 3 (pkappa), paste the above.

[*] starting capture on $IFACE (${INTERVAL}s rotation). Ctrl+C to stop.
EOF

sudo tcpdump -n -i "$IFACE" "(tcp or udp) and not port 22" \
  -G "$INTERVAL" -w "$BASE/${IFACE}_%Y%m%d_%H%M%S.pcap" \
  -z "$HOOK" -Z root
