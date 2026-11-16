# adducksetup 🦆

Menu-driven A&D network-monitoring setup. One repo, run on both boxes.
Deterministic shell, offline after the first clone, **no AI, no external backend.**

```
bash setup.sh
```

```
============== adducksetup ==============
  1) tcpdump   capture  (run ON THE VULNBOX)
  2) tulip     dashboard (run ON THE PWNBOX)
  3) pkappa    dashboard (run ON THE PWNBOX)
  4) status    docker ps
  q) quit
```

## The flow

```
 VULNBOX                                   PWNBOX
 ───────                                   ──────
 pick 1) tcpdump                           pick 2) tulip  OR  3) pkappa
   detects your IP / iface / ports           paste the config from step 1
   starts rotating capture                   brings the dashboard up
   moves done pcaps -> ready/                pulls pcaps:  rsync ready/ -> dashboard
   PRINTS the config you need  ───copy──►    browse the attacks in the UI
```

1. **On the Vulnbox:** `git pull` the repo on the Pwnbox, then `scp` it over (the Vulnbox usually can't reach GitHub). Run `bash setup.sh`, pick **1**. It auto-detects your VM IP, interface and listening ports, starts the capture, and **prints the values to copy to the Pwnbox**.
2. **On the Pwnbox:** `bash setup.sh`, pick **2** (tulip) or **3** (pkappa). It prompts for the config, you paste what step 1 printed (+ the organiser's flag regex / tick), brings the dashboard up, and offers to **rsync-pull** the pcaps from the Vulnbox into the dashboard.

## What each option needs

| Step | Where | You provide |
| --- | --- | --- |
| 1 tcpdump | Vulnbox | capture interface (it lists them for you) |
| 2 tulip | Pwnbox | VM_IP, service IPs/ports, FLAG_REGEX + TICK_LENGTH (organiser) |
| 3 pkappa | Pwnbox | a UI password + an upload password (you choose) |

Both dashboards then ask for the **vulnbox `user@ip`** and the **ready dir** to pull pcaps from.

## ⚠️ Read before you rely on this

- **Situation 1 only** — needs shell on the Vulnbox to capture. No shell (image-only) = no pcap source; fall back to the scoreboard + source review + ItikGuard.
- **Run ONE dashboard** (tulip *or* pkappa), not both — redundant and RAM-hungry on a ~7.7 GB Pwnbox.
- **SSH key first** — the pcap pull rsyncs every 5s; set up an SSH key / ssh-agent to the Vulnbox or it'll ask for a password each loop.
- **Needs internet** to clone Tulip/pkappa2 the first time (on the Pwnbox). Pre-stage if the Pwnbox is offline.
- **Authorised interfaces only**, and confirm running tcpdump on the Vulnbox is allowed.
- Auto-detects compose spelling (`docker compose` vs `docker-compose`).
- **Not AI.** Prepare and test this **before** the final; AI help is prohibited during the match.
