#!/usr/bin/env bash
# Send normal + injection requests to the test vulnbox so there's traffic to capture.
IP="${1:-}"
[ -z "$IP" ] && { echo "usage: gen-traffic.sh <vulnbox-ip>"; exit 1; }
B="http://$IP:8080/ping"
echo "[*] sending traffic to $B ..."
for i in 1 2 3 4 5; do curl -s "$B?host=127.0.0.1" >/dev/null; sleep 0.3; done
curl -s "$B?host=127.0.0.1;id" >/dev/null
curl -s "$B?host=%3Bcat%20/etc/hostname" >/dev/null
echo "[*] sent 5 normal + 2 injection requests. Check the dashboard."
