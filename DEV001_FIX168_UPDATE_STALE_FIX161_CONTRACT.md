# DEV001 FIX168 – Update stale FIX161 contract

FIX167 intentionally changed the UX:
- FAST/FULL build no longer opens Windows Explorer automatically,
- export remains physically verified,
- manual Explorer buttons remain available,
- Last Export ZIP moved to Project Information.

The old FIX161 contract still required automatic Explorer opening and therefore
failed even though the new FIX167 behavior was correct.

FIX168 updates only that stale test expectation. Runtime behavior from FIX167
is unchanged.

Identity: Build 285 / DEV001 FIX168.
