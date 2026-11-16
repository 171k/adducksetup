#!/usr/bin/env bash
# =====================================================================
#  RUN ON THE PWNBOX (Docker host).
#  Stands up the fake vulnbox, wires passwordless ssh host->container,
#  copies adducksetup in, and prints the steps to run the real pipeline.
# =====================================================================
set -euo pipefail
cd "$(dirname "$0")"              # test-lab/
KIT="$(cd .. && pwd)"            # adducksetup/

if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then COMPOSE="docker-compose"
else echo "[!] need Docker"; exit 1; fi

echo "[*] building + starting the fake vulnbox..."
$COMPOSE up -d --build
C=adduck-test-vulnbox
sleep 2
IP="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "$C")"
[ -z "$IP" ] && { echo "[!] no container IP (is it running?)"; exit 1; }

# passwordless ssh host -> container (inject the host's pubkey via docker exec)
[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
docker exec "$C" mkdir -p /root/.ssh
docker cp ~/.ssh/id_rsa.pub "$C":/root/.ssh/authorized_keys
docker exec "$C" chmod 600 /root/.ssh/authorized_keys
ssh-keygen -R "$IP" >/dev/null 2>&1 || true

# copy adducksetup into the container (the "vulnbox" copy)
docker exec "$C" rm -rf /root/adducksetup
docker cp "$KIT" "$C":/root/adducksetup

cat <<EOF

================= FAKE VULNBOX READY =================
  container : $C
  vulnbox IP: $IP        (ssh root@$IP is passwordless now)
  service   : http://$IP:8080/   (also http://localhost:8099/)
=====================================================

RUN THESE (3 terminals on this Pwnbox):

  T1  capture (plays the vulnbox):
      ssh -o StrictHostKeyChecking=accept-new root@$IP \\
          'cd /root/adducksetup && bash setup.sh'
      -> pick 1,  interface = eth0    (leave it running)

  T2  generate attack traffic:
      bash "$PWD/gen-traffic.sh" $IP

  T3  dashboard (plays the pwnbox):
      cd "$KIT" && bash setup.sh
      -> pick 2 (tulip), then pull from:
           vulnbox user@ip : root@$IP
           ready dir       : /root/adduck_pcaps/ready

  Open Tulip ( http://127.0.0.1:3000/ ) — you should see the captured
  ping / injection traffic. That proves the whole pipeline end to end.

Teardown:  $COMPOSE down      (from test-lab/)
EOF
