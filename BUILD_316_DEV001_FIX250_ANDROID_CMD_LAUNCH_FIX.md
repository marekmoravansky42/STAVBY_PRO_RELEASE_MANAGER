# FIX250 Android CMD launch fix

Ručný test potvrdil, že `flutter build apk --release` z obyčajného CMD funguje,
kým rovnaký krok spustený pôvodným One Click runnerom končil na Windows
`CreateProcess error=740` pri štarte CMake.

FIX250 preto:
- na Windows spúšťa iba Android APK release krok cez `cmd.exe /d /s /c`,
- ostatné One Click Flutter kroky necháva na pôvodnom runneri,
- nemení DEV → FINAL preflight ani projektové dáta.
