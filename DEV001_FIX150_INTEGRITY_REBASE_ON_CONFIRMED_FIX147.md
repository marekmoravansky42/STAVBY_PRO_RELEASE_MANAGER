# DEV001 FIX150 – Integrity restore rebased on confirmed FIX147

FIX149 is discarded. The diagnostic showed that the previous cleanup chain had
removed dashboard/build functions still referenced by the UI and also contained
a malformed appended contract test.

FIX150 is rebuilt from the user-confirmed working FIX147 / Build 264 and applies
only the Release Integrity startup fix:
- wait for App Settings + Project Profiles before restoring persisted integrity,
- rediscover Distribution Center before validation,
- prevent the timer from resetting to NEOVERENÉ while startup discovery loads,
- refresh persisted Integrity/Publish Gate when activating a project profile.

No dashboard/build/export functions are removed in this build.
Identity: 8.0.0 RC1 • Build 267 • DEV001 FIX150.
