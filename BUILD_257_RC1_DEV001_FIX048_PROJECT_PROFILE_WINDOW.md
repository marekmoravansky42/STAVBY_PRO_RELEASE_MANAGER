# FIX048 – Project Profile Window

Built from FIX047.

Dashboard `Zmeniť projekt` now opens the dedicated `Project Profile` management
window. The existing profile system was already present, so this fix exposes
and polishes it instead of duplicating project selection logic.

Window includes:
- active profile summary,
- saved Project Profiles,
- add project,
- activate/open profile,
- rename,
- duplicate,
- delete.

Activating a profile continues to switch project/workspace/Git/build tools
through the existing Project Profile workflow.

FIX047 inline Git origin setup and all previous confirmed functionality remain.
