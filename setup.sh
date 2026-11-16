#!/usr/bin/env bash
# =====================================================================
#  adducksetup  -  A&D monitoring setup kit
#  Run (1) on the VULNBOX, (2) or (3) on the PWNBOX.
#  Flow:  vulnbox -> pick 1 -> it prints the config -> pwnbox -> pick 2 or 3
#         -> paste the config -> dashboard comes up and pulls the pcaps.
# =====================================================================
HERE="$(cd "$(dirname "$0")" && pwd)"

# compose spelling (Pwnbox often needs the hyphen); only needed for 2/3
if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then COMPOSE="docker-compose"
else COMPOSE=""; fi
export COMPOSE HERE

menu() {
cat <<'EOF'

============== adducksetup ==============
  1) tcpdump   capture  (run ON THE VULNBOX)
  2) tulip     dashboard (run ON THE PWNBOX)
  3) pkappa    dashboard (run ON THE PWNBOX)
  4) status    docker ps
  q) quit
========================================
  flow:  vulnbox (1) prints config  ->  pwnbox (2 or 3) paste it in
  run ONE dashboard (2 OR 3), not both.
EOF
}

while true; do
  menu
  read -rp "choose> " c
  case "$c" in
    1) bash "$HERE/lib/tcpdump.sh" || echo "[!] tcpdump step failed (see above)";;
    2) bash "$HERE/lib/tulip.sh"   || echo "[!] tulip step failed (see above)";;
    3) bash "$HERE/lib/pkappa.sh"  || echo "[!] pkappa step failed (see above)";;
    4) docker ps ;;
    q|Q) echo "bye"; exit 0 ;;
    *) echo "?" ;;
  esac
done
