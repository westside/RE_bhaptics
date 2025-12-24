@echo off
:: REFramework Uninstaller
:: Double-click to run

echo.
echo REFramework Uninstaller
echo =======================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*

pause
