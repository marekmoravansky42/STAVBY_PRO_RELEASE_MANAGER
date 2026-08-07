# STAVBY PRO Release Manager 6.2.0 LTS – Build 217 FIX 001

## Opravy

- Obnovený kompatibilný wrapper `_writeCrashLog(...)` v `_ReleaseManagerPageState`.
- Wrapper odovzdáva diagnostiku do centralizovaného `AppStartup.writeCrashLog(...)`.
- Opravených 35 hlásení `undefined_method` z `flutter analyze`.
- Odstránený nepoužívaný import `test_result.dart` v `automated_test.dart`.
- Verzia a build zostávajú `6.2.0+217`; ide o FIX 001 toho istého buildu.
