# REFramework Uninstaller
# Removes REFramework files and restores game to original state

param(
    [string]$GamePath,
    [string]$Game = "RE7",
    [switch]$KeepScripts,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Files installed by REFramework
$REFrameworkFiles = @(
    "dinput8.dll",
    "openvr_api.dll",
    "openxr_loader.dll"
)

# Folders created by REFramework
$REFrameworkFolders = @(
    "reframework"
)

# Steam default paths
$SteamPaths = @(
    "C:\Program Files (x86)\Steam\steamapps\common",
    "C:\Program Files\Steam\steamapps\common",
    "D:\SteamLibrary\steamapps\common",
    "E:\SteamLibrary\steamapps\common"
)

$GameFolders = @{
    "RE7" = @("RESIDENT EVIL 7 biohazard", "RESIDENT EVIL 7 biohazard Demo", "RESIDENT EVIL 7 Teaser Beginning Hour")
    "RE8" = @("RESIDENT EVIL VILLAGE")
}

function Write-Status($Message, $Type = "Info") {
    $colors = @{ "Info" = "Cyan"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red" }
    Write-Host "[$Type] $Message" -ForegroundColor $colors[$Type]
}

function Find-GamePath($Game) {
    foreach ($steamPath in $SteamPaths) {
        if (Test-Path $steamPath) {
            foreach ($folder in $GameFolders[$Game]) {
                $fullPath = Join-Path $steamPath $folder
                if (Test-Path $fullPath) {
                    return $fullPath
                }
            }
        }
    }
    return $null
}

# Main execution
Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "  REFramework Uninstaller" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Find or validate game path
if (-not $GamePath) {
    Write-Status "Searching for $Game installation..."
    $GamePath = Find-GamePath -Game $Game

    if (-not $GamePath) {
        Write-Status "Could not auto-detect game path." "Warning"
        $GamePath = Read-Host "Please enter the game installation path"
    }
}

if (-not (Test-Path $GamePath)) {
    Write-Status "Game path does not exist: $GamePath" "Error"
    exit 1
}

Write-Status "Game found at: $GamePath" "Success"

# Check if REFramework is installed
$dinput = Join-Path $GamePath "dinput8.dll"
if (-not (Test-Path $dinput)) {
    Write-Status "REFramework does not appear to be installed (dinput8.dll not found)" "Warning"
    exit 0
}

# Confirm uninstall
if (-not $Force) {
    Write-Host ""
    Write-Host "This will remove:" -ForegroundColor Yellow
    foreach ($file in $REFrameworkFiles) {
        $filePath = Join-Path $GamePath $file
        if (Test-Path $filePath) {
            Write-Host "  - $file" -ForegroundColor Yellow
        }
    }
    if (-not $KeepScripts) {
        foreach ($folder in $REFrameworkFolders) {
            $folderPath = Join-Path $GamePath $folder
            if (Test-Path $folderPath) {
                Write-Host "  - $folder/ (including all scripts)" -ForegroundColor Yellow
            }
        }
    }
    Write-Host ""
    $response = Read-Host "Continue with uninstall? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Status "Uninstall cancelled." "Warning"
        exit 0
    }
}

# Remove files
Write-Status "Removing REFramework files..."

foreach ($file in $REFrameworkFiles) {
    $filePath = Join-Path $GamePath $file
    if (Test-Path $filePath) {
        Remove-Item -Path $filePath -Force
        Write-Status "Removed: $file" "Success"
    }
}

# Remove folders (unless -KeepScripts)
if (-not $KeepScripts) {
    foreach ($folder in $REFrameworkFolders) {
        $folderPath = Join-Path $GamePath $folder
        if (Test-Path $folderPath) {
            Remove-Item -Path $folderPath -Recurse -Force
            Write-Status "Removed: $folder/" "Success"
        }
    }
} else {
    Write-Status "Keeping reframework/autorun scripts (-KeepScripts)" "Info"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Uninstall Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Status "Game restored to original state." "Success"
Write-Host ""
