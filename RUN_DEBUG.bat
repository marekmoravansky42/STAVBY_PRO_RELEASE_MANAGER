@echo off
cd /d "%~dp0"
where flutter >nul 2>nul || (echo Flutter nebol najdeny v PATH.& pause & exit /b 1)
call flutter pub get || (pause & exit /b 1)
call flutter run -d windows
pause
