# Build 254 DEV020 FIX001 – Deep Pub Cache Repair

- oprava už nemaže iba projektový `.dart_tool`,
- spustí `dart pub cache repair`,
- následne vykoná `flutter clean` a `flutter pub get`,
- overí fyzickú existenciu vstupných súborov balíkov `file_picker`, `package_info_plus`, `printing`, `geolocator_windows` a `image_picker_windows`,
- v prípade neúplnej cache zobrazí presný chýbajúci súbor,
- po úspechu pokračuje od Flutter analyze.
