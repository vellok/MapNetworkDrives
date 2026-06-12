# WPF Enhancement Guide for Map Network Drives

## Overview
Your app has been converted from **Windows Forms with hardcoded pixels** to **WPF with XAML markup**. This makes it easier to edit visually and add modern features.

---

## What You Got

### Files Created:
1. **MainWindow.xaml** - Main app UI with modern styling
2. **CredentialWindow.xaml** - Credential entry dialog
3. **AddEditDriveWindow.xaml** - Add/edit drive dialog
4. **EditDrivesWindow.xaml** - Manage drives list dialog
5. **map_drivesGUI_WPF.ps1** - PowerShell wrapper that loads all XAML

### Key Improvements Over WinForms:
✅ **No pixel math** - Uses layout panels (DockPanel, StackPanel) for automatic responsive layout
✅ **Visual editing** - Can open XAML in VS 2026 designer and drag/drop controls
✅ **Centralized styling** - Colors, fonts, button styles defined once in Resources
✅ **Modern look** - Built-in rounded corners, hover effects, color scheme
✅ **Easier to maintain** - Separation of UI (XAML) from logic (PowerShell)

---

## How to Use Now

### Run the WPF Version:
```powershell
# From GUI folder
pwsh map_drivesGUI_WPF.ps1
```

### Edit UI in Visual Studio:
1. Open `MainWindow.xaml` in VS 2026
2. Design tab shows visual preview
3. Drag controls, change colors, adjust spacing
4. Auto-generates XAML
5. PowerShell picks up changes (no recompile needed!)

---

## 🚀 Enhancement Ideas (Easy to Medium)

### 1. **Add Icons to Buttons**
Change this button:
```xml
<Button Content="Connect" />
```

To this:
```xml
<Button>
	<StackPanel Orientation="Horizontal">
		<TextBlock Text="🔗" FontSize="14" Margin="0,0,6,0"/>
		<TextBlock Text="Connect" VerticalAlignment="Center"/>
	</StackPanel>
</Button>
```

**Other icons you can use:**
- 🗂️ Folder/Drive
- ➕ Add
- ✎ Edit
- 🗑️ Delete
- ⚙️ Settings
- 🔐 Credentials

---

### 2. **Change Color Scheme**
Colors are in `Window.Resources`. Change these hex codes:
```xml
<Color x:Key="PrimaryColor">#007ACC</Color>      <!-- Main blue -->
<Color x:Key="AccentColor">#107C10</Color>       <!-- Green -->
<Color x:Key="DangerColor">#E81B23</Color>       <!-- Red -->
```

**Popular color combinations:**
- Dark theme: `#1E1E1E` background, `#00D4FF` accent
- Green theme: `#107C10` primary, `#107C10` accent
- Purple theme: `#6B46C1` primary, `#8B5CF6` accent

---

### 3. **Add Window Icon**
1. Find a `.ico` file (e.g., drive icon)
2. Add to `gui/Resources/` folder
3. Update MainWindow.xaml:
```xml
<Window ... Icon="pack://application:,,,/Resources/drive-icon.ico">
```

---

### 4. **Show Connected/Disconnected Status**
In **map_drivesGUI_WPF.ps1**, enhance the list display:

```powershell
# After line ~260, modify the ListBox.ItemTemplate
$driveListBox.ItemsSource = @()  # Clear
foreach ($d in $driveList) {
	# Check if drive is actually connected
	$isConnected = Test-Path "$($d.Letter.TrimEnd(':')):"
	$status = if ($isConnected) { "✓ Connected" } else { "✗ Disconnected" }

	$item = New-Object PSObject -Property @{
		Letter = $d.Letter
		Path = $d.Path
		Status = $status
		StatusIcon = if ($isConnected) { "✓" } else { "✗" }
	}
	$driveListBox.Items.Add($item) | Out-Null
}
```

Then update MainWindow.xaml ItemTemplate to show status.

---

### 5. **Add Drag-to-Reorder Drives**
In PowerShell, make ListBox support drag-drop:

```powershell
$driveListBox.AllowDrop = $true

$driveListBox.Add_DragOver({
	$_.Effects = [System.Windows.DragDropEffects]::Move
})

$driveListBox.Add_Drop({
	if ($driveListBox.SelectedItem) {
		# Reorder logic here
	}
})
```

---

### 6. **Add Search/Filter Box**
In **MainWindow.xaml**, add above the ListBox:

```xml
<TextBox x:Name="SearchBox" Placeholder="Search drives..." Height="32" Margin="0,0,0,8"/>
```

Then in PowerShell:
```powershell
$searchBox.Add_TextChanged({
	$filter = $searchBox.Text.ToLower()
	# Filter driveList and refresh ListBox based on $filter
})
```

---

### 7. **Add Drive Count Indicator**
Already in the UI! It's the blue box that says "X drive(s) configured". You can:
- Change colors (edit in MainWindow.xaml Resources)
- Add a progress indicator
- Show last connection time

---

### 8. **Right-Click Context Menu**
Add to DriveListBox in PowerShell:

```powershell
$contextMenu = New-Object System.Windows.Controls.ContextMenu

$editItem = New-Object System.Windows.Controls.MenuItem
$editItem.Header = "Edit Drive"
$editItem.Add_Click({ 
	# Call Show-AddEditDialog for selected drive
})
$contextMenu.Items.Add($editItem) | Out-Null

$driveListBox.ContextMenu = $contextMenu
```

---

### 9. **Add Keyboard Shortcuts**
In MainWindow.xaml:
```xml
<Window.InputBindings>
	<KeyBinding Key="Ctrl+S" Command="..." />
	<KeyBinding Key="Delete" Command="..." />
</Window.InputBindings>
```

Or in PowerShell:
```powershell
$mainWindow.Add_KeyDown({
	if ($_.Key -eq 'Delete' -and $driveListBox.SelectedIndex -ge 0) {
		# Remove selected drive
	}
})
```

---

### 10. **Animated Status Messages**
Replace the TextBox status with animated feedback:

```xaml
<TextBlock x:Name="StatusText" Text="Ready" Margin="0,0,0,10"/>
```

Then in PowerShell:
```powershell
function Show-Status($message, $duration = 3000) {
	$statusText.Text = $message
	$statusText.Opacity = 1

	Start-Sleep -Milliseconds $duration

	# Fade out animation (if you add StoryBoard)
	$statusText.Opacity = 0
}
```

---

## 🎨 WPF-Specific Enhancement Patterns

### **Data Binding (Automatic UI Updates)**
Instead of manually updating lists, use binding:

```xaml
<ListBox ItemsSource="{Binding DriveList}"/>
```

**Requires:** Create a ViewModel in PowerShell that implements `INotifyPropertyChanged`.

### **Styles & Templates**
All buttons share the same style. To quickly reskin:
1. Edit one `<Style>` in Resources
2. All buttons update automatically
3. No duplicate code!

### **Animations**
```xaml
<Button>
	<Button.Triggers>
		<EventTrigger RoutedEvent="Button.Click">
			<BeginStoryboard>
				<Storyboard>
					<DoubleAnimation ... Duration="0:0:0.3"/>
				</Storyboard>
			</BeginStoryboard>
		</EventTrigger>
	</Button.Triggers>
</Button>
```

### **Theming (Dark/Light Mode)**
Add to Window.Resources:
```xaml
<SolidColorBrush x:Key="BackgroundBrush" Color="White"/>
<!-- Change one key and entire app updates -->
```

### **Converter for Custom Display**
```powershell
# Convert drive object to display string (XAML Binding)
# This goes in code-behind or PowerShell equivalent
```

---

## How to Edit XAML Visually

### **Method 1: Visual Studio Designer**
1. Right-click `MainWindow.xaml` → **Open**
2. Look for **Design** tab at bottom
3. Drag controls, adjust properties in Properties panel
4. Click **XAML** tab to see auto-generated code

### **Method 2: Edit XAML Directly (Our Approach)**
- Open `.xaml` files in VS code editor
- Change colors, fonts, spacing by editing XML
- Save file
- Run app - PowerShell reloads XAML automatically

### **Method 3: Use WPF Designer Tools**
- VS 2026 has built-in WPF designer
- More powerful than most UI builders
- Full IntelliSense for XAML

---

## Common Tasks

### **Change Button Color**
Find in MainWindow.xaml:
```xml
<Style x:Key="ModernButtonStyle" TargetType="Button">
	<Setter Property="Background" Value="{StaticResource PrimaryBrush}"/>
```

Change `{StaticResource PrimaryBrush}` → `"#FF0000"` (red)

### **Make Window Bigger**
```xml
<Window ... Height="600" Width="700">
```

### **Add New Dialog Window**
1. Create `MyNewWindow.xaml` following the template of existing dialogs
2. In PowerShell, add function:
```powershell
function Show-MyNewDialog {
	$window = Load-XamlWindow "MyNewWindow.xaml"
	# ... event handlers ...
	return $window.ShowDialog()
}
```

### **Change Font Size**
In MainWindow.xaml, change:
```xml
<Window ... FontSize="11">  <!-- Default size for all text -->
```

Or per-control:
```xml
<TextBlock FontSize="14" Text="Large Title"/>
```

---

## Testing Your Changes

**Before** running the EXE:
1. Edit `.xaml` file
2. Run `.ps1` version: `pwsh map_drivesGUI_WPF.ps1`
3. Test changes immediately

**Then** rebuild EXE:
```powershell
cd C:\Users\itc\Desktop\MapNetworkDrives
pwsh .\buildGUIExe.ps1
```

---

## Next Steps

**Beginner:** 
- Change colors (edit hex codes in Resources)
- Add icons to buttons (emoji or ➕ symbols)
- Adjust window size

**Intermediate:**
- Add drive status indicator (connected/disconnected)
- Add search box to filter drives
- Add right-click context menu

**Advanced:**
- Implement MVVM pattern with data binding
- Add animations on button clicks
- Create dark mode / theme switcher

---

## Tips & Tricks

1. **Use emoji for quick icons**: 🗂️ 🔗 ➕ ✎ 🗑️ instead of finding image files
2. **Copy-paste XAML snippets** between files - easier than starting from scratch
3. **Use online WPF color pickers** to find hex codes
4. **Test in PS first** (no EXE rebuild needed) - faster iteration
5. **Keep hex colors in Resources** - change once, applies everywhere

---

## When Reading the Code

- **XAML files** = What it looks like (UI structure)
- **map_drivesGUI_WPF.ps1** = How it works (business logic)
- **Window.Resources** = Global styles & colors

This separation makes it MUCH easier to change visuals without touching logic!

