# adducksetup test-lab 🧪

A throwaway Docker **fake vulnbox** so you can test the WHOLE adducksetup pipeline
on a single Pwnbox *before* the match — capture → pull → dashboard — without
touching any real competition box.

> ⚠️ Run only in your Pwnbox / a dev box. The service here is **intentionally
> vulnerable** (command injection, on purpose, to generate test traffic). Never deploy it.

## One command

```
cd adducksetup/test-lab
bash run-test.sh
```

It builds the fake vulnbox (sshd + tcpdump + a vulnerable ping service), wires
passwordless ssh, copies adducksetup in, and prints the exact next steps (3 terminals).

## What this actually proves

- option 1 (tcpdump) **captures** and the `-z` hook **moves pcaps to `ready/`**
- the **rsync pull** brings pcaps from the "vulnbox" to the dashboard
- **Tulip** (or pkappa) **ingests** them and shows the ping/injection traffic

If you see the traffic in Tulip, the pipeline works. If not, you found the bug
**today**, not at 10am.

## Also test the "no tcpdump" path (optional)

```
docker exec adduck-test-vulnbox rm /usr/bin/tcpdump     # pretend it's missing
# on the host:  cd adducksetup && bash setup.sh -> s   (stage tcpdump), then re-copy the kit in and retry option 1
```

## Teardown

```
docker compose down      # from test-lab/
```

## Why it works on one box

It uses the container's **bridge IP**, so adducksetup's normal port-22 ssh/rsync
reaches the "vulnbox" unchanged (on a Linux Docker host). No port tweaks needed.
