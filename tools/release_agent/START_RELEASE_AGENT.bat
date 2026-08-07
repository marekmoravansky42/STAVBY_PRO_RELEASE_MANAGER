@echo off
setlocal
cd /d "%~dp0"
echo ================================================
echo STAVBY PRO RELEASE AGENT - BUILD 254 DEV001
echo ================================================
echo.
where dart >nul 2>nul
if errorlevel 1 (
  echo CHYBA: Dart SDK nebol najdeny v PATH.
  echo Spust Flutter terminal alebo pridaj Dart SDK do PATH.
  pause
  exit /b 1
)
echo Agent sa spusta na porte 47833...
echo Pre ukoncenie stlac Ctrl+C.
echo.
dart run bin\release_agent.dart 47833
pause
