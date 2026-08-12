# FIX073 – Release Dashboard v1

Built from confirmed FIX072A.

Adds a dedicated Release Dashboard under Overview.

It shows, at a glance:
- active project/version/build;
- current release readiness percentage;
- Windows and Android artifact status;
- Git branch and changed-file count;
- Project Profile / Git / origin / release readiness checklist;
- latest LTS / FINAL release when detected;
- quick actions to Release Recipes, Distribution Center, Git Publisher and
  release-state refresh.

Release Dashboard reuses Persistent Release Detection from FIX072A and does
not duplicate or move release artifacts.
