# FIX045 – Git Build Publisher Preflight

Built directly from confirmed FIX044.

`Uložiť build do Gitu` keeps the existing dialog and workflow, but now shows a
clear Git preflight before the user confirms:
- active branch,
- Git author identity,
- origin remote,
- collision state of the suggested tag.

The existing safe order remains:
git add → commit → tag → push branch → push tag.

FIX044 AI Completion Center, FIX043 Agent Dashboard and FIX038 non-destructive
Workspace Sync remain preserved.
