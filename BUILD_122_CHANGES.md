# STAVBY PRO Release Manager 4.0.16 LTS – Build 122

Oprava Build 121:
- odstránená nepoužívaná metóda `_prepareWindowsBuild`,
- tým odstránený warning `unused_element`, ktorý zastavoval `flutter analyze`,
- nový APK-style Windows DEV Workflow zostáva zachovaný,
- tlačidlo `SPUSTIŤ KOMPLETNÝ WINDOWS BUILD` zostáva zachované,
- jednotlivé Windows kroky a ich progress/stav zostávajú zachované.

Windows kompletný build:
analyze → clean → ephemeral → pub get → build windows --release →
kontrola EXE → spustenie EXE → 5-sekundový test.
