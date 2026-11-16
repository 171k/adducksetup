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
  s) stage     bundle the pwnbox's tcpdump into the kit (PWNBOX, pre-scp)
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

1. **Pwnbox:** `git clone` this repo (needs internet once). `scp -r adducksetup <user>@<vulnbox>:~/` to the vulnbox (it usually can't reach GitHub).
2. **Vulnbox:** `bash setup.sh` → **1**. Auto-detects your IP/iface/ports, starts the capture, and **prints the values to copy to the Pwnbox**.
3. **Pwnbox:** `bash setup.sh` → **2** (tulip) or **3** (pkappa). Paste the config, dashboard comes up, and it **rsync-pulls** the pcaps from the vulnbox.

## If the Vulnbox has no tcpdump

First, on the vulnbox: `which tcpdump` — it's **usually pre-installed**, so you're probably fine. If it's missing:

1. **Best fix — bundle the Pwnbox's tcpdump.** On the **Pwnbox**, run `setup.sh` → **s**. It copies the Pwnbox's own `tcpdump` + its `libpcap` into `bin/` (trusted binary, same Linux image = compatible). Then **re-scp** the kit to the vulnbox. Option 1 uses `bin/tcpdump` automatically when the system one is missing.
2. If the vulnbox is online: `sudo apt install tcpdump`.
3. Another capture tool? `which tshark dumpcap` — Wireshark's CLI does the same job.
4. **Nothing captures?** Drop to app-level: **ItikGuard** (logs attacks from inside the service) + the **scoreboard**. You're never blind.

> Why not just ship a tcpdump binary in the repo? Because that would mean running an unknown downloaded binary **as root** on the vulnbox. The `s` step uses the Pwnbox's *own* trusted tcpdump instead.

## ⚠️ Read before you rely on this

- **Situation 1 only** — needs shell on the vulnbox to capture. No shell (image-only) = no pcap source; fall back to the scoreboard + source review + ItikGuard.
- **Run ONE dashboard** (tulip *or* pkappa), not both — redundant and RAM-hungry on a ~7.7 GB Pwnbox.
- **SSH key first** — the pcap pull rsyncs every 5s; set up an SSH key / ssh-agent to the vulnbox or it'll prompt for a password each loop.
- **Needs internet** to clone Tulip/pkappa2 the first time (on the Pwnbox). Pre-stage if offline.
- **Authorised interfaces only**, and confirm running tcpdump on the vulnbox is allowed.
- Auto-detects compose spelling (`docker compose` vs `docker-compose`).
- **Not AI.** Prepare and test this **before** the final; AI help is prohibited during the match.
