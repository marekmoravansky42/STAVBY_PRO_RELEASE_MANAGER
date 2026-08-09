# Release Manager Build 257 RC1 DEV001 – FAST DEV BUILD

New accelerated test loop:
- FAST DEV BUILD: flutter analyze → flutter test → flutter build windows --release.
- Skips flutter clean and flutter pub get for ordinary code-only DEV iterations.
- FULL BUILD remains available as the clean fallback.
- FAST and FULL both keep Project Identity Guard, build report and Release ZIP export.
- Reports and success dialog explicitly show which steps were skipped.
- Build number remains 257 until this Release Manager change is validated on the Windows test machine.

Recommended workflow:
1. Synchronizovať ZIP.
2. FAST DEV BUILD for normal STAVBY PRO code changes.
3. FULL BUILD when pubspec/dependencies/plugins/Windows native configuration changed,
   or when FAST mode fails because of stale/generated/dependency state.
