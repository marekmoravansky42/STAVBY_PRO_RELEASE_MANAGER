# Release Manager 8.0.0 DEV – Build 255 DEV001

## Build Completion Center – Phase 1

- Dashboard action **Uložiť build** now opens one unified completion window.
- Automatically loads project, version, build, Git branch and changed-file count.
- Adds fields for Commit Message, change description and internal notes.
- Adds options for commit, push, tag, Release ZIP, Build Report, history and ZIP synchronization.
- Performs workspace, Git and build-identity preflight checks.
- Saves the completed draft to `.release_manager/build_completion_draft.json` in the selected project.
- Phase 1 intentionally stores the draft only; execution of Git/export steps follows in the next tested phase.
