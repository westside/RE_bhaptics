# REFramework Non-VR Installation Script
# For RE7/RE8 modding framework (scripting only, no VR)

param(
    [string]$GamePath,
    [string]$Game = "RE7",
    [switch]$Force,
    [switch]$UseTDB  # Force TDB version
)

$ErrorActionPreference = "Stop"

# Configuration
$GitHubRepo = "praydog/REFramework"
$GitHubApiUrl = "https://api.github.com/repos/$GitHubRepo/releases/latest"
$TempDir = Join-Path $env:TEMP "REFramework_Install"

# Steam default paths
$SteamPaths = @(
    "C:\Program Files (x86)\Steam\steamapps\common",
    "C:\Program Files\Steam\steamapps\common",
    "D:\SteamLibrary\steamapps\common",
    "E:\SteamLibrary\steamapps\common"
)

$GameFolders = @{
    "RE7" = @("RESIDENT EVIL 7 biohazard", "RESIDENT EVIL 7 biohazard Demo", "RESIDENT EVIL 7 Teaser Beginning Hour", "re7")
    "RE8" = @("RESIDENT EVIL VILLAGE", "re8")
}

# TDB version mapping (older game versions need TDB builds)
$TDBVersions = @{
    "RE7" = "RE7_TDB49.zip"
    "RE2" = "RE2_TDB66.zip"
    "RE3" = "RE3_TDB67.zip"
}

# Patterns that indicate demo/trial versions (need TDB)
$DemoPatterns = @("Demo", "Trial", "Teaser", "Beginning Hour")

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
                    $exeFiles = Get-ChildItem -Path $fullPath -Filter "*.exe" -File | Where-Object { $_.Name -notmatch "^(unins|setup)" }
                    if ($exeFiles) {
                        return $fullPath
                    }
                }
            }
        }
    }
    return $null
}

function Get-LatestRelease {
    Write-Status "Fetching latest REFramework release..."
    try {
        $headers = @{ "User-Agent" = "REFramework-Installer" }
        $release = Invoke-RestMethod -Uri $GitHubApiUrl -Headers $headers
        return $release
    }
    catch {
        Write-Status "Failed to fetch release info: $_" "Error"
        return $null
    }
}

function Test-NeedsTDB($GamePath) {
    # Check if game path contains demo/trial patterns
    foreach ($pattern in $DemoPatterns) {
        if ($GamePath -match $pattern) {
            return $true
        }
    }
    return $false
}

function Download-REFramework($Release, $Game, $NeedsTDB) {
    $asset = $null

    # If TDB version is needed, try TDB first
    if ($NeedsTDB) {
        $tdbName = $TDBVersions[$Game]
        if ($tdbName) {
            $asset = $Release.assets | Where-Object { $_.name -eq $tdbName }
            if ($asset) {
                Write-Status "Using TDB version for demo/older game" "Info"
            }
        }
    }

    # Fallback to regular version
    if (-not $asset) {
        $assetName = "$Game.zip"
        $asset = $Release.assets | Where-Object { $_.name -eq $assetName }
    }

    if (-not $asset) {
        Write-Status "Could not find $Game asset in release" "Error"
        return $null
    }

    Write-Status "Downloading $($asset.name) ($('{0:N2}' -f ($asset.size / 1MB)) MB)..."

    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }

    $zipPath = Join-Path $TempDir $asset.name

    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        return $zipPath
    }
    catch {
        Write-Status "Download failed: $_" "Error"
        return $null
    }
}

function Install-NonVR($ZipPath, $GamePath) {
    Write-Status "Installing Non-VR mod to: $GamePath"

    $extractPath = Join-Path $TempDir "extracted"
    if (Test-Path $extractPath) {
        Remove-Item -Path $extractPath -Recurse -Force
    }

    Expand-Archive -Path $ZipPath -DestinationPath $extractPath -Force

    # For Non-VR, only copy dinput8.dll
    $dinput = Get-ChildItem -Path $extractPath -Filter "dinput8.dll" -File -Recurse | Select-Object -First 1

    if (-not $dinput) {
        Write-Status "dinput8.dll not found in archive" "Error"
        return $false
    }

    $destPath = Join-Path $GamePath "dinput8.dll"
    Copy-Item -Path $dinput.FullName -Destination $destPath -Force
    Write-Status "Copied: dinput8.dll" "Success"

    Write-Status "Non-VR installation complete!" "Success"
    return $true
}

# Main execution
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  REFramework Non-VR Installer" -ForegroundColor Cyan
Write-Host "  (Scripting/Modding Framework Only)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
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

# Detect if TDB version is needed
$needsTDB = $UseTDB -or (Test-NeedsTDB -GamePath $GamePath)
if ($needsTDB) {
    Write-Status "Detected: Demo/Trial version - will use TDB build" "Info"
}

# Check for existing installation
$existingDll = Join-Path $GamePath "dinput8.dll"
if ((Test-Path $existingDll) -and -not $Force) {
    $response = Read-Host "REFramework already installed. Overwrite? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Status "Installation cancelled." "Warning"
        exit 0
    }
}

# Download and install
$release = Get-LatestRelease
if (-not $release) {
    exit 1
}

Write-Status "Latest version: $($release.tag_name)" "Info"

$zipPath = Download-REFramework -Release $release -Game $Game -NeedsTDB $needsTDB
if (-not $zipPath) {
    exit 1
}

$success = Install-NonVR -ZipPath $zipPath -GamePath $GamePath

# Cleanup
Write-Status "Cleaning up temporary files..."
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

if ($success) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Status "Usage:" "Info"
    Write-Host "  - Press INSERT to open REFramework menu in-game"
    Write-Host "  - Lua scripts go in: <game>/reframework/autorun/"
    Write-Host ""
    Write-Host "NOTE: Only dinput8.dll was installed (Non-VR mode)." -ForegroundColor Yellow
    Write-Host "      VR features are NOT available." -ForegroundColor Yellow
    Write-Host ""
}
