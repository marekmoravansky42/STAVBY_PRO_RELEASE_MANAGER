# STAVBY PRO Release Manager 6.2.1 LTS – Build 218

## Windows Workspace State Extraction

- Added `WindowsWorkspaceController` under `lib/features/windows_workspace/`.
- Moved Windows build-step state, environment checks, details and check timestamp out of `main.dart`.
- Kept the existing Windows commands, dialogs and visual workflow unchanged.
- Added explicit controller disposal to the Release Manager page lifecycle.
- Synchronized the application version to `6.2.1+218`.

This is the first low-risk stage of the Windows Workspace extraction. Process execution and UI widgets remain in place to avoid a large behavioral regression in one build.
