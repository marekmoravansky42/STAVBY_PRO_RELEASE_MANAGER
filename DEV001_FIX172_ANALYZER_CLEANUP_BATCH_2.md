# DEV001 FIX172 – Analyzer cleanup batch 2

Low-risk cleanup only:
- removed an unnecessary non-null assertion from detected Git origin URL,
- added a `mounted` guard after async Git/process work before opening the Git
  publisher dialog,
- simplified one unnecessary string interpolation brace in release package naming.

No build, release, export, Integrity or Publish Gate behavior is changed.

Identity: Build 289 / DEV001 FIX172.
