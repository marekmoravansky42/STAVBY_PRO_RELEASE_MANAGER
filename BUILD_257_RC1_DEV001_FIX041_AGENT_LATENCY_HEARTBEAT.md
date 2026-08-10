# FIX041 – Agent Latency Heartbeat

Built from confirmed FIX040.

- Dashboard Agent status now shows real Local Agent latency, e.g. `Pripojený • 8 ms`.
- Heartbeat still runs every 5 seconds.
- Heartbeat timer is explicitly cancelled when Release Manager closes.
- Remote Agent status from FIX039 remains supported.
- Non-destructive Workspace Sync from FIX038 remains preserved.
