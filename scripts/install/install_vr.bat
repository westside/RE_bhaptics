@echo off
:: REFramework VR Quick Installer
:: Double-click to run or execute from command line

echo.
echo REFramework VR Installer
echo ========================
echo.

:: Check for PowerShell
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is required but not found.
    pause
    exit /b 1
)

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0install_for_vr.ps1" %*

pause
