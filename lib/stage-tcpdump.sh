#!/usr/bin/env bash
# =====================================================================
#  stage-tcpdump  -  RUN ON THE PWNBOX, before you scp the kit to the vulnbox.
#  Copies the Pwnbox's OWN tcpdump + its libpcap into bin/, so option 1 can
#  use them if the vulnbox has no tcpdump. Same competition Linux image =>
#  compatible. (We use the Pwnbox's trusted binary, never a random download.)
# =====================================================================
set -uo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$KIT/bin"
mkdir -p "$BIN"

TD="$(command -v tcpdump || true)"
if [ -z "$TD" ]; then
  echo "[!] no tcpdump on THIS pwnbox either — install it here first:"
  echo "    sudo apt install tcpdump"
  exit 1
fi

cp "$TD" "$BIN/tcpdump" && chmod +x "$BIN/tcpdump"
echo "[*] bundled tcpdump  <- $TD"

# bring the libpcap it needs (the 'battery')
for lib in $(ldd "$TD" 2>/dev/null | awk '/libpcap/{print $3}'); do
  [ -f "$lib" ] && cp "$lib" "$BIN/" && echo "[*] bundled $(basename "$lib")"
done

echo
echo "[*] staged into: $BIN"
echo "[*] now copy the whole kit to the vulnbox, e.g.:"
echo "      scp -r \"$KIT\" <user>@<vulnbox-ip>:~/"
echo "[*] on the vulnbox, option 1 will use bin/tcpdump automatically if needed."
