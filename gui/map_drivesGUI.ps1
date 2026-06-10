param(
    [switch]$AdminConnect
)

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

function Get-SelfPath {
    if ($PSCommandPath) { return $PSCommandPath }
    if ($MyInvocation.MyCommand.Path) { return $MyInvocation.MyCommand.Path }
    return [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
}

$ScriptPath = Get-SelfPath
$ScriptFolder = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'NetworkDriveScript'
$ConfigFile = Join-Path $ScriptFolder 'drivelist.json'

function Ensure-ScriptFolder {
    if (-not (Test-Path $ScriptFolder)) {
        New-Item -ItemType Directory -Path $ScriptFolder | Out-Null
    }
}

function Read-DriveList {
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
        [System.Windows.Forms.MessageBox]::Show("Unable to read saved drive list: $($_.Exception.Message)", 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return @()
    }
}

function Save-DriveList($drives) {
    $drives | ConvertTo-Json -Depth 4 | Set-Content -Path $ConfigFile -Encoding UTF8
}

function Write-DebugLog($message) {
    $logFile = Join-Path $ScriptFolder 'admin-connect-debug.txt'
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    "$timestamp $message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

function Format-DriveEntry($drive) {
    return "$($drive.Letter) $($drive.Path)"
}

function Update-DriveListBox($listBox, $drives) {
    $listBox.Items.Clear()
    foreach ($drive in $drives) {
        $listBox.Items.Add((Format-DriveEntry $drive)) | Out-Null
    }
}

function Normalize-DriveLetter([string]$rawInput) {
    if ($null -eq $rawInput) { return $null }
    $letter = $rawInput.Trim().TrimEnd(':')
    if ($letter.Length -ne 1) { return $null }
    if ($letter -notmatch '^[A-Za-z]$') { return $null }
    return $letter.ToUpper()
}

function Show-InputDialog($title, $label1, $default1, $label2, $default2, $usePlaceholder = $true) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(420,260)
    $form.StartPosition = 'CenterParent'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $lbl1 = New-Object System.Windows.Forms.Label
    $lbl1.Text = $label1
    $lbl1.AutoSize = $true
    $lbl1.Location = New-Object System.Drawing.Point(12,15)

    $txt1 = New-Object System.Windows.Forms.TextBox
    $txt1.Size = New-Object System.Drawing.Size(360,22)
    $txt1.Location = New-Object System.Drawing.Point(12,35)
    $txt1.Text = [string]$default1
    $txt1.ForeColor = [System.Drawing.Color]::Black
    if ($usePlaceholder) {
        $txt1.Add_GotFocus({ if ($txt1.Text -eq $default1) { $txt1.Text = '' } })
        $txt1.Add_LostFocus({ if ([string]::IsNullOrWhiteSpace($txt1.Text)) { $txt1.Text = $default1 } })
    } else {
        $txt1.Text = [string]$default1
        $txt1.ForeColor = [System.Drawing.Color]::Black
    }
    # helper description below the textbox
    $lbl1Desc = New-Object System.Windows.Forms.Label
    $lbl1Desc.Text = 'Enter a single drive letter (A-Z). Do not include a colon.'
    $lbl1Desc.AutoSize = $true
    $lbl1Desc.ForeColor = [System.Drawing.Color]::Gray
    $lbl1Desc.Location = New-Object System.Drawing.Point(12,60)
    $lbl1Desc.Font = New-Object System.Drawing.Font($lbl1Desc.Font.FontFamily,8)

    $lbl2 = New-Object System.Windows.Forms.Label
    $lbl2.Text = $label2
    $lbl2.AutoSize = $true
    $lbl2.Location = New-Object System.Drawing.Point(12,85)

    $txt2 = New-Object System.Windows.Forms.TextBox
    $txt2.Size = New-Object System.Drawing.Size(360,22)
    $txt2.Location = New-Object System.Drawing.Point(12,105)
    $txt2.Text = [string]$default2
    $txt2.ForeColor = [System.Drawing.Color]::Black
    if ($usePlaceholder) {
        $txt2.Add_GotFocus({ if ($txt2.Text -eq $default2) { $txt2.Text = '' } })
        $txt2.Add_LostFocus({ if ([string]::IsNullOrWhiteSpace($txt2.Text)) { $txt2.Text = $default2 } })
    } else {
        $txt2.Text = [string]$default2
        $txt2.ForeColor = [System.Drawing.Color]::Black
    }
    # helper description below the path textbox
    $lbl2Desc = New-Object System.Windows.Forms.Label
    $lbl2Desc.Text = 'Enter the UNC path to the share, e.g. \\server\\share\\folder'
    $lbl2Desc.AutoSize = $true
    $lbl2Desc.ForeColor = [System.Drawing.Color]::Gray
    $lbl2Desc.Location = New-Object System.Drawing.Point(12,130)
    $lbl2Desc.Font = New-Object System.Drawing.Font($lbl2Desc.Font.FontFamily,8)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = 'OK'
    $btnOk.Size = New-Object System.Drawing.Size(90,28)
    $btnOk.Location = New-Object System.Drawing.Point(200,165)
    $btnOk.Add_Click({ $form.Tag = 'OK'; $form.Close() })

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.Size = New-Object System.Drawing.Size(90,28)
    $btnCancel.Location = New-Object System.Drawing.Point(302,165)
    $btnCancel.Add_Click({ $form.Tag = 'Cancel'; $form.Close() })

    $form.Controls.AddRange(@($lbl1, $txt1, $lbl1Desc, $lbl2, $txt2, $lbl2Desc, $btnOk, $btnCancel))
    $form.AcceptButton = $btnOk
    $form.CancelButton = $btnCancel
    if (-not $usePlaceholder) {
        $txt1.SelectAll()
        $txt1.Focus()
    }
    $form.ShowDialog() | Out-Null

    return @{Cancelled = ($form.Tag -ne 'OK'); Value1 = $txt1.Text.Trim(); Value2 = $txt2.Text.Trim()}
}

function Show-CredentialDialog() {
    Write-DebugLog 'Show-CredentialDialog entered.'
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Enter network credentials'
    $form.Size = New-Object System.Drawing.Size(420,220)
    $form.StartPosition = 'CenterParent'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.TopMost = $true

    $lblUser = New-Object System.Windows.Forms.Label
    $lblUser.Text = 'Username (e.g. DOMAIN\\user):'
    $lblUser.AutoSize = $true
    $lblUser.Location = New-Object System.Drawing.Point(12,15)

    $txtUser = New-Object System.Windows.Forms.TextBox
    $txtUser.Size = New-Object System.Drawing.Size(360,22)
    $txtUser.Location = New-Object System.Drawing.Point(12,35)

    $lblPassword = New-Object System.Windows.Forms.Label
    $lblPassword.Text = 'Password:'
    $lblPassword.AutoSize = $true
    $lblPassword.Location = New-Object System.Drawing.Point(12,70)

    $txtPassword = New-Object System.Windows.Forms.TextBox
    $txtPassword.Size = New-Object System.Drawing.Size(360,22)
    $txtPassword.Location = New-Object System.Drawing.Point(12,90)
    $txtPassword.UseSystemPasswordChar = $true

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = 'OK'
    $btnOk.Size = New-Object System.Drawing.Size(90,28)
    $btnOk.Location = New-Object System.Drawing.Point(200,130)
    $btnOk.Add_Click({ $form.Tag = 'OK'; $form.Close() })

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.Size = New-Object System.Drawing.Size(90,28)
    $btnCancel.Location = New-Object System.Drawing.Point(302,130)
    $btnCancel.Add_Click({ $form.Tag = 'Cancel'; $form.Close() })

    $form.Controls.AddRange(@($lblUser, $txtUser, $lblPassword, $txtPassword, $btnOk, $btnCancel))
    $form.AcceptButton = $btnOk
    $form.CancelButton = $btnCancel
    $form.ShowDialog() | Out-Null

    if ($form.Tag -ne 'OK') { return $null }

    $securePassword = ConvertTo-SecureString $txtPassword.Text -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential($txtUser.Text.Trim(), $securePassword)
}

function Show-EditDialog($drives) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Edit saved drives'
    $form.Size = New-Object System.Drawing.Size(540,360)
    $form.StartPosition = 'CenterParent'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # use a mutable collection so event handlers modify the same object
    $driveList = New-Object System.Collections.ArrayList
    if ($drives) { foreach ($d in $drives) { $driveList.Add($d) | Out-Null } }

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(12,12)
    $listBox.Size = New-Object System.Drawing.Size(500,240)
    $listBox.HorizontalScrollbar = $true

    $btnAdd = New-Object System.Windows.Forms.Button
    $btnAdd.Text = 'Add drive'
    $btnAdd.Size = New-Object System.Drawing.Size(96,32)
    $btnAdd.Location = New-Object System.Drawing.Point(12,260)

    $btnRemove = New-Object System.Windows.Forms.Button
    $btnRemove.Text = 'Remove selected'
    $btnRemove.Size = New-Object System.Drawing.Size(96,32)
    $btnRemove.Location = New-Object System.Drawing.Point(116,260)

    $btnEditSelected = New-Object System.Windows.Forms.Button
    $btnEditSelected.Text = 'Edit selected'
    $btnEditSelected.Size = New-Object System.Drawing.Size(96,32)
    $btnEditSelected.Location = New-Object System.Drawing.Point(220,260)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.Size = New-Object System.Drawing.Size(96,32)
    $btnCancel.Location = New-Object System.Drawing.Point(324,260)

    $btnDone = New-Object System.Windows.Forms.Button
    $btnDone.Text = 'Done'
    $btnDone.Size = New-Object System.Drawing.Size(96,32)
    $btnDone.Location = New-Object System.Drawing.Point(428,260)

    $btnAdd.Add_Click({
        $result = Show-InputDialog('Add new drive','Drive letter (single letter, e.g. Z)','Z', 'Network path (UNC path, e.g. \\server\\share)','\\server\\share')
        if ($result.Cancelled) { return }
        $letter = Normalize-DriveLetter $result.Value1
        if (-not $letter) {
            [System.Windows.Forms.MessageBox]::Show('Drive letter must be a single letter A-Z.','Invalid drive letter',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if ($driveList | Where-Object { $_.Letter -eq "$($letter):" }) {
            [System.Windows.Forms.MessageBox]::Show("Drive letter $($letter): is already in use.",'Duplicate drive',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if ([string]::IsNullOrWhiteSpace($result.Value2)) {
            [System.Windows.Forms.MessageBox]::Show('Path cannot be empty.','Invalid path',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        $newItem = [pscustomobject]@{ Letter = "$($letter):"; Path = $result.Value2 }
        $driveList.Add($newItem) | Out-Null
        Update-DriveListBox $listBox $driveList
        try { $listBox.SelectedIndex = $listBox.Items.Count - 1 } catch { }
    })

    $btnRemove.Add_Click({
        if ($listBox.SelectedIndex -lt 0) {
            [System.Windows.Forms.MessageBox]::Show('Select a drive to remove.','No selection',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            return
        }
        $selIndex = $listBox.SelectedIndex
        $driveList.RemoveAt($selIndex) | Out-Null
        Update-DriveListBox $listBox $driveList
    })

    $btnEditSelected.Add_Click({
        if ($listBox.SelectedIndex -lt 0) {
            [System.Windows.Forms.MessageBox]::Show('Select a drive to edit.','No selection',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            return
        }

        $selIndex = $listBox.SelectedIndex
        $selectedDrive = $driveList[$selIndex]
        $defaultLetter = [string]($selectedDrive.Letter.TrimEnd(':').ToUpper())
        $defaultPath = [string]$selectedDrive.Path
        $result = Show-InputDialog('Edit selected drive','Drive letter (single letter, e.g. Z)',$defaultLetter, 'Network path (UNC path, e.g. \\server\\share)',$defaultPath, $false)
        if ($result.Cancelled) { return }

        $letter = Normalize-DriveLetter $result.Value1
        if (-not $letter) {
            [System.Windows.Forms.MessageBox]::Show('Drive letter must be a single letter A-Z.','Invalid drive letter',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if ($driveList | Where-Object { $_.Letter -eq "$($letter):" -and $_ -ne $selectedDrive }) {
            [System.Windows.Forms.MessageBox]::Show("Drive letter $($letter): is already in use.",'Duplicate drive',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        if ([string]::IsNullOrWhiteSpace($result.Value2)) {
            [System.Windows.Forms.MessageBox]::Show('Path cannot be empty.','Invalid path',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }

        $driveList[$selIndex] = [pscustomobject]@{ Letter = "$($letter):"; Path = $result.Value2 }
        Update-DriveListBox $listBox $driveList
        try { $listBox.SelectedIndex = $selIndex } catch { }
    })

    $btnDone.Add_Click({ $form.Tag = 'OK'; $form.Close() })
    $btnCancel.Add_Click({ $form.Tag = 'Cancel'; $form.Close() })

    $form.Controls.AddRange(@($listBox, $btnAdd, $btnRemove, $btnEditSelected, $btnCancel, $btnDone))
    Update-DriveListBox $listBox $driveList
    $form.ShowDialog() | Out-Null
    if ($form.Tag -ne 'OK') { return $null }
    return $driveList.ToArray()
}

function Map-SingleDrive($drive, [System.Management.Automation.PSCredential]$credential) {
    $letter = Normalize-DriveLetter $drive.Letter.TrimEnd(':')
    if (-not $letter) {
        return @{Success=$false; Message="Invalid drive letter: $($drive.Letter)"}
    }
    $driveName = "$($letter):"
    net use $driveName /delete /y >$null 2>&1
    $secure = $credential.Password
    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    try {
        $arguments = @('use', $driveName, $drive.Path, "/user:$($credential.UserName)", $passwordPlain, '/persistent:no')
        $process = Start-Process -FilePath net.exe -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        if ($process.ExitCode -eq 0) {
            return @{Success=$true; Message="Mapped $driveName -> $($drive.Path)"}
        }
        return @{Success=$false; Message="Failed to map $driveName -> $($drive.Path). Net use exit code $($process.ExitCode)."}
    } catch {
        return @{Success=$false; Message="Failed to map $driveName -> $($drive.Path): $($_.Exception.Message)"}
    } finally {
        $passwordPlain = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Map-SingleDriveAsAdmin($drive, [System.Management.Automation.PSCredential]$credential) {
    $letter = Normalize-DriveLetter $drive.Letter.TrimEnd(':')
    if (-not $letter) {
        return @{Success=$false; Message="Invalid drive letter: $($drive.Letter)"}
    }
    $driveName = "$($letter):"
    $secure = $credential.Password
    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    try {
        try {
            Start-Process -FilePath net.exe -ArgumentList @('use', $driveName, '/delete', '/y') -Verb RunAs -Wait -WindowStyle Hidden -ErrorAction Stop | Out-Null
        } catch {
            # Ignore delete failures; the drive may not exist yet.
        }

        $arguments = @('use', $driveName, $drive.Path, $passwordPlain, "/user:$($credential.UserName)", '/persistent:no')
        $process = Start-Process -FilePath net.exe -ArgumentList $arguments -Verb RunAs -Wait -PassThru -WindowStyle Hidden -ErrorAction Stop
        if ($process.ExitCode -eq 0) {
            return @{Success=$true; Message="Mapped $driveName -> $($drive.Path) as administrator."}
        }
        return @{Success=$false; Message="Failed to map $driveName -> $($drive.Path) as administrator. Net use exit code $($process.ExitCode)."}
    } catch [System.ComponentModel.Win32Exception] {
        if ($_.Exception.NativeErrorCode -eq 1223) {
            return @{Success=$false; Message='Admin elevation cancelled by user.'}
        }
        return @{Success=$false; Message="Failed to map $driveName -> $($drive.Path) as administrator: $($_.Exception.Message)"}
    } catch {
        return @{Success=$false; Message="Failed to map $driveName -> $($drive.Path) as administrator: $($_.Exception.Message)"}
    } finally {
        $passwordPlain = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Connect-DriveList($drives) {
    # Always read the persisted list to ensure we use the most recent edits
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
        $out = Map-SingleDrive $drive $credential
        if ($out.Success) { $successCount++ } else { $failedCount++ }
        $results.AppendLine($out.Message) | Out-Null
    }

    $summary = "Connected $successCount of $($drives.Count) drive(s)."
    if ($failedCount -gt 0) {
        $summary += " $failedCount failed."
    }

    $results.Insert(0, "$summary`n") | Out-Null
    return $results.ToString()
}

function Connect-DriveListAsAdmin($drives) {
    # Always read the persisted list to ensure we use the most recent edits
    $saved = Read-DriveList
    if ($saved -ne $null -and $saved.Count -gt 0) { $drives = $saved }

    if (-not $drives -or $drives.Count -eq 0) {
        return 'No drives configured to connect.'
    }

    $isExe = ([System.IO.Path]::GetExtension($ScriptPath)).ToLower() -eq '.exe'
    if ($isExe) {
        $processFile = $ScriptPath
        $arguments = @('-AdminConnect')
    } else {
        $processFile = 'PowerShell.exe'
        $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath, '-AdminConnect')
    }

    Write-DebugLog "Launching elevated process: $processFile $($arguments -join ' ')"
    try {
        Start-Process -FilePath $processFile -ArgumentList $arguments -Verb RunAs -Wait -WindowStyle Normal -ErrorAction Stop | Out-Null
        Write-DebugLog 'Elevated process returned.'
        return 'Elevated connection attempt completed.'
    } catch [System.ComponentModel.Win32Exception] {
        if ($_.Exception.NativeErrorCode -eq 1223) {
            return 'Admin elevation cancelled by user.'
        }
        return "Failed to run elevated connect: $($_.Exception.Message)"
    } catch {
        return "Failed to run elevated connect: $($_.Exception.Message)"
    }
}

Ensure-ScriptFolder
if ($AdminConnect) {
    Write-DebugLog 'AdminConnect branch entered.'
    try {
        $driveList = Read-DriveList
        if (-not $driveList -or $driveList.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show('No drives configured to connect.','Connect as admin',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            exit 0
        }

        $credential = Show-CredentialDialog
        if ($null -eq $credential) {
            Write-DebugLog 'Show-CredentialDialog returned null.'
            exit 0
        }

        Write-DebugLog 'Credential provided, mapping drives.'
        $results = New-Object System.Text.StringBuilder
        $successCount = 0
        $failedCount = 0

        foreach ($drive in $driveList) {
            Write-DebugLog "Mapping drive $($drive.Letter) -> $($drive.Path)"
            $out = Map-SingleDrive $drive $credential
            if ($out.Success) { $successCount++ } else { $failedCount++ }
            $results.AppendLine($out.Message) | Out-Null
            Write-DebugLog $out.Message
        }

        $summary = "Connected $successCount of $($driveList.Count) drive(s) as administrator."
        if ($failedCount -gt 0) {
            $summary += " $failedCount failed."
        }
        $results.Insert(0, "$summary`n") | Out-Null

        [System.Windows.Forms.MessageBox]::Show($results.ToString(), 'Admin connect results', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        exit 0
    } catch {
        Write-DebugLog "AdminConnect branch exception: $($_.Exception.Message)"
        Write-DebugLog $_.Exception.StackTrace
        [System.Windows.Forms.MessageBox]::Show("Admin connect failed: $($_.Exception.Message)", 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        exit 1
    }
}

$driveList = Read-DriveList
if ($driveList -eq $null) { $driveList = @() }

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Map My Drives'
$form.Size = New-Object System.Drawing.Size(580,440)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = 'Saved network drive list:'
$lbl.AutoSize = $true
$lbl.Location = New-Object System.Drawing.Point(12,15)

$listBoxMain = New-Object System.Windows.Forms.ListBox
$listBoxMain.Location = New-Object System.Drawing.Point(12,35)
$listBoxMain.Size = New-Object System.Drawing.Size(540,240)
$listBoxMain.HorizontalScrollbar = $true

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = 'Connect'
$btnConnect.Size = New-Object System.Drawing.Size(120,36)
$btnConnect.Location = New-Object System.Drawing.Point(12,290)

$btnConnectAdmin = New-Object System.Windows.Forms.Button
$btnConnectAdmin.Text = 'Connect as admin'
$btnConnectAdmin.Size = New-Object System.Drawing.Size(120,36)
$btnConnectAdmin.Location = New-Object System.Drawing.Point(146,290)

$btnEdit = New-Object System.Windows.Forms.Button
$btnEdit.Text = 'Edit list'
$btnEdit.Size = New-Object System.Drawing.Size(120,36)
$btnEdit.Location = New-Object System.Drawing.Point(280,290)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = 'Exit'
$btnExit.Size = New-Object System.Drawing.Size(120,36)
$btnExit.Location = New-Object System.Drawing.Point(414,290)

$statusBox = New-Object System.Windows.Forms.TextBox
$statusBox.Location = New-Object System.Drawing.Point(12,340)
$statusBox.Size = New-Object System.Drawing.Size(540,50)
$statusBox.Multiline = $true
$statusBox.ReadOnly = $true
$statusBox.ScrollBars = 'Vertical'
$statusBox.Text = 'Choose an action to begin.'

$btnConnect.Add_Click({
    $result = Connect-DriveList $driveList
    if ($result) {
        [System.Windows.Forms.MessageBox]::Show($result, 'Connect results', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        $statusBox.Text = $result
    } else {
        $statusBox.Text = 'No result from connect.'
    }
    Update-DriveListBox $listBoxMain $driveList
})

$btnConnectAdmin.Add_Click({
    $result = Connect-DriveListAsAdmin $driveList
    if ($result) {
        [System.Windows.Forms.MessageBox]::Show($result, 'Connect as admin results', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        $statusBox.Text = $result
    } else {
        $statusBox.Text = 'No result from admin connect.'
    }
    Update-DriveListBox $listBoxMain $driveList
})

$btnEdit.Add_Click({
    $driveList = Read-DriveList
    if ($driveList -eq $null) { $driveList = @() }
    Update-DriveListBox $listBoxMain $driveList

    $newList = Show-EditDialog $driveList
    if ($null -ne $newList) {
        Save-DriveList $newList
        $driveList = Read-DriveList
        if ($driveList -eq $null) { $driveList = @() }
        Update-DriveListBox $listBoxMain $driveList
        $statusBox.Text = 'Drive list updated.'
    }
})

$btnExit.Add_Click({ $form.Close() })

$form.Controls.AddRange(@($lbl, $listBoxMain, $btnConnect, $btnConnectAdmin, $btnEdit, $btnExit, $statusBox))
Update-DriveListBox $listBoxMain $driveList

[System.Windows.Forms.Application]::Run($form)
