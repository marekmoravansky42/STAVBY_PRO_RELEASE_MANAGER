@echo off
setlocal
cd /d "%~dp0"
title STAVBY PRO Release Manager - Windows build

echo ============================================================
echo STAVBY PRO Release Manager 3.4.15 - Build 71
echo ============================================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo CHYBA: Flutter nebol najdeny v PATH.
  echo Spusti "flutter doctor" v novom CMD a oprav instalaciu Flutter SDK.
  pause
  exit /b 1
)

echo [1/6] Kontrola Flutter prostredia...
flutter doctor
if errorlevel 1 (
  echo.
  echo CHYBA: flutter doctor hlasil problem. Pre Windows build musi byt
  echo nainstalovane Visual Studio s workloadom Desktop development with C++.
  pause
  exit /b 1
)

echo.
echo [2/6] flutter clean
call flutter clean || goto :error

echo.
echo [3/6] flutter pub get
call flutter pub get || goto :error

echo.
echo [4/6] flutter analyze
call flutter analyze || goto :error

echo.
echo [5/6] flutter test
call flutter test || goto :error

echo.
echo [6/6] flutter build windows --release
call flutter build windows --release || goto :error

echo.
echo ============================================================
echo BUILD USPESNY
echo EXE a potrebne DLL subory su v:
echo %CD%\build\windows\x64\runner\Release
echo.
echo Dolezite: na iny pocitac kopiruj CELÝ priecinok Release,
echo nie iba samotny EXE subor.
echo ============================================================
explorer "%CD%\build\windows\x64\runner\Release"
pause
exit /b 0

:error
echo.
echo BUILD ZLYHAL. Precitaj poslednu chybu vyssie.
pause
exit /b 1
