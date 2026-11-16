#!/usr/bin/env bash
# =====================================================================
#  adducksetup  -  A&D monitoring setup kit
#  Easiest:  on the PWNBOX pick 'A' (auto) — it drives the whole pipeline.
#  Manual:   1 on the VULNBOX, 2/3/s on the PWNBOX (fallback if auto breaks).
# =====================================================================
HERE="$(cd "$(dirname "$0")" && pwd)"

# compose spelling (Pwnbox often needs the hyphen)
if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then COMPOSE="docker-compose"
else COMPOSE=""; fi
export COMPOSE HERE

menu() {
cat <<'EOF'

============== adducksetup ==============
  A) auto      do EVERYTHING from the pwnbox (give vulnbox ip + password once)
  --- or run the pieces by hand (fallback) ---
  1) tcpdump   capture  (run ON THE VULNBOX)
  2) tulip     dashboard (run ON THE PWNBOX)
  3) pkappa    dashboard (run ON THE PWNBOX)
  s) stage     bundle the pwnbox's tcpdump into the kit (PWNBOX, pre-scp)
  4) status    docker ps
  q) quit
========================================
  'A' needs SSH access to the vulnbox. Test it in test-lab/ first.
EOF
}

while true; do
  menu
  read -rp "choose> " c
  case "$c" in
    A|a) bash "$HERE/lib/auto.sh"        || echo "[!] auto failed (see above; try the manual steps)";;
    1) bash "$HERE/lib/tcpdump.sh"       || echo "[!] tcpdump step failed (see above)";;
    2) bash "$HERE/lib/tulip.sh"         || echo "[!] tulip step failed (see above)";;
    3) bash "$HERE/lib/pkappa.sh"        || echo "[!] pkappa step failed (see above)";;
    s|S) bash "$HERE/lib/stage-tcpdump.sh" || echo "[!] stage step failed (see above)";;
    4) docker ps ;;
    q|Q) echo "bye"; exit 0 ;;
    *) echo "?" ;;
  esac
done
