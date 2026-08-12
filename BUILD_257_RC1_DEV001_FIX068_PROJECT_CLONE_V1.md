# FIX068 – Project Clone v1

Built from confirmed FIX067.

Adds safe physical project cloning from Project Profiles.

- PROJECT CLONE button beside New Profile.
- Also available in each profile's management menu.
- User selects an empty destination directory and new profile name.
- Copies project while excluding `.git`, `.dart_tool`, `build`,
  `.release_manager`.
- Source project is never modified.
- New Project Profile is created automatically.
- New clone profile intentionally has empty `gitRepository`, preventing an
  accidental push to the original repository.
- After completion user may stay on original project or activate the clone.
