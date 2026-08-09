# Release Manager Build 257 RC1 DEV001 FIX001

Fixes the three Flutter analyze errors introduced by DEV001.

- Dependency-repair retry explicitly starts FULL BUILD (`fastMode: false`).
- Existing dashboard action “SPUSTIŤ CELÝ BUILD” explicitly starts FULL BUILD.
- Existing workflow action “2. SPUSTIŤ CELÝ BUILD” explicitly starts FULL BUILD.
- FAST DEV BUILD remains available in Development Center.
- Build stays 257 because this is a FIX build for DEV001.
