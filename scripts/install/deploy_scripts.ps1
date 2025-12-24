# Deploy Lua Scripts to Game Folder
# Copies project scripts to REFramework autorun folder

param(
    [string]$GamePath,
    [string]$Game = "RE7",
    [switch]$Watch
)

$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

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
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp][$Type] $Message" -ForegroundColor $colors[$Type]
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

function Deploy-Scripts($GamePath) {
    $autorunPath = Join-Path $GamePath "reframework\autorun"

    if (-not (Test-Path $autorunPath)) {
        New-Item -ItemType Directory -Path $autorunPath -Force | Out-Null
    }

    $sourcefolders = @(
        @{ Path = "scripts\core"; Files = "*.lua" },
        @{ Path = "scripts\detectors"; Files = "*.lua" },
        @{ Path = "scripts\games"; Files = "re7.lua" }
    )

    $copied = 0
    foreach ($source in $sourcefolders) {
        $sourcePath = Join-Path $ScriptRoot $source.Path
        if (Test-Path $sourcePath) {
            $files = Get-ChildItem -Path $sourcePath -Filter $source.Files
            foreach ($file in $files) {
                Copy-Item -Path $file.FullName -Destination $autorunPath -Force
                Write-Status "Deployed: $($file.Name)" "Success"
                $copied++
            }
        }
    }

    return $copied
}

# Main execution
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Script Deployer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find game path
if (-not $GamePath) {
    $GamePath = Find-GamePath -Game $Game
    if (-not $GamePath) {
        Write-Status "Could not auto-detect game path." "Error"
        exit 1
    }
}

Write-Status "Target: $GamePath" "Info"
Write-Status "Source: $ScriptRoot" "Info"
Write-Host ""

if ($Watch) {
    Write-Status "Watch mode enabled. Press Ctrl+C to stop." "Info"
    Write-Host ""

    # Initial deploy
    Deploy-Scripts -GamePath $GamePath

    # Watch for changes
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = Join-Path $ScriptRoot "scripts"
    $watcher.Filter = "*.lua"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    $action = {
        $path = $Event.SourceEventArgs.FullPath
        $name = $Event.SourceEventArgs.Name
        Start-Sleep -Milliseconds 100  # Debounce

        $autorunPath = Join-Path $GamePath "reframework\autorun"
        $fileName = Split-Path $path -Leaf
        Copy-Item -Path $path -Destination $autorunPath -Force

        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp][Success] Reloaded: $fileName" -ForegroundColor Green
    }

    Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null
    Register-ObjectEvent $watcher "Created" -Action $action | Out-Null

    try {
        while ($true) { Start-Sleep -Seconds 1 }
    }
    finally {
        $watcher.EnableRaisingEvents = $false
        Get-EventSubscriber | Unregister-Event
    }
}
else {
    $count = Deploy-Scripts -GamePath $GamePath
    Write-Host ""
    Write-Status "Deployed $count scripts." "Success"
}
