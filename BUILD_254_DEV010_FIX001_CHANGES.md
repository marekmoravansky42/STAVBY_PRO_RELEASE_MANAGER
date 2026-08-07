# STAVBY PRO Release Manager 7.1.0 LTS – Build 254 DEV010 FIX001

## Analyzer compatibility fix

- Fixed nullable `RemoteAgent?` use during Local Agent registration.
- Removed four unnecessary imports reported by `flutter analyze`.
- Replaced deprecated `Color.withOpacity()` with `withValues(alpha:)`.
- Replaced deprecated `DropdownButtonFormField.value` with `initialValue`.
- Multi-Agent Scheduler v1 functionality remains unchanged.
