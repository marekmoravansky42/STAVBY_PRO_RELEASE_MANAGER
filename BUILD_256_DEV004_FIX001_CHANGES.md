# STAVBY PRO Release Manager 8.0.0 — Build 256 DEV004 FIX001

## Opravy
- Opravené nekompatibilné volania `FilePicker.platform` pre file_picker 11.x.
- Opravený nepodporovaný parameter `tooltip` na `Chip` použitím widgetu `Tooltip`.
- Vyčistené warningy v novom DEV004 kóde: zbytočné non-null assertions, cast, interpolácia, deprecated DropdownButtonFormField value a nepoužitý parameter.
- Pridaná mounted kontrola pred completion dialógom po async operáciách.
- Build číslo ostáva 256 podľa pravidla FIX buildu.

## Testovací cieľ
1. flutter clean
2. flutter pub get
3. flutter analyze
4. flutter test
5. flutter build windows --release
