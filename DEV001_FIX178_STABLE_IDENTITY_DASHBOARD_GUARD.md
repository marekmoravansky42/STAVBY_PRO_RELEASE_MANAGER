# DEV001 FIX178 – Stable identity + Dashboard regression guard

No runtime behavior is changed.

Adds regression protection for:
- pubspec build and AppVersion build staying synchronized,
- Last Export ZIP remaining in Project Information rather than Last Build,
- FAST DEV not automatically opening Explorer,
- manual export navigation remaining available,
- explicit DEV / RC / FINAL export-stage routing remaining intact.

Identity: Build 295 / DEV001 FIX178.
