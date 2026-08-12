# FIX071 – Final Release Git Publisher

Built from confirmed FIX070.

After a successful One Click Final Release:
- offers `ULOŽIŤ FINAL DO GITU`;
- validates repository, Git author, origin, branch, changed files and tag;
- detects FINAL identity from `lib/app/app_version.dart`;
- creates a FINAL/LTS tag (for example `v8.0.0-lts-final-b258`);
- runs existing tested Git publish engine:
  git add -> commit -> tag -> push branch -> push tag;
- never overwrites an existing tag;
- if Git publishing fails or is skipped, the already successful FINAL release
  remains intact and can be published later via Git Build Publisher.

No CMD is required.
