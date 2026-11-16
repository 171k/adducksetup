#!/usr/bin/env bash
# =====================================================================
#  (2) RUN ON THE PWNBOX.
#  Brings up Tulip, takes the config you copied from the vulnbox step,
#  then pulls pcaps from the vulnbox into Tulip's pcaps/ folder.
# =====================================================================
set -uo pipefail
COMPOSE="${COMPOSE:-docker compose}"
DIR="${TULIP_DIR:-$HOME/tulip}"
REPO="https://github.com/OpenAttackDefenseTools/tulip.git"

if [ -d "$DIR/.git" ]; then
  echo "[*] updating Tulip"; git -C "$DIR" pull --ff-only || echo "[!] pull failed, using existing"
else
  echo "[*] cloning Tulip -> $DIR"; git clone "$REPO" "$DIR"
fi
cd "$DIR"
[ -f .env ] || cp .env.example .env
mkdir -p pcaps
sed -i 's|"3000:3000"|"127.0.0.1:3000:3000"|' docker-compose.yml 2>/dev/null || true

echo
echo "=== Tulip config (paste what the vulnbox step / organiser gave you) ==="
read -rp "  VM_IP (the vulnbox IP): " VM_IP
read -rp "  TICK_LENGTH in ms (organiser): " TL
read -rp "  FLAG_REGEX (organiser): " FR
[ -n "${VM_IP:-}" ] && (grep -q '^VM_IP=' .env && sed -i "s|^VM_IP=.*|VM_IP=$VM_IP|" .env || echo "VM_IP=$VM_IP" >> .env)
[ -n "${TL:-}" ]    && (grep -q '^TICK_LENGTH=' .env && sed -i "s|^TICK_LENGTH=.*|TICK_LENGTH=$TL|" .env || echo "TICK_LENGTH=$TL" >> .env)
[ -n "${FR:-}" ]    && (grep -q '^FLAG_REGEX=' .env && sed -i "s|^FLAG_REGEX=.*|FLAG_REGEX=$FR|" .env || echo "FLAG_REGEX=$FR" >> .env)

echo "[>] set your service IPs/ports in services/api/configurations.py"
read -rp "    open it now? [y/N] " a; [ "${a:-N}" = y ] && "${EDITOR:-nano}" services/api/configurations.py

echo "[*] building + starting Tulip..."
$COMPOSE up -d --build && $COMPOSE ps
echo "[*] Tulip -> http://127.0.0.1:3000/"

echo
read -rp "start pulling pcaps from the vulnbox now? [y/N] " p
if [ "${p:-N}" = y ]; then
  read -rp "  vulnbox user@ip: " VB
  read -rp "  vulnbox ready dir: " RD
  echo "[*] (tip: set up an SSH key first so it doesn't ask for a password each loop)"
  echo "[*] pulling every 5s. Ctrl+C to stop (Tulip keeps running)."
  while true; do
    rsync -az --remove-source-files "$VB:$RD/" "$DIR/pcaps/" 2>/dev/null || echo "[!] rsync failed (ssh reachable?)"
    sleep 5
  done
fi
