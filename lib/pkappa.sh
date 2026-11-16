#!/usr/bin/env bash
# =====================================================================
#  (3) RUN ON THE PWNBOX.
#  Brings up pkappa2 (watch-dir ingest), takes the passwords you choose,
#  then pulls pcaps from the vulnbox into pkappa2's pcaps_incoming/ folder.
# =====================================================================
set -uo pipefail
COMPOSE="${COMPOSE:-docker compose}"
DIR="${PKAPPA_DIR:-$HOME/pkappa2}"
REPO="https://github.com/spq/pkappa2.git"

if [ -d "$DIR/.git" ]; then
  echo "[*] updating pkappa2"; git -C "$DIR" pull --ff-only || echo "[!] pull failed, using existing"
else
  echo "[*] cloning pkappa2 -> $DIR"; git clone "$REPO" "$DIR"
fi
cd "$DIR"
[ -f .env ] || cp .env.example .env
mkdir -p pcaps_incoming
# enable the watch-dir mount + bind UI to localhost
sed -i 's|# *- \./pcaps_incoming:/pcaps_in|- ./pcaps_incoming:/pcaps_in|' docker-compose.yml 2>/dev/null || true
sed -i 's|- 8080:8080|- 127.0.0.1:8080:8080|' docker-compose.yml 2>/dev/null || true

echo
echo "=== pkappa2 passwords (you choose these) ==="
read -rp "  UI password (PKAPPA2_USER_PASSWORD): " UP
read -rp "  upload password (PKAPPA2_PCAP_PASSWORD): " PP
[ -n "${UP:-}" ] && (grep -q 'PKAPPA2_USER_PASSWORD=' .env && sed -i "s|.*PKAPPA2_USER_PASSWORD=.*|PKAPPA2_USER_PASSWORD=$UP|" .env || echo "PKAPPA2_USER_PASSWORD=$UP" >> .env)
[ -n "${PP:-}" ] && (grep -q 'PKAPPA2_PCAP_PASSWORD=' .env && sed -i "s|.*PKAPPA2_PCAP_PASSWORD=.*|PKAPPA2_PCAP_PASSWORD=$PP|" .env || echo "PKAPPA2_PCAP_PASSWORD=$PP" >> .env)

echo "[*] building + starting pkappa2..."
$COMPOSE up -d --build && $COMPOSE ps
echo "[*] pkappa2 -> http://127.0.0.1:8080/"

echo
read -rp "start pulling pcaps from the vulnbox now? [y/N] " p
if [ "${p:-N}" = y ]; then
  read -rp "  vulnbox user@ip: " VB
  read -rp "  vulnbox ready dir: " RD
  echo "[*] (tip: set up an SSH key first so it doesn't ask for a password each loop)"
  echo "[*] pulling every 5s. Ctrl+C to stop (pkappa2 keeps running)."
  while true; do
    rsync -az -e "ssh -o StrictHostKeyChecking=accept-new" --remove-source-files "$VB:$RD/" "$DIR/pcaps_incoming/" 2>/dev/null || echo "[!] rsync failed (ssh reachable?)"
    sleep 5
  done
fi
