# FIX253 Transition Engine Scope Fix

Flutter analyze našiel jedinú novú compile chybu:
`Undefined name '_releaseTransitionEngine'`.

Oprava:
- transition engine sa vytvára lokálne priamo v potvrdenom DEV → FINAL flow,
- nevzniká závislosť na State/class scope,
- poradie confirm → backup → apply zostáva nezmenené.
