# WPF Version - Architecture Overview

## 🏗️ Project Structure

```
gui/
├── MainWindow.xaml                 ← Main app UI
├── CredentialWindow.xaml           ← Credential dialog UI
├── AddEditDriveWindow.xaml         ← Add/Edit drive dialog UI
├── EditDrivesWindow.xaml           ← Edit drives list dialog UI
│
├── map_drivesGUI_WPF.ps1           ← Main app (PowerShell + WPF)
├── map_drivesGUI.ps1               ← Old WinForms version (backup)
│
├── QUICK_START.md                  ← This file (TL;DR)
├── WPF_ENHANCEMENT_GUIDE.md        ← Full enhancement guide
│
└── MapMyDrivesGUI.exe              ← Compiled EXE (rebuilt with buildGUIExe.ps1)
```

## 🔄 How It Works

```
User Runs: pwsh map_drivesGUI_WPF.ps1
	↓
PowerShell Loads Assemblies (PresentationFramework, etc.)
	↓
Script Reads Saved Drive List (JSON)
	↓  
Load-XamlWindow("MainWindow.xaml")
	↓
Windows Forms Loader converts XAML → WPF Objects
	↓
MainWindow appears with:
	- ListBox of saved drives
	- Connect buttons
	- Edit/Exit options
	- Status display
	↓
User Clicks Button → Event Handler fires
	↓
PowerShell Function Executes (Check credentials, map drive, etc.)
	↓
Results appear in Status TextBox
```

## 📦 File Breakdown

### **MainWindow.xaml** (8.2 KB)
- Main application window
- 650×500 pixels
- Contains:
  - DockPanel for header layout
  - ListBox for drive list
  - Info box showing drive count
  - 4 action buttons (Connect, Admin, Edit, Exit)
  - Status TextBox
- Resources section has colors & button styles

### **CredentialWindow.xaml** (4.3 KB)
- Popup dialog for credentials
- 450×280 pixels
- Contains:
  - Username TextBox
  - Password PasswordBox (masked input)
  - OK/Cancel buttons
  - Info box explaining credentials aren't saved

### **AddEditDriveWindow.xaml** (5 KB)
- Popup dialog for adding/editing drives
- 480×340 pixels
- Contains:
  - Drive letter TextBox (with instructions)
  - Network path TextBox (with UNC format hint)
  - Warning box about network accessibility
  - OK/Cancel buttons

### **EditDrivesWindow.xaml** (6.1 KB)
- Dialog to manage saved drives
- 650×500 pixels
- Contains:
  - ListBox of all drives
  - Add, Edit, Remove buttons
  - Information box
  - Done/Cancel buttons

### **map_drivesGUI_WPF.ps1** (17.5 KB)
- Main PowerShell script
- Loads XAML files dynamically at runtime
- Contains:
  - Helper functions (Read-DriveList, Save-DriveList, etc.)
  - Drive mapping functions (Map-SingleDrive, Map-SingleDriveAsAdmin)
  - Dialog wrapper functions (Show-CredentialDialog, Show-AddEditDialog, etc.)
  - Main window setup and event handlers
  - AdminConnect branch for elevated operations

---

## 🎨 Visual Design System

### **Color Palette**
```
Primary:    #007ACC (Microsoft blue)
Primary Dark: #005A9E (darker for hover)
Accent:     #107C10 (green for admin)
Warning:    #FFB900 (orange for warnings)
Danger:     #E81B23 (red for delete)
Background: #F5F5F5 (light gray)
Text:       #333333 (dark gray)
Border:     #D0D0D0 (light gray)
```

### **Typography**
- Font Family: **Segoe UI** (Windows system font)
- Default Size: **11px** (readable, professional)
- Headers: **13-18px, SemiBold**
- Helper text: **9px, Gray**

### **Layout System**
- No hardcoded pixels!
- Uses **DockPanel** (header at top)
- Uses **StackPanel** (vertical/horizontal stacking)
- Auto-sizing with Margin for spacing
- Responsive - adapts to window size

### **Button Styling**
- Rounded corners: 4px radius
- Padding: 12×8 pixels (comfortable click target)
- Background: PrimaryBrush (#007ACC)
- Hover: Darker blue (#005A9E)
- Press: Opacity drops to 0.8
- Cursor: Hand pointer on hover

---

## 🔄 Data Flow

```
1. INITIALIZATION
   ├─ Read drivelist.json
   ├─ Parse JSON → Array of {Letter, Path}
   └─ Display in ListBox

2. USER CLICKS CONNECT
   ├─ Show CredentialWindow
   ├─ Get username & password
   ├─ For each drive:
   │  ├─ Call net.exe with credentials
   │  ├─ Return success/failure
   │  └─ Add result to status
   └─ Show results

3. USER CLICKS EDIT LIST
   ├─ Show EditDrivesWindow
   ├─ Display current drive list
   ├─ Allow add/edit/remove
   ├─ If user clicks Done:
   │  ├─ Convert array to JSON
   │  ├─ Save to drivelist.json
   │  └─ Reload MainWindow display
   └─ If Cancel: discard changes

4. ADMIN CONNECT (elevated)
   ├─ User clicks "Connect as Admin"
   ├─ Launch self with -AdminConnect flag
   ├─ UAC prompt appears
   ├─ Run map drives elevated
   └─ Display results
```

---

## 🚀 To Edit Anything

### **Change UI Layout?**
→ Edit the `.xaml` file directly

### **Change Colors?**
→ Edit hex codes in `Window.Resources` section

### **Add a New Button?**
→ Add `<Button>` tag to `.xaml` + event handler in PowerShell

### **Change Button Size?**
→ Edit `Width` and `Height` in `.xaml`

### **Add new functionality?**
→ Add PowerShell function in `map_drivesGUI_WPF.ps1` + wire it to button event

### **Rebuild EXE?**
```powershell
cd C:\Users\itc\Desktop\MapNetworkDrives
pwsh .\buildGUIExe.ps1
```

---

## 💡 WPF vs WinForms Comparison

### **WinForms (Old)**
```powershell
# Create button with hardcoded pixels
$btn = New-Object System.Windows.Forms.Button
$btn.Location = New-Object System.Drawing.Point(12, 290)
$btn.Size = New-Object System.Drawing.Size(120, 36)
$btn.Text = "Connect"
$btn.BackColor = [System.Drawing.Color]::RoyalBlue
$btn.ForeColor = [System.Drawing.Color]::White
# ... 10+ more lines per button
```

### **WPF (New)**
```xml
<!-- Just 1 line in XAML, styles from Resources -->
<Button x:Name="ConnectButton" 
		Content="Connect" 
		Style="{StaticResource ModernButtonStyle}"
		Width="120"/>
```

**Why WPF is better:**
- ✅ DRY (Don't Repeat Yourself) - reuse styles
- ✅ Easier to read
- ✅ Visual editor support
- ✅ Change style once → ALL buttons update
- ✅ No math required

---

## 📊 Size Comparison (from `du` output)

```
Old WinForms version:  27.5 KB
New WPF version:       17.5 KB (main script)
Total XAML:            ~23.7 KB (4 files)
Combined new:          ~41 KB

Why? WPF separates UI (XAML) from logic (PS1),
allowing better reuse and cleaner code.
```

---

## ✅ Testing Checklist

### **Basic Functionality**
- [ ] Run `map_drivesGUI_WPF.ps1`
- [ ] Window appears with no errors
- [ ] ListBox displays saved drives (or empty if new)
- [ ] Drive count shows correctly
- [ ] Status shows "Ready"

### **UI Interactions**
- [ ] Click "Connect" → asks for credentials
- [ ] Click "Cancel" on credential dialog → cancels without error
- [ ] Click "Edit List" → shows edit dialog
- [ ] Click "Add drive" in edit dialog → shows add dialog
- [ ] Click "Exit" → app closes

### **Visual**
- [ ] Buttons are blue with white text
- [ ] Buttons get darker on hover
- [ ] TextBoxes have borders
- [ ] Status box is readable
- [ ] Window is resizable (or fixed if desired)

### **Drive Mapping**
- [ ] Provide credentials → connects drives
- [ ] Status shows results (success/failed count)
- [ ] Failed connections still show error details
- [ ] Can run multiple times without issues

---

## 🔧 Debugging Tips

### **If window doesn't appear:**
```powershell
# Check for XAML parse errors
try {
	$window = Load-XamlWindow "MainWindow.xaml"
} catch {
	Write-Host "Error: $_"
}
```

### **If buttons don't respond:**
- Check if FindName() is finding the right element
- Verify button x:Name matches exactly in PowerShell/XAML

### **If dialogs don't appear:**
- Ensure IsModal or ShowDialog() is called
- Check if Window.Resources are properly defined

### **If colors look wrong:**
- Verify hex code format `#RRGGBB`
- Check if StaticResource is spelled correctly

---

## 📝 Next Enhancement Ideas (in order of difficulty)

**Easy (5 min):**
1. Change primary color
2. Add emoji icons to buttons
3. Resize window

**Medium (15 min):**
4. Add drive status indicator
5. Add search/filter box
6. Show connection timestamp

**Hard (30+ min):**
7. Drag-to-reorder drives
8. Right-click context menu
9. Implement MVVM data binding
10. Dark mode toggle

See `WPF_ENHANCEMENT_GUIDE.md` for code examples!

---

**This architecture gives you the best of both worlds:**
- PowerShell's power & flexibility (drive mapping, WMI, registry, etc.)
- WPF's modern UI & visual design capabilities
