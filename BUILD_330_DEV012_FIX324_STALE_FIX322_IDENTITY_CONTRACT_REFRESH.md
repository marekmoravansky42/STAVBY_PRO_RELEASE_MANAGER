# Build 330 / DEV012 / FIX324

## Stale FIX322 identity contract refresh

FIX323 closure exposed one historical regression test that pinned the current
canonical stage to `RC1 DEV012 FIX322`.

FIX324 keeps the actual FIX322 dialog-parenthesis regression checks intact,
but makes its identity assertion future-FIX compatible inside Build 330 /
DEV012. Canonical identity advances to `RC1 DEV012 FIX324`.

No production UI behavior is changed.
