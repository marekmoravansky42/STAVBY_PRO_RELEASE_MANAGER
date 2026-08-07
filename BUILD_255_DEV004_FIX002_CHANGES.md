# Build 255 DEV004 FIX002 – Git Preflight Timeout & Recovery

- každý Git príkaz v kritickej preflight ceste má časový limit,
- zaseknutý proces sa ukončí a workflow pokračuje do výsledkového dialógu,
- kontrola `git cat-file` má vlastný 45-sekundový timeout,
- celý Git preflight má maximálny limit 3 minúty,
- zastaraný `.git/index.lock` sa bezpečne odstráni, aktívny lock sa nemaže,
- do živého terminálu sa zapisujú jednotlivé fázy preflightu,
- Git fetch neťahá tagy a má obmedzený čas,
- výsledkové okno sa zobrazí aj pri timeout-e alebo chybe.
