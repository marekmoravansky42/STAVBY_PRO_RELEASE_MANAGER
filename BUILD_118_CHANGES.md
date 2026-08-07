# STAVBY PRO Release Manager 4.0.14 LTS – Build 120

Windows DEV build now performs:
- flutter clean
- recursive removal of windows\flutter\ephemeral
- flutter pub get
- flutter analyze
- flutter build windows --release
- EXE verification

This prevents stale .plugin_symlinks from causing PathExistsException / errno 183.
APK workflow is unchanged.
