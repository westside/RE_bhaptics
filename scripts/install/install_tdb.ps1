# Quick TDB version installer
$ErrorActionPreference = "Stop"

$GamePath = "D:\SteamLibrary\steamapps\common\RESIDENT EVIL 7 biohazard Demo"
$TempDir = Join-Path $env:TEMP "REFramework_TDB"

Write-Host "Fetching latest release..." -ForegroundColor Cyan
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/praydog/REFramework/releases/latest" -Headers @{"User-Agent"="REFramework-Installer"}

$asset = $release.assets | Where-Object { $_.name -eq "RE7_TDB49.zip" }
if (-not $asset) {
    Write-Host "RE7_TDB.zip not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Downloading $($asset.name)..." -ForegroundColor Cyan
$zipPath = Join-Path $env:TEMP "RE7_TDB.zip"

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
$ProgressPreference = 'Continue'

Write-Host "Extracting..." -ForegroundColor Cyan
if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force }
Expand-Archive -Path $zipPath -DestinationPath $TempDir -Force

$dll = Get-ChildItem -Path $TempDir -Filter "dinput8.dll" -Recurse | Select-Object -First 1
if (-not $dll) {
    Write-Host "dinput8.dll not found in archive!" -ForegroundColor Red
    exit 1
}

Copy-Item -Path $dll.FullName -Destination (Join-Path $GamePath "dinput8.dll") -Force
Write-Host "Installed TDB version successfully!" -ForegroundColor Green

# Cleanup
Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
