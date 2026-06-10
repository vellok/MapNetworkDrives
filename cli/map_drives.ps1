# -----------------------------------------------------------------------------
# CLI Drive Mapper
#
# Purpose:
#  - Command-line interface for managing a list of network drive mappings.
#  - Stores only drive letters and UNC paths in a JSON config under
#    the user's Documents folder (NetworkDriveScript/drivelist.json).
#  - Prompts for network credentials each time; credentials are NOT persisted.
#
# Usage:
#  - Run in PowerShell: `pwsh map_drives.ps1` or use the launcher `MapMyDrives.cmd`.
#  - Add / remove / edit saved drives and use the Connect action to map them.
#
# Notes:
#  - This file contains only the CLI (text) UI logic. Shared mapping helpers
#    are kept inline for simplicity; consider extracting to a module if needed.
# -----------------------------------------------------------------------------

$ScriptFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'NetworkDriveScript'
$ConfigFile = Join-Path $ScriptFolder "drivelist.json"

function Ensure-ScriptFolder {
    # Ensure the script storage folder exists (creates Documents\NetworkDriveScript)
    if (-not (Test-Path $ScriptFolder)) {
        New-Item -ItemType Directory -Path $ScriptFolder | Out-Null
    }
}

function Read-DriveList {
    # Read the saved drive list JSON and return an array of drive objects
    if (-not (Test-Path $ConfigFile)) {
        return @()
    }

    try {
        $json = Get-Content -Path $ConfigFile -Raw
        $drives = $json | ConvertFrom-Json
        if ($null -eq $drives) {
            return @()
        }
        return $drives
    } catch {
        Write-Warning "Unable to read saved drive list: $($_.Exception.Message)"
        return @()
    }
}

function Save-DriveList($drives) {
    # Save the drive list array as JSON to the config file
    $drives | ConvertTo-Json -Depth 4 | Out-File -FilePath $ConfigFile -Encoding UTF8
}

function Show-DriveList($drives) {
    # Print a numbered list of saved drives to the console
    if ($drives.Count -eq 0) {
        Write-Host "No saved drives found." -ForegroundColor Yellow
        return
    }

    Write-Host "Saved network drive list:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $drives.Count; $i++) {
        $entry = $drives[$i]
        Write-Host "[$($i + 1)] $($entry.Letter) $($entry.Path)"
    }
}

function Read-Choice([string]$prompt, [string[]]$options) {
    # Display a simple numbered choice prompt and return the selected option
    while ($true) {
        Write-Host "`n$prompt"
        for ($i = 0; $i -lt $options.Length; $i++) {
            Write-Host "  [$($i + 1)] $($options[$i])"
        }

        $selection = Read-Host 'Choose a number'
        $index = 0
        if ([int]::TryParse($selection, [ref]$index) -and $index -ge 1 -and $index -le $options.Length) {
            return $options[$index - 1]
        }

        Write-Host "Invalid selection. Please enter a number between 1 and $($options.Length)." -ForegroundColor Yellow
    }
}

function Read-YesNo([string]$prompt, [string]$default = 'Y') {
    # Prompt for a yes/no answer (returns $true/$false)
    $default = $default.ToUpper()
    while ($true) {
        $response = Read-Host "$prompt [Y/N] (default: $default)"
        if ([string]::IsNullOrWhiteSpace($response)) {
            $response = $default
        }
        switch ($response.Trim().ToUpper()) {
            'Y' { return $true }
            'N' { return $false }
            default { Write-Host 'Please answer Y or N.' -ForegroundColor Yellow }
        }
    }
}

function Normalize-DriveLetter([string]$rawInput) {
    # Normalize user input into an uppercase single-letter drive (no colon)
    if ($null -eq $rawInput) { return $null }
    $letter = $rawInput.Trim().TrimEnd(':')
    if ($letter.Length -ne 1) { return $null }
    if ($letter -notmatch '^[A-Za-z]$') { return $null }
    return $letter.ToUpper()
}

function Prompt-DriveLetter($existingLetters) {
    # Prompt user for a drive letter and validate it isn't already used
    while ($true) {
        $raw = Read-Host 'Enter drive letter (for example Z)'
        $letter = Normalize-DriveLetter $raw
        if (-not $letter) {
            Write-Host 'Drive letter must be a single letter A-Z.' -ForegroundColor Yellow
            continue
        }
        if ($existingLetters -contains ($letter + ':')) {
            Write-Host ("Drive letter " + $letter + ": is already defined. Choose a different letter.") -ForegroundColor Yellow
            continue
        }
        return ($letter + ':')
    }
}

function Prompt-DrivePath {
    # Prompt user for the UNC path and validate non-empty input
    while ($true) {
        $path = Read-Host 'Enter network path (UNC path, e.g. \\server\share)'
        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-Host 'Path cannot be empty.' -ForegroundColor Yellow
            continue
        }
        return $path.Trim()
    }
}

function Add-Drive($drives) {
    # Create a new drive entry (Letter + Path) and append to the list
    $drives = @($drives)
    $existingLetters = $drives | ForEach-Object { $_.Letter }
    $letter = Prompt-DriveLetter $existingLetters
    $path = Prompt-DrivePath
    $drives += [pscustomobject]@{
        Letter = $letter
        Path   = $path
    }
    Write-Host "Added drive $letter -> $path" -ForegroundColor Green
    return $drives
}

function Remove-Drive($drives) {
    # Remove a selected drive from the list by its displayed index
    if ($drives.Count -eq 0) {
        Write-Host 'No drives to remove.' -ForegroundColor Yellow
        return $drives
    }

    Show-DriveList $drives
    while ($true) {
        $selection = Read-Host 'Enter the number of the drive to remove'
        $index = 0
        if ([int]::TryParse($selection, [ref]$index) -and $index -ge 1 -and $index -le $drives.Count) {
            $removed = $drives[$index - 1]
            $drives = $drives | Where-Object { $_ -ne $removed }
            Write-Host "Removed drive $($removed.Letter) -> $($removed.Path)" -ForegroundColor Green
            return $drives
        }
        Write-Host "Please enter a valid number between 1 and $($drives.Count)." -ForegroundColor Yellow
    }
}

function Edit-DriveList($drives) {
    # Loop to allow adding or removing drives until user finishes
    while ($true) {
        Write-Host ''
        Show-DriveList $drives
        $action = Read-Choice 'Would you like to add or remove drives?' @('Add', 'Remove', 'Done')

        switch ($action) {
            'Add' {
                $drives = Add-Drive $drives
                if (-not (Read-YesNo 'Add another drive?')) {
                    continue
                }
            }
            'Remove' {
                $drives = Remove-Drive $drives
                if (-not (Read-YesNo 'Remove another drive?')) {
                    continue
                }
            }
            'Done' {
                return $drives
            }
        }
    }
}

function Get-NetworkCredential {
    # Prompt the user for network credentials and return a PSCredential
    while ($true) {
        Write-Host 'Enter network credentials for drive mapping' -ForegroundColor Cyan
        $username = Read-Host 'Username (e.g. DOMAIN\user)'
        if ([string]::IsNullOrWhiteSpace($username)) {
            Write-Host 'Username cannot be empty.' -ForegroundColor Yellow
            continue
        }

        $password = Read-Host 'Password' -AsSecureString
        if ($null -eq $password) {
            Write-Host 'Password cannot be empty.' -ForegroundColor Yellow
            continue
        }

        return New-Object System.Management.Automation.PSCredential($username, $password)
    }
}

function Map-SingleDrive($drive, [System.Management.Automation.PSCredential]$credential) {
    # Map a single drive using `net use` with supplied credentials (non-elevated)
    $letter = Normalize-DriveLetter $drive.Letter.TrimEnd(':')
    if (-not $letter) {
        Write-Warning "Skipping invalid drive letter: $($drive.Letter)"
        return
    }

    $driveName = $letter + ':'
    net use $driveName /delete /y >$null 2>&1
    Remove-PSDrive -Name $letter -ErrorAction SilentlyContinue -Force | Out-Null

    # Convert SecureString to plain text for passing to net.exe (short-lived)
    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
    )

    try {
        # Call `net use` to map the network drive. We pass the username and password
        # as separate arguments so net.exe can authenticate to the remote share.
        $arguments = @('use', $driveName, $drive.Path, "/user:$($credential.UserName)", $passwordPlain, '/persistent:no')
        $process = Start-Process -FilePath net.exe -ArgumentList $arguments -Wait -NoNewWindow -PassThru -ErrorAction Stop

        if ($process.ExitCode -eq 0) {
            Write-Host "Mapped $driveName -> $($drive.Path)" -ForegroundColor Green
        } else {
            Write-Warning "Failed to map $driveName -> $($drive.Path). Net use returned exit code $($process.ExitCode)."
        }
    } catch {
        Write-Warning "Failed to map $driveName -> $($drive.Path): $($_.Exception.Message)"
    } finally {
        # Clear the plaintext password variable as soon as possible
        $passwordPlain = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Connect-DriveList($drives) {
    if ($drives.Count -eq 0) {
        Write-Host 'No drives configured to connect.' -ForegroundColor Yellow
        return
    }

    $credential = Get-NetworkCredential
    foreach ($drive in $drives) {
        Map-SingleDrive $drive $credential
    }
}

# --------------------- Main script ---------------------
Ensure-ScriptFolder
$driveList = Read-DriveList

if ($driveList.Count -eq 0) {
    Write-Host 'No saved drive list was found. Let us create it now.' -ForegroundColor Cyan
    $driveList = Add-Drive @()
    while (Read-YesNo 'Add another drive?') {
        $driveList = Add-Drive $driveList
    }
    Save-DriveList $driveList
}

$exitRequested = $false
while (-not $exitRequested) {
    Write-Host ''
    Show-DriveList $driveList
    $mainAction = Read-Choice 'Choose an action' @('Connect', 'Edit list', 'Exit')

    switch ($mainAction) {
        'Connect' {
            Connect-DriveList $driveList
            if (-not (Read-YesNo 'Return to the menu?')) {
                $exitRequested = $true
            }
        }
        'Edit list' {
            $driveList = Edit-DriveList $driveList
            Save-DriveList $driveList
            Write-Host 'Drive list updated.' -ForegroundColor Cyan
        }
        'Exit' {
            $exitRequested = $true
        }
    }
}

Write-Host 'Done.' -ForegroundColor Green
