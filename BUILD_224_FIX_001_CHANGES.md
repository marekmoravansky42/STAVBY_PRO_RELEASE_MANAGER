# STAVBY PRO Release Manager 6.2.7 LTS – Build 224 FIX 001

## Opravy

- Presunutá direktíva `export` v `lib/design_system.dart` pred deklaráciu triedy `RMDesign`.
- Odstránená nepoužitá lokálna premenná `scheme` a súvisiaca premenná `theme` v `RMSectionCard`.
- Verzia a číslo buildu zostávajú `6.2.7+224`; ide o opravu `FIX 001` bez zvýšenia buildu.

## Diagnostika

Oprava reaguje na oba nálezy z `flutter analyze`:

- `directive_after_declaration`
- `unused_local_variable`
