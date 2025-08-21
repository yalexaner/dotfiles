function md5 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }

    $hash = Get-FileHash -Path $FilePath -Algorithm MD5
    Write-Output $hash.Hash.ToLower()
}

function filesize {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [switch]$k,  # Kilobytes
        [switch]$m,  # Megabytes  
        [switch]$g,  # Gigabytes
        [switch]$t   # Terabytes
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return
    }
    
    $file = Get-Item $FilePath
    $sizeInBytes = $file.Length
    
    if ($k) {
        Write-Output ([math]::Round($sizeInBytes / 1KB, 2))
    }
    elseif ($m) {
        Write-Output ([math]::Round($sizeInBytes / 1MB, 2))
    }
    elseif ($g) {
        Write-Output ([math]::Round($sizeInBytes / 1GB, 2))
    }
    elseif ($t) {
        Write-Output ([math]::Round($sizeInBytes / 1TB, 2))
    }
    else {
        # Default to bytes
        Write-Output $sizeInBytes
    }
}

function scprm {
    param (
        [string]$serverAddress,
        [string]$filePath,
        [string]$destinationPath = "D:\Downloads\",
        [ConsoleColor]$SuccessColor  = 'Green',
        [ConsoleColor]$FileNameColor = 'Yellow',
        [ConsoleColor]$ErrorColor    = 'Red',
        [ConsoleColor]$InfoColor     = 'Cyan'
    )

    if (-not $serverAddress -or -not $filePath) {
        Write-Host "Error: Missing required arguments" -ForegroundColor $ErrorColor
        Write-Host "Usage: scprm <user@server> <remote_file_path> [<local_path>]" -ForegroundColor $InfoColor
        return
    }

    $fileName = [System.IO.Path]::GetFileName($filePath)

    # Download the file
    & scp "${serverAddress}:${filePath}" "$destinationPath"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: could not download file " -ForegroundColor $ErrorColor -NoNewline
        Write-Host "$fileName" -ForegroundColor $FileNameColor -NoNewline
        Write-Host " from remote server" -ForegroundColor $ErrorColor
        return
    }

    # Remove the remote file
    & ssh "$serverAddress" "rm '$filePath'"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: could not delete file " -ForegroundColor $ErrorColor -NoNewline
        Write-Host "$fileName" -ForegroundColor $FileNameColor -NoNewline
        Write-Host " from remote server" -ForegroundColor $ErrorColor
        return
    }

    Write-Host "$fileName" -ForegroundColor $FileNameColor -NoNewline
    Write-Host " downloaded and deleted successfully" -ForegroundColor $SuccessColor
}

function Build-And-Sign-Android {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SigningKey,

        [Parameter(Mandatory=$false)]
        [string]$BuildType = "debug",

        [Parameter(Mandatory=$false)]
        [string]$SignerPath = "D:\Programs\ApkSigner"
    )

    Write-Host "Starting Android build and sign process..." -ForegroundColor Green

    # Step 1: Build the Android project
    Write-Host "Building Android project..." -ForegroundColor Yellow

    if ($BuildType -eq "release") {
        $buildCommand = "./gradlew assembleRelease"
        $apkPath = "app/build/outputs/apk/release"
    } else {
        $buildCommand = "./gradlew assembleDebug"
        $apkPath = "app/build/outputs/apk/debug"
    }

    try {
        Invoke-Expression $buildCommand
        if ($LASTEXITCODE -ne 0) {
            throw "Build failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "Failed to build Android project: $_"
        return
    }

    # Step 2: Find the built APK file
    Write-Host "Looking for built APK..." -ForegroundColor Yellow

    if (!(Test-Path $apkPath)) {
        Write-Error "APK output directory not found: $apkPath"
        return
    }

    $apkFiles = Get-ChildItem -Path $apkPath -Filter "*.apk" | Sort-Object LastWriteTime -Descending
    if ($apkFiles.Count -eq 0) {
        Write-Error "No APK files found in $apkPath"
        return
    }

    $sourceApk = $apkFiles[0].FullName
    $apkFileName = $apkFiles[0].Name
    Write-Host "Found APK: $apkFileName" -ForegroundColor Green

    # Step 3: Copy APK to signer directory
    Write-Host "Copying APK to signer directory..." -ForegroundColor Yellow

    if (!(Test-Path $SignerPath)) {
        Write-Error "Signer directory not found: $SignerPath"
        return
    }

    $destinationApk = Join-Path $SignerPath $apkFileName
    try {
        Copy-Item $sourceApk $destinationApk -Force
        Write-Host "APK copied to: $destinationApk" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to copy APK: $_"
        return
    }

    # Step 4: Check if signing key exists
    $signingKeyPath = Join-Path $SignerPath "$SigningKey.bat"
    if (!(Test-Path $signingKeyPath)) {
        Write-Error "Signing key not found: $signingKeyPath"
        # Clean up copied APK
        Remove-Item $destinationApk -Force -ErrorAction SilentlyContinue
        return
    }

    # Step 5: Run the signing process
    Write-Host "Signing APK with key: $SigningKey" -ForegroundColor Yellow

    $currentLocation = Get-Location
    try {
        Set-Location $SignerPath

        # Execute the signing batch file
        & $signingKeyPath

        # Wait for the signing process to complete by checking for .idsig file
        $idsigFile = "$apkFileName.idsig"
        $timeout = 60 # seconds
        $elapsed = 0

        Write-Host "Waiting for signing to complete..." -ForegroundColor Yellow
        while (!(Test-Path $idsigFile) -and $elapsed -lt $timeout) {
            Start-Sleep -Seconds 2
            $elapsed += 2
        }

        if (!(Test-Path $idsigFile)) {
            throw "Signing process timed out or failed - .idsig file not found"
        }

        Write-Host "Signing completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed during signing process: $_"
        Set-Location $currentLocation
        Remove-Item $destinationApk -Force -ErrorAction SilentlyContinue
        return
    }
    finally {
        Set-Location $currentLocation
    }

    # Step 6: Remove the .idsig trash file
    Write-Host "Removing .idsig trash file..." -ForegroundColor Yellow
    try {
        $idsigPath = Join-Path $SignerPath "$apkFileName.idsig"
        if (Test-Path $idsigPath) {
            Remove-Item $idsigPath -Force
            Write-Host "Trash file removed: $apkFileName.idsig" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Failed to remove .idsig file: $_"
    }

    # Step 7: Install APK to Android device
    Write-Host "Installing APK to Android device..." -ForegroundColor Yellow

    try {
        # Check if adb is available
        $adbCheck = Get-Command adb -ErrorAction SilentlyContinue
        if (!$adbCheck) {
            throw "ADB not found in PATH. Please ensure Android SDK tools are installed and in PATH."
        }

        # Check if device is connected
        $devices = & adb devices
        if ($devices -match "device$") {
            & adb install -r $destinationApk
            if ($LASTEXITCODE -eq 0) {
                Write-Host "APK installed successfully" -ForegroundColor Green
            } else {
                throw "ADB install failed with exit code $LASTEXITCODE"
            }
        } else {
            throw "No Android device found. Please connect your device and enable USB debugging."
        }
    }
    catch {
        Write-Error "Failed to install APK: $_"
        # Don't return here, still clean up the APK file
    }

    # Step 8: Delete the APK file from signer directory
    Write-Host "Cleaning up APK file..." -ForegroundColor Yellow
    try {
        Remove-Item $destinationApk -Force
        Write-Host "APK file cleaned up" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to delete APK file: $_"
    }

    Write-Host "Android build and sign process completed!" -ForegroundColor Green
}

# Create an alias for easier usage
Set-Alias -Name silo -Value Build-And-Sign-Android

# Custom function for enhanced 'rm' command that handles multiple files
function Remove-MultipleItems {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter(ValueFromRemainingArguments=$true, Position=0)]
        [string[]]$Paths,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$Recurse
    )

    if ($Paths.Count -gt 0) {
        $params = @{
            Path = $Paths
        }

        if ($Force) { $params['Force'] = $true }
        if ($Recurse) { $params['Recurse'] = $true }

        # Use splatting to pass all parameters to Remove-Item
        if ($PSCmdlet.ShouldProcess("$($Paths -join ', ')", "Remove item(s)")) {
            Remove-Item @params
        }
    }
    else {
        Write-Warning "No items to remove"
    }
}

# Create an alias for the enhanced remove function
Set-Alias -Name rm -Value Remove-MultipleItems -Option AllScope -Force

# Function to open File Explorer in the current directory
function Open-Explorer {
    Start-Process explorer.exe .
}

# Aliases for Open-Explorer
Set-Alias -Name here -Value Open-Explorer
Set-Alias -Name explore -Value Open-Explorer

# Import PSReadLine and enable history-based predictions
Import-Module PSReadLine

# Use history for prediction; you can also try Plugin for community plugins later
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView   # shows a dropdown list

# Fuzzy-match tab completion
Set-PSReadLineOption -CompletionQueryItems 100       # more candidates
Set-PSReadLineOption -HistorySearchCursorMovesToEnd  # Emacs-style history search

# JJ autocomplete
Invoke-Expression (& { (jj util completion power-shell | Out-String) })

