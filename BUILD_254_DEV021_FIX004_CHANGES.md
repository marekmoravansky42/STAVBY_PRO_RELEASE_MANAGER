# STAVBY PRO Release Manager 7.1.0 LTS – Build 254 DEV021 FIX004

## Clean Workspace Synchronization

- Workspace Sync now removes all old project content except `.git`, `.gitignore`, and `.release_manager`.
- The complete development ZIP is copied into a clean workspace.
- `pubspec.yaml` and the version service are copied explicitly after robocopy.
- The synchronized `pubspec.yaml` must be byte-identical to the source ZIP.
- Version/build identity is verified before One Click Build is enabled.
- Derived Flutter data and stale build state cannot survive synchronization.
