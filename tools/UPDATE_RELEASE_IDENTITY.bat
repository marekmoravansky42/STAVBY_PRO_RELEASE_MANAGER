@echo off
setlocal
if "%~1"=="" (
  echo Pouzitie:
  echo   UPDATE_RELEASE_IDENTITY.bat "DEV026 FIX046 POPIS"
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_release_identity.ps1" -Stage "%~1"
exit /b %ERRORLEVEL%
