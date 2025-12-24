@echo off
:: Deploy scripts to game folder
:: Use: deploy.bat or deploy.bat -Watch for auto-reload

powershell -ExecutionPolicy Bypass -File "%~dp0deploy_scripts.ps1" %*
