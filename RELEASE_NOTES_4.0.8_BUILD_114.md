# STAVBY PRO Release Manager 4.0.8 LTS Build 114

## Nová sekcia STAVBY PRO – WINDOWS
- Samostatná navigačná sekcia WINDOWS, oddelená od Android APK.
- Krok 1: rozbalenie ZIP Windows DEV projektu.
- Krok 2: automatické načítanie a overenie projektu po rozbalení.
- Zobrazenie verzie, Flutter buildu a logického buildu.
- Referenčný základ: STAVBY PRO 3.5.56 DEV – Build 130.
- Aktuálny testovací cieľ: STAVBY PRO 3.5.59 DEV – Build 133.

Ďalšie kroky po otestovaní základu: flutter clean, pub get, analyze, test,
flutter build windows, kontrola/spustenie stavby_pro_dev.exe a samostatný Windows export.
