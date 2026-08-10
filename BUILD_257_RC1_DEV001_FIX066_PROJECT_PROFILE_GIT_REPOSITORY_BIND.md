# FIX066 – Project Profile Git Repository Bind

Built from FIX065.

The Portable Backup confirmed that both current Project Profiles had an empty
`gitRepository`. Therefore Release Manager had no project-specific repository
URL to restore after `origin` was missing.

New behavior:
- existing Git origin is detected and automatically saved into the matching
  Project Profile;
- if origin is missing but Project Profile already contains `gitRepository`,
  Release Manager restores `origin` automatically;
- if both are missing, URL is requested only once;
- after successful manual `NASTAVIŤ ORIGIN`, the URL is persisted into that
  Project Profile for future runs and New PC Export/Restore;
- repository settings remain project-specific and are not copied from the
  global GitHub Updates configuration.

Existing origin is never overwritten automatically.
