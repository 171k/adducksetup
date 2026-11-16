# A&D Monitoring Setup Kit 🦆

A small, menu-driven installer for Attack & Defense network monitoring.
Run one script, pick a tool, and it clones + configures + launches it.
Deterministic, offline after the initial clone, **no AI, no external backend.**

```
bash setup.sh
```

```
============== A&D Monitoring Setup ==============
  1) Tulip         PCAP analysis dashboard   (Pwnbox)
  2) pkappa2       PCAP stream dashboard      (Pwnbox)
  3) Tcpdump       capture on the Vulnbox  -> pcaps
  4) Status        show running containers
  q) Quit
```

## What it does

| Option | Where you run it | What it does |
| --- | --- | --- |
| **Tulip** | Pwnbox | clone/update Tulip, bind the dashboard to `127.0.0.1:3000`, `up -d`. Reads pcaps from `~/tulip/pcaps/`. |
| **pkappa2** | Pwnbox | clone/update pkappa2, enable the `pcaps_incoming` watch dir, bind UI to `127.0.0.1:8080`, `up -d`. Ingests via upload **or** the watch dir. |
| **Tcpdump** | **Vulnbox** | rotating capture on the service interface; on each file it uploads to pkappa2 (`MODE=pkappa`) or leaves it to rsync to Tulip (`MODE=move`). |

The script auto-detects whether this box uses `docker compose` (space) or `docker-compose` (hyphen).

## The data flow (Situation 1 only)

```
Vulnbox service traffic
   │  tcpdump  (option 3, ON the Vulnbox)
   ▼
completed .pcap files
   │  upload to pkappa2   OR   rsync to Tulip's pcaps/
   ▼
Tulip / pkappa2 dashboard  (option 1 or 2, ON the Pwnbox)
   ▼
browse & reconstruct the attacks  →  steal exploits
```

## ⚠️ Read before you rely on this

- **Situation 1 only.** This needs you to reach/capture on the **Vulnbox**. If you have **no shell** on the Vulnbox (image-only), there is **no pcap source** — this kit can't help; fall back to the scoreboard + source review + ItikGuard.
- **Run ONE dashboard,** Tulip *or* pkappa2 — not both. They're redundant and both are RAM-hungry (~7.7 GB Pwnbox).
- **Needs internet to clone** Tulip/pkappa2 the first time. If the Pwnbox has no internet at the match, pre-stage the repos via an authorised offline method.
- **Fill the kickoff unknowns:** interface name (`IFACE`), service IPs/ports, flag regex, tick length, dashboard/pcap passwords. The scripts prompt / have clear placeholders.
- **Authorised interfaces only.** Capture only what the rules permit, and confirm that running tcpdump on the Vulnbox is allowed.
- **Not AI.** The kit is deterministic shell. Prepare and test it **before** the final; AI assistance is prohibited during the match.

## Quick start (Situation 1)

1. **Pwnbox:** `bash setup.sh` → pick **2 (pkappa2)**, set passwords, let it come up.
2. **Vulnbox** (via SSH): copy `lib/tcpdump.sh` over, then:
   ```
   IFACE=<svc-iface> MODE=pkappa PKAPPA_URL=http://<pwnbox-ip>:8080 \
   PKAPPA_PCAP_PASSWORD=<pcap-pass> bash tcpdump.sh
   ```
3. Watch attacks land in the pkappa2 UI at `http://127.0.0.1:8080/`.

(For Tulip instead: pick **1**, run tcpdump with `MODE=move`, then on the Pwnbox
`rsync -av --remove-source-files vulnbox:~/pcaps/ ~/tulip/pcaps/`.)
