# FIX065 – Git Remote Auto Detection

Built from confirmed FIX064A.

`Uložiť build do Gitu` now detects an existing origin automatically.

Detection order:
1. `git remote get-url origin`
2. `git config --get remote.origin.url`
3. fallback parsing of `git remote -v`

If origin exists, the dialog only displays it in preflight and does not ask
for a URL. The URL field appears only when no origin can be found.

Existing origin is never overwritten automatically.
