# DEV001 FIX160 – Update stale Export ZIP contract test

The only failing Flutter test after FIX159 was the older FIX158 contract test.
It still expected the former SnackBar action label `OTVORIŤ`, while FIX159
intentionally replaced that UI with `OTVORIŤ V PRIESKUMNÍKOVI`.

FIX160:
- updates only that stale contract expectation,
- leaves FIX159 export runtime behavior unchanged,
- keeps physical file verification, exact path display, Explorer selection and
  completion dialog intact.

Identity: 8.0.0 RC1 • Build 277 • DEV001 FIX160.
