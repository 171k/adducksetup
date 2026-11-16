#!/usr/bin/env bash
# =====================================================================
#  (A) auto  -  RUN ON THE PWNBOX. Drives the whole pipeline.
#  You give: vulnbox user@ip (+ the password ONCE). It then:
#    - installs your SSH key on the vulnbox (passwordless after this)
#    - auto-detects the capture interface
#    - pushes capture.sh (+ staged tcpdump if present) to the vulnbox
#    - starts tcpdump there, detached
#    - brings up Tulip on the pwnbox
#    - pulls pcaps every 5s
#  TEST THIS IN THE test-lab FIRST. It is new, remote-heavy automation.
# =====================================================================
set -uo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
COMPOSE="${COMPOSE:-docker compose}"

read -rp "vulnbox user@ip: " VB
[ -z "${VB:-}" ] && { echo "[!] need user@ip"; exit 1; }
VBIP="${VB##*@}"
SSHO="-o StrictHostKeyChecking=accept-new"

echo "[*] setting up passwordless SSH (type the vulnbox password ONCE if asked)..."
[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa >/dev/null
if command -v ssh-copy-id >/dev/null 2>&1; then
  ssh-copy-id $SSHO "$VB" || true
else
  KEY="$(cat ~/.ssh/id_rsa.pub)"
  ssh $SSHO "$VB" "mkdir -p ~/.ssh && echo '$KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
fi

echo "[*] auto-detecting the capture interface..."
IFACE="$(ssh $SSHO "$VB" "ip route 2>/dev/null | awk '/default/{print \$5; exit}'" 2>/dev/null)"
IFACE="${IFACE:-eth0}"
read -rp "capture interface [$IFACE]: " x; IFACE="${x:-$IFACE}"

echo "[*] pushing the capture script to the vulnbox..."
scp -q $SSHO "$HERE/lib/capture.sh" "$VB:~/adduck_capture.sh"
if [ -x "$HERE/bin/tcpdump" ]; then
  echo "[*] vulnbox may lack tcpdump -> sending the staged binary too"
  ssh $SSHO "$VB" "mkdir -p ~/adduck_bin"
  scp -q $SSHO "$HERE/bin/"* "$VB:~/adduck_bin/"
fi

echo "[*] starting the capture on the vulnbox (detached)..."
ssh $SSHO "$VB" "nohup bash ~/adduck_capture.sh '$IFACE' 30 </dev/null >~/adduck_capture.log 2>&1 & sleep 1; echo '    remote capture started'"

echo "[*] bringing up Tulip on the pwnbox..."
DIR="$HOME/tulip"
if [ -d "$DIR/.git" ]; then git -C "$DIR" pull --ff-only || true; else git clone https://github.com/OpenAttackDefenseTools/tulip.git "$DIR"; fi
cd "$DIR"
[ -f .env ] || cp .env.example .env
mkdir -p pcaps
sed -i 's|"3000:3000"|"127.0.0.1:3000:3000"|' docker-compose.yml 2>/dev/null || true
grep -q '^VM_IP=' .env && sed -i "s|^VM_IP=.*|VM_IP=$VBIP|" .env || echo "VM_IP=$VBIP" >> .env
$COMPOSE up -d --build && $COMPOSE ps
echo "[*] Tulip -> http://127.0.0.1:3000/   (add FLAG_REGEX + TICK_LENGTH in $DIR/.env later for flag highlighting)"

echo
echo "[*] pulling pcaps every 5s. Ctrl+C to stop (Tulip + the capture keep running)."
while true; do
  rsync -az $SSHO --remove-source-files "$VB:~/adduck_pcaps/ready/" "$DIR/pcaps/" 2>/dev/null || echo "[!] pull failed (ssh reachable?)"
  sleep 5
done
