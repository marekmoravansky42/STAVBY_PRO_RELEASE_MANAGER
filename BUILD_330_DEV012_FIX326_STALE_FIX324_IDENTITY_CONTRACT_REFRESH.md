# Build 330 / DEV012 / FIX326

Repairs the stale exact-current-FIX assertion introduced by FIX324.
Also makes FIX325's repair regression future-FIX compatible to prevent
the same one-step identity cascade on the next repair.

Canonical identity: 8.0.0+330 / RC1 DEV012 FIX326.
