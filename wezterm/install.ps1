
# wezterm config install — windows
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configDir = Join-Path $env:USERPROFILE ".config\wezterm"

New-Item -ItemType Directory -Path $configDir -Force -ErrorAction Stop | Out-Null
Copy-Item (Join-Path $scriptDir "wezterm.lua") (Join-Path $configDir "wezterm.lua") -Force -ErrorAction Stop
Write-Host "installed wezterm.lua to $configDir" -ForegroundColor Green

# back up legacy config if it exists
$legacyPath = Join-Path $env:USERPROFILE ".wezterm.lua"
if (Test-Path $legacyPath) {
    $backup = "$legacyPath.bak"
    try {
        Move-Item $legacyPath $backup -Force -ErrorAction Stop
        Write-Host "backed up $legacyPath to $backup" -ForegroundColor Yellow
    } catch {
        Write-Warning "could not back up ${legacyPath}: $($_.Exception.Message)"
    }
}
