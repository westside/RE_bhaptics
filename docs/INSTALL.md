# Installation Guide

## Quick Start

### VR Installation
```batch
# Double-click or run from command line:
scripts\install\install_vr.bat

# Or with PowerShell directly:
powershell -ExecutionPolicy Bypass -File scripts\install\install_for_vr.ps1
```

### Non-VR Installation (Scripting Only)
```batch
scripts\install\install_nonvr.bat

# Or:
powershell -ExecutionPolicy Bypass -File scripts\install\install_for_nonvr.ps1
```

## Parameters

### VR Installer
```powershell
install_for_vr.ps1 [-GamePath <path>] [-Game <RE7|RE8>] [-UseOpenXR] [-Force]
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-GamePath` | Game installation folder | Auto-detect |
| `-Game` | Target game (RE7 or RE8) | RE7 |
| `-UseOpenXR` | Use OpenXR instead of OpenVR | $true |
| `-Force` | Overwrite without prompting | $false |

### Non-VR Installer
```powershell
install_for_nonvr.ps1 [-GamePath <path>] [-Game <RE7|RE8>] [-Force]
```

## Examples

```powershell
# Install VR for RE7 (auto-detect path)
.\install_for_vr.ps1

# Install VR for RE8 with specific path
.\install_for_vr.ps1 -Game RE8 -GamePath "D:\Games\RE8"

# Install Non-VR for RE7 Beginning Hour Demo
.\install_for_nonvr.ps1 -GamePath "C:\Program Files (x86)\Steam\steamapps\common\RESIDENT EVIL 7 Teaser Beginning Hour"

# Force reinstall
.\install_for_vr.ps1 -Force
```

## Supported Games

| Game | Folder Names (Auto-detected) |
|------|------------------------------|
| RE7 | `RESIDENT EVIL 7 biohazard`, `RESIDENT EVIL 7 Teaser Beginning Hour` |
| RE8 | `RESIDENT EVIL VILLAGE` |

## Testing with RE7 Demo

The **RE7 Beginning Hour** demo is free on Steam and can be used for testing:
- Steam: https://store.steampowered.com/app/530620/

REFramework should work with the demo since it uses the same RE Engine.

## After Installation

1. Launch the game
2. Press `INSERT` to open REFramework menu
3. For RE7 VR: Set **Ambient Occlusion** to SSAO or Off
4. Lua scripts go in: `<game folder>/reframework/autorun/`

## Troubleshooting

- **Game crashes on startup**: Try the TDB version (for older game versions)
- **VR not working**: Ensure SteamVR or your OpenXR runtime is running
- **OpenXR issues**: Check your headset's OpenXR runtime is set as default
