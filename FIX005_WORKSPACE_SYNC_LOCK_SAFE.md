# RC1 Build 257 FIX005
- Workspace Sync never deletes or copies `build/` and `.dart_tool/`.
- Locked generated folders no longer abort ZIP synchronization.
- `.flutter-plugins*` cleanup is best-effort and non-blocking if Windows locks a file.
- `flutter clean` remains responsible for generated build artifacts before compilation.
