# FIX047 – Inline Git Origin Setup

Built from FIX046.

When Git Build Publisher detects `Origin: nenastavený`, the same dialog now:
- shows a Git origin URL field,
- provides `NASTAVIŤ ORIGIN`,
- runs `git remote add origin <url>` in the selected workspace,
- updates the preflight immediately after success,
- blocks `ULOŽIŤ BUILD` until origin is configured.

No CMD is required. Existing Git publisher order and all confirmed FIX046
functionality remain preserved.
