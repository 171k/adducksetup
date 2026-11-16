#!/usr/bin/env bash
# pkappa2 — clone/update, enable the watch dir, bind local-only, bring up on the Pwnbox.
# Ingests pcaps by: HTTP upload to /upload/<name>.pcap, OR files dropped in ./pcaps_incoming/.
set -euo pipefail
COMPOSE="${COMPOSE:-docker compose}"
DIR="${PKAPPA_DIR:-$HOME/pkappa2}"
REPO="https://github.com/spq/pkappa2.git"

if [ -d "$DIR/.git" ]; then
  echo "[*] updating pkappa2 in $DIR"
  git -C "$DIR" pull --ff-only || echo "[!] git pull failed, using existing checkout"
else
  echo "[*] cloning pkappa2 -> $DIR"
  git clone "$REPO" "$DIR"
fi

cd "$DIR"
[ -f .env ] || cp .env.example .env
mkdir -p pcaps_incoming

# enable the local watch-dir bind mount (commented out by default upstream)
sed -i 's|# *- \./pcaps_incoming:/pcaps_in|- ./pcaps_incoming:/pcaps_in|' docker-compose.yml 2>/dev/null || true
# bind the web UI to localhost only
sed -i 's|- 8080:8080|- 127.0.0.1:8080:8080|' docker-compose.yml 2>/dev/null || true

cat <<EOF

[>] BEFORE starting, set passwords in $DIR/.env :
    - PKAPPA2_USER_PASSWORD   (login to the web UI)
    - PKAPPA2_PCAP_PASSWORD   (auth for the /upload endpoint — used by the capture script)
    PKAPPA2_WATCH_DIR is already /pcaps_in in .env.example (matches the mount above).
EOF
read -rp "Open .env now? [y/N] " a; [ "${a:-N}" = y ] && "${EDITOR:-nano}" .env

echo "[*] building + starting pkappa2..."
$COMPOSE up -d --build
$COMPOSE ps
echo
echo "[*] pkappa2 -> http://127.0.0.1:8080/"
echo "[*] feed it by: dropping pcaps in $DIR/pcaps_incoming/  OR  curl upload (see Tcpdump option)"
