#!/usr/bin/env bash
# =====================================================================
#  A&D Monitoring Setup Kit  —  menu-driven installer
#  Tulip / pkappa2 dashboards (run on the PWNBOX) + tcpdump capture
#  (run on the VULNBOX). Deterministic, offline-after-clone, no AI.
#
#  Usage:   bash setup.sh
#  Only useful in SITUATION 1 (you can reach / SSH the Vulnbox to capture).
# =====================================================================

HERE="$(cd "$(dirname "$0")" && pwd)"

# --- pick whichever compose spelling this box has (Pwnbox often needs the hyphen)
if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "[!] Neither 'docker compose' nor 'docker-compose' found. Install Docker first."
  exit 1
fi
export COMPOSE
echo "[*] using compose command: $COMPOSE"

menu() {
  cat <<'EOF'

============== A&D Monitoring Setup ==============
  1) Tulip         PCAP analysis dashboard   (Pwnbox)
  2) pkappa2       PCAP stream dashboard      (Pwnbox)
  3) Tcpdump       capture on the Vulnbox  -> pcaps
  4) Status        show running containers
  q) Quit
=================================================
  NOTE: run ONE dashboard (1 or 2), not both.
EOF
}

while true; do
  menu
  read -rp "choose> " choice
  case "$choice" in
    1) bash "$HERE/lib/tulip.sh"   || echo "[!] Tulip step failed (see above)";;
    2) bash "$HERE/lib/pkappa.sh"  || echo "[!] pkappa2 step failed (see above)";;
    3) bash "$HERE/lib/tcpdump.sh" || echo "[!] tcpdump step failed (see above)";;
    4) docker ps ;;
    q|Q) echo "bye"; exit 0 ;;
    *) echo "?" ;;
  esac
done
