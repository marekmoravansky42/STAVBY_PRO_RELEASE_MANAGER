# Build 319 / FIX272

Corrective fix for FIX271 contract test.

- Build remains 319.
- Export ZIP history behavior from FIX271 is unchanged.
- Fixed Dart parser error in `test/fix271_export_zip_history_contract_test.dart` caused by `$` escaping inside the expected regex string.
- Stage identity: RC1 DEV001 FIX272.
