
# wezterm config install — windows
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configDir = Join-Path $env:USERPROFILE ".config\wezterm"

New-Item -ItemType Directory -Path $configDir -Force | Out-Null
Copy-Item (Join-Path $scriptDir "wezterm.lua") (Join-Path $configDir "wezterm.lua") -Force
Write-Host "installed wezterm.lua to $configDir" -ForegroundColor Green

# remove legacy symlink if it exists
$legacyPath = Join-Path $env:USERPROFILE ".wezterm.lua"
if (Test-Path $legacyPath) {
    Remove-Item $legacyPath -Force
    Write-Host "removed legacy symlink $legacyPath" -ForegroundColor Green
}
