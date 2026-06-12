param(
	[switch]$AdminConnect
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# ============================================================================
# WPF Map Network Drives - PowerShell + XAML Hybrid
# 
# This version uses XAML for UI design (MainWindow.xaml, dialogs)
# and PowerShell for all business logic.
# ============================================================================

function Get-SelfPath {
	if ($PSCommandPath) { return $PSCommandPath }
	if ($MyInvocation.MyCommand.Path) { return $MyInvocation.MyCommand.Path }
	return [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
}

$ScriptPath = Get-SelfPath
$ScriptFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'NetworkDriveScript'
$ConfigFile = Join-Path $ScriptFolder 'drivelist.json'
$XamlFolder = Join-Path (Split-Path $ScriptPath) ''

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Ensure-ScriptFolder {
	if (-not (Test-Path $ScriptFolder)) {
		New-Item -ItemType Directory -Path $ScriptFolder | Out-Null
	}
}

function Write-DebugLog($message) {
	$logFile = Join-Path $ScriptFolder 'admin-connect-debug.txt'
	$timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
	"$timestamp $message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

function Read-DriveList {
	if (-not (Test-Path $ConfigFile)) {
		return @()
	}
	try {
		$json = Get-Content -Path $ConfigFile -Raw
		$drives = $json | ConvertFrom-Json
		return if ($null -eq $drives) { @() } else { $drives }
	} catch {
		[System.Windows.MessageBox]::Show("Unable to read saved drive list: $($_.Exception.Message)", 'Error', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
		return @()
	}
}

function Save-DriveList($drives) {
	$drives | ConvertTo-Json -Depth 4 | Set-Content -Path $ConfigFile -Encoding UTF8
}

function Normalize-DriveLetter([string]$rawInput) {
	if ($null -eq $rawInput) { return $null }
	$letter = $rawInput.Trim().TrimEnd(':')
	if ($letter.Length -ne 1) { return $null }
	if ($letter -notmatch '^[A-Za-z]$') { return $null }
	return $letter.ToUpper()
}

# ============================================================================
# LOAD XAML
# ============================================================================

function Load-XamlWindow($xamlPath) {
	if (-not (Test-Path $xamlPath)) {
		throw "XAML file not found: $xamlPath"
	}
	$xaml = Get-Content -Path $xamlPath -Raw
	$xamlReader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
	return [System.Windows.Markup.XamlReader]::Load($xamlReader)
}

# ============================================================================
# DRIVE MAPPING LOGIC (from original script)
# ============================================================================

function Map-SingleDrive($drive, [System.Management.Automation.PSCredential]$credential) {
	$letter = Normalize-DriveLetter $drive.Letter.TrimEnd(':')
	if (-not $letter) {
		return @{Success=$false; Message="Invalid drive letter: $($drive.Letter)"}
	}
	$driveName = "$($letter):"

	net use $driveName /delete /y 2>$null | Out-Null

	$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password))
	try {
		$arguments = @('use', $driveName, $drive.Path, "/user:$($credential.UserName)", $passwordPlain, '/persistent:no')
		$process = Start-Process -FilePath net.exe -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
		if ($process.ExitCode -eq 0) {
			return @{Success=$true; Message="Mapped $driveName -> $($drive.Path)"}
		}
		return @{Success=$false; Message="Failed to map $driveName -> $($drive.Path). Exit code $($process.ExitCode)."}
	} catch {
		return @{Success=$false; Message="Failed to map $driveName -> $($drive.Path): $($_.Exception.Message)"}
	} finally {
		$passwordPlain = $null
		[System.GC]::Collect()
	}
}

function Map-SingleDriveAsAdmin($drive, [System.Management.Automation.PSCredential]$credential) {
	$letter = Normalize-DriveLetter $drive.Letter.TrimEnd(':')
	if (-not $letter) {
		return @{Success=$false; Message="Invalid drive letter: $($drive.Letter)"}
	}
	$driveName = "$($letter):"
	$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password))
	try {
		try {
			Start-Process -FilePath net.exe -ArgumentList @('use', $driveName, '/delete', '/y') -Verb RunAs -Wait -WindowStyle Hidden -ErrorAction Stop | Out-Null
		} catch {
			# Ignore delete failures
		}
		$arguments = @('use', $driveName, $drive.Path, $passwordPlain, "/user:$($credential.UserName)", '/persistent:no')
		$process = Start-Process -FilePath net.exe -ArgumentList $arguments -Verb RunAs -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
		if ($process.ExitCode -eq 0) {
			return @{Success=$true; Message="Mapped $driveName -> $($drive.Path) as administrator."}
		}
		return @{Success=$false; Message="Failed to map $driveName -> $($drive.Path) as administrator. Exit code $($process.ExitCode)."}
	} catch [System.ComponentModel.Win32Exception] {
		if ($_.Exception.NativeErrorCode -eq 1223) {
			return @{Success=$false; Message='Admin elevation cancelled by user.'}
		}
		return @{Success=$false; Message="Failed: $($_.Exception.Message)"}
	} catch {
		return @{Success=$false; Message="Failed: $($_.Exception.Message)"}
	} finally {
		$passwordPlain = $null
		[System.GC]::Collect()
	}
}

function Connect-DriveList($drives, $isAdmin = $false) {
	$saved = Read-DriveList
	if ($saved -ne $null -and $saved.Count -gt 0) { $drives = $saved }

	if (-not $drives -or $drives.Count -eq 0) {
		return 'No drives configured to connect.'
	}

	$credential = Show-CredentialDialog
	if ($null -eq $credential) { return 'Credential entry cancelled.' }

	$results = New-Object System.Text.StringBuilder
	$successCount = 0
	$failedCount = 0

	foreach ($drive in $drives) {
		if ($isAdmin) {
			$out = Map-SingleDriveAsAdmin $drive $credential
		} else {
			$out = Map-SingleDrive $drive $credential
		}
		if ($out.Success) { $successCount++ } else { $failedCount++ }
		$results.AppendLine($out.Message) | Out-Null
	}

	$summary = "Connected $successCount of $($drives.Count) drive(s)."
	if ($failedCount -gt 0) { $summary += " $failedCount failed." }
	$results.Insert(0, "$summary`n") | Out-Null

	return $results.ToString()
}

# ============================================================================
# DIALOG WRAPPERS (using XAML)
# ============================================================================

function Show-CredentialDialog {
	try {
		$xamlPath = Join-Path (Split-Path $ScriptPath) 'CredentialWindow.xaml'
		$window = Load-XamlWindow $xamlPath

		$usernameBox = $window.FindName('UsernameTextBox')
		$passwordBox = $window.FindName('PasswordBox')
		$okButton = $window.FindName('OkButton')
		$cancelButton = $window.FindName('CancelButton')

		$dialogResult = $null

		$okButton.Add_Click({
			$dialogResult = @{
				Username = $usernameBox.Text
				Password = $passwordBox.Password
			}
			$window.DialogResult = $true
			$window.Close()
		})

		$cancelButton.Add_Click({
			$window.DialogResult = $false
			$window.Close()
		})

		$window.ShowDialog() | Out-Null

		if ($window.DialogResult -eq $true) {
			$securePassword = ConvertTo-SecureString $dialogResult.Password -AsPlainText -Force
			return New-Object System.Management.Automation.PSCredential($dialogResult.Username, $securePassword)
		}
		return $null
	} catch {
		Write-DebugLog "CredentialDialog error: $_"
		[System.Windows.MessageBox]::Show("Credential dialog error: $_", 'Error', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
		return $null
	}
}

function Show-AddEditDialog($drive = $null, $existingDrives = @()) {
	try {
		$xamlPath = Join-Path (Split-Path $ScriptPath) 'AddEditDriveWindow.xaml'
		$window = Load-XamlWindow $xamlPath

		$titleBlock = $window.FindName('WindowTitleBlock')
		$letterBox = $window.FindName('DriveLetterTextBox')
		$pathBox = $window.FindName('NetworkPathTextBox')
		$saveButton = $window.FindName('SaveButton')
		$cancelButton = $window.FindName('CancelButton')

		if ($drive) {
			$titleBlock.Text = "Edit Network Drive"
			$letterBox.Text = $drive.Letter.TrimEnd(':')
			$pathBox.Text = $drive.Path
		}

		$dialogResult = $null

		$saveButton.Add_Click({
			$letter = Normalize-DriveLetter $letterBox.Text
			if (-not $letter) {
				[System.Windows.MessageBox]::Show('Drive letter must be A-Z.', 'Invalid', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
				return
			}

			if (-not $drive -and ($existingDrives | Where-Object { $_.Letter -eq "$($letter):" })) {
				[System.Windows.MessageBox]::Show("Drive $letter`: already in use.", 'Duplicate', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
				return
			}

			if ([string]::IsNullOrWhiteSpace($pathBox.Text)) {
				[System.Windows.MessageBox]::Show('Path cannot be empty.', 'Invalid', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
				return
			}

			$dialogResult = @{
				Letter = "$($letter):"
				Path = $pathBox.Text.Trim()
			}
			$window.DialogResult = $true
			$window.Close()
		})

		$cancelButton.Add_Click({
			$window.DialogResult = $false
			$window.Close()
		})

		$window.ShowDialog() | Out-Null

		if ($window.DialogResult -eq $true) {
			return $dialogResult
		}
		return $null
	} catch {
		Write-DebugLog "AddEditDialog error: $_"
		[System.Windows.MessageBox]::Show("Dialog error: $_", 'Error', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
		return $null
	}
}

function Show-EditDrivesDialog($drives) {
	try {
		$xamlPath = Join-Path (Split-Path $ScriptPath) 'EditDrivesWindow.xaml'
		$window = Load-XamlWindow $xamlPath

		$driveListBox = $window.FindName('DriveListBox')
		$addButton = $window.FindName('AddButton')
		$editButton = $window.FindName('EditButton')
		$removeButton = $window.FindName('RemoveButton')
		$doneButton = $window.FindName('DoneButton')
		$cancelButton = $window.FindName('CancelButton')
		$infoLabel = $window.FindName('InfoLabel')

		$driveList = New-Object System.Collections.ArrayList
		if ($drives) { foreach ($d in $drives) { $driveList.Add($d) | Out-Null } }

		$updateListBox = {
			$driveListBox.Items.Clear()
			foreach ($d in $driveList) {
				$item = New-Object PSObject -Property @{ Letter = $d.Letter; Path = $d.Path }
				$driveListBox.Items.Add($item) | Out-Null
			}
		}

		&$updateListBox

		$addButton.Add_Click({
			$result = Show-AddEditDialog -existingDrives $driveList
			if ($result) {
				$driveList.Add($result) | Out-Null
				&$updateListBox
				$infoLabel.Text = "Drive added: $($result.Letter)"
			}
		})

		$editButton.Add_Click({
			if ($driveListBox.SelectedIndex -lt 0) {
				[System.Windows.MessageBox]::Show('Select a drive to edit.', 'No selection', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
				return
			}
			$selected = $driveList[$driveListBox.SelectedIndex]
			$result = Show-AddEditDialog -drive $selected -existingDrives $driveList
			if ($result) {
				$driveList[$driveListBox.SelectedIndex] = $result
				&$updateListBox
				$infoLabel.Text = "Drive updated: $($result.Letter)"
			}
		})

		$removeButton.Add_Click({
			if ($driveListBox.SelectedIndex -lt 0) {
				[System.Windows.MessageBox]::Show('Select a drive to remove.', 'No selection', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
				return
			}
			$selected = $driveList[$driveListBox.SelectedIndex]
			$confirm = [System.Windows.MessageBox]::Show("Remove $($selected.Letter)?", 'Confirm', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
			if ($confirm -eq 'Yes') {
				$driveList.RemoveAt($driveListBox.SelectedIndex)
				&$updateListBox
				$infoLabel.Text = 'Drive removed'
			}
		})

		$doneButton.Add_Click({
			$window.DialogResult = $true
			$window.Tag = $driveList
			$window.Close()
		})

		$cancelButton.Add_Click({
			$window.DialogResult = $false
			$window.Close()
		})

		$window.ShowDialog() | Out-Null

		if ($window.DialogResult -eq $true) {
			return $window.Tag
		}
		return $null
	} catch {
		Write-DebugLog "EditDrivesDialog error: $_"
		[System.Windows.MessageBox]::Show("Dialog error: $_", 'Error', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
		return $null
	}
}

# ============================================================================
# MAIN WINDOW
# ============================================================================

function Show-MainWindow {
	try {
		$xamlPath = Join-Path (Split-Path $ScriptPath) 'MainWindow.xaml'
		$mainWindow = Load-XamlWindow $xamlPath

		$driveListBox = $mainWindow.FindName('DriveListBox')
		$driveCountLabel = $mainWindow.FindName('DriveCountLabel')
		$connectButton = $mainWindow.FindName('ConnectButton')
		$connectAdminButton = $mainWindow.FindName('ConnectAdminButton')
		$editListButton = $mainWindow.FindName('EditListButton')
		$exitButton = $mainWindow.FindName('ExitButton')
		$statusBox = $mainWindow.FindName('StatusBox')

		$driveList = Read-DriveList
		if ($null -eq $driveList) { $driveList = @() }

		$updateMainUI = {
			$driveListBox.Items.Clear()
			foreach ($d in $driveList) {
				$item = New-Object PSObject -Property @{ Letter = $d.Letter; Path = $d.Path }
				$driveListBox.Items.Add($item) | Out-Null
			}
			$count = if ($driveList.Count -gt 0) { $driveList.Count } else { 0 }
			$driveCountLabel.Text = if ($count -eq 0) { "No drives configured yet" } else { "$count drive(s) configured" }
		}

		&$updateMainUI

		$connectButton.Add_Click({
			$result = Connect-DriveList $driveList $false
			[System.Windows.MessageBox]::Show($result, 'Connect Results', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
			$statusBox.Text = $result
		})

		$connectAdminButton.Add_Click({
			$result = Connect-DriveList $driveList $true
			[System.Windows.MessageBox]::Show($result, 'Admin Connect Results', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
			$statusBox.Text = $result
		})

		$editListButton.Add_Click({
			$driveList = Read-DriveList
			if ($driveList -eq $null) { $driveList = @() }
			$newList = Show-EditDrivesDialog $driveList
			if ($null -ne $newList) {
				Save-DriveList $newList
				$driveList = Read-DriveList
				if ($driveList -eq $null) { $driveList = @() }
				&$updateMainUI
				$statusBox.Text = 'Drive list updated.'
			}
		})

		$exitButton.Add_Click({
			$mainWindow.Close()
		})

		$mainWindow.ShowDialog() | Out-Null
	} catch {
		Write-DebugLog "MainWindow error: $_"
		[System.Windows.MessageBox]::Show("Application error: $_", 'Error', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
	}
}

# ============================================================================
# ENTRY POINT
# ============================================================================

Ensure-ScriptFolder

if ($AdminConnect) {
	Write-DebugLog 'AdminConnect branch entered.'
	try {
		$driveList = Read-DriveList
		if (-not $driveList -or $driveList.Count -eq 0) {
			[System.Windows.MessageBox]::Show('No drives configured.', 'Connect as Admin', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
			exit 0
		}

		$credential = Show-CredentialDialog
		if ($null -eq $credential) {
			Write-DebugLog 'Credential cancelled.'
			exit 0
		}

		Write-DebugLog 'Mapping drives with admin credentials.'
		$results = New-Object System.Text.StringBuilder
		$successCount = 0
		$failedCount = 0

		foreach ($drive in $driveList) {
			Write-DebugLog "Mapping $($drive.Letter) -> $($drive.Path)"
			$out = Map-SingleDriveAsAdmin $drive $credential
			if ($out.Success) { $successCount++ } else { $failedCount++ }
			$results.AppendLine($out.Message) | Out-Null
			Write-DebugLog $out.Message
		}

		$summary = "Connected $successCount of $($driveList.Count) drive(s) as administrator."
		if ($failedCount -gt 0) { $summary += " $failedCount failed." }
		$results.Insert(0, "$summary`n") | Out-Null

		[System.Windows.MessageBox]::Show($results.ToString(), 'Admin Connect Results', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
		exit 0
	} catch {
		Write-DebugLog "AdminConnect error: $_"
		[System.Windows.MessageBox]::Show("Error: $_", 'Error', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
		exit 1
	}
}

# Normal mode: Show main window
Show-MainWindow
