# Build 316 DEV001 FIX254

- FINAL FULL BUILD už neexportuje ZIP natvrdo ako DEV; stage sa určuje podľa reálne aplikovaného transition stavu.
- BUILD REPORT zapisuje release stage a DEV → FINAL / FINAL → DEV transition informáciu.
- Dashboard tlačidlo „Otvoriť report“ otvára konkrétny posledný úspešný BUILD_REPORT v Notepade namiesto presmerovania na inú stránku.
- Po FINAL builde zostáva zachovaný bezpečný restore konfigurácie späť do DEV.
