param(
    [string]$ScriptPath = 'gui\map_drivesGUI.ps1',
    [string]$OutputPath = 'gui\MapMyDrivesGUI.exe'
)

# -----------------------------------------------------------------------------
# Build helper for GUI executable
#
# Purpose:
#  - Wraps the `ps2exe` module to create a standalone GUI executable from the
#    GUI PowerShell script. This helper removes any existing output and then
#    compiles the script into `gui\MapMyDrivesGUI.exe` by default.
#
# Usage:
#  - From repository root: `pwsh .\buildGUIExe.ps1`
#  - Optionally pass `-ScriptPath` / `-OutputPath` to override defaults.
# -----------------------------------------------------------------------------

Write-Host "Building executable from $ScriptPath to $OutputPath"

Import-Module ps2exe -ErrorAction Stop

if (Test-Path $OutputPath) {
    try {
        Remove-Item -LiteralPath $OutputPath -Force -ErrorAction Stop
        Write-Host "Removed existing $OutputPath"
    } catch {
        Write-Error "Unable to remove existing output file '$OutputPath'. Close the executable if it is running and try again."
        exit 1
    }
}

Invoke-ps2exe -inputFile $ScriptPath -outputFile $OutputPath -noConsole

Write-Host "Build complete: $OutputPath"