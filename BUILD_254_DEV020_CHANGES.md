# Build 254 DEV020 – Workflow Diagnostics & Dependency Repair

- inteligentný súhrn chýb a upozornení v diagnostickom okne,
- zvýraznenie prvej hlavnej chyby,
- otvorenie problémového súboru priamo z diagnostiky,
- automatická oprava závislostí: odstránenie `.dart_tool` a plugin metadata, `flutter clean`, `flutter pub get`, kontrola `package_config.json`,
- automatické pokračovanie od `flutter analyze` po oprave závislostí,
- automatický úspešný Build Report po One Click Builde,
- aplikácia označená ako DEV020.
