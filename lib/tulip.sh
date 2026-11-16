#!/usr/bin/env bash
# Tulip — clone/update, configure for local-only, and bring up on the Pwnbox.
# Feeds from completed .pcap files dropped into <dir>/pcaps/.
set -euo pipefail
COMPOSE="${COMPOSE:-docker compose}"
DIR="${TULIP_DIR:-$HOME/tulip}"
REPO="https://github.com/OpenAttackDefenseTools/tulip.git"

if [ -d "$DIR/.git" ]; then
  echo "[*] updating Tulip in $DIR"
  git -C "$DIR" pull --ff-only || echo "[!] git pull failed, using existing checkout"
else
  echo "[*] cloning Tulip -> $DIR"
  git clone "$REPO" "$DIR"
fi

cd "$DIR"
[ -f .env ] || cp .env.example .env
mkdir -p pcaps

# bind the dashboard to localhost only (don't expose port 3000 to the network)
sed -i 's|"3000:3000"|"127.0.0.1:3000:3000"|' docker-compose.yml 2>/dev/null || true

cat <<EOF

[>] BEFORE this is useful, fill in the kickoff values:
    - $DIR/.env                        : TICK_START, TICK_LENGTH, FLAG_REGEX, VM_IP
    - $DIR/services/api/configurations.py : your real service IPs / ports / names
EOF
read -rp "Open .env now? [y/N] " a; [ "${a:-N}" = y ] && "${EDITOR:-nano}" .env

echo "[*] building + starting Tulip..."
$COMPOSE up -d --build
$COMPOSE ps
echo
echo "[*] Tulip -> http://127.0.0.1:3000/"
echo "[*] drop completed pcaps into: $DIR/pcaps/   (see 'Tcpdump' option for capture)"
