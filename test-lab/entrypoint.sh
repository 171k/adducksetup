#!/usr/bin/env bash
# start sshd (background) + the vulnerable test service (foreground)
/usr/sbin/sshd
echo "[test-vulnbox] sshd up on :22, vuln service on :8080"
exec python3 /root/vuln_service.py
