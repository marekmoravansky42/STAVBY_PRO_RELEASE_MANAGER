# DEV001 FIX175 – Async context guards

Low-risk analyzer stabilization:
- Create Project Profile now checks `mounted` after asynchronous platform
  detection and before mutating UI state.
- Project Clone now checks `mounted` after the asynchronous profile-name dialog
  before opening the confirmation dialog.

No build, export, release, Integrity or Publish Gate behavior is changed.

Identity: Build 292 / DEV001 FIX175.
