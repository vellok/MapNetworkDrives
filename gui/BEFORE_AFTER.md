# Before & After: WinForms to WPF

## 🔄 The Problem with WinForms (Old Code)

### **Adding a Simple Button**
```powershell
# Old WinForms way: ~15 lines of math
$btn = New-Object System.Windows.Forms.Button
$btn.Text = 'Connect'
$btn.Size = New-Object System.Drawing.Size(120, 36)      # <-- pixel math
$btn.Location = New-Object System.Drawing.Point(12, 290)  # <-- pixel math
$btn.BackColor = [System.Drawing.Color]::RoyalBlue        # <-- hardcoded color
$btn.ForeColor = [System.Drawing.Color]::White            # <-- hardcoded color
$btn.Font = New-Object System.Drawing.Font('Segoe UI', 11) # <-- hardcoded font

# Each button needs similar setup...
# If you want to change color = find & replace all instances
# If you want to resize = recalculate all pixel positions
# 😫 Pain!
```

### **Editing UI = Trial & Error**
Want to move the Connect button down 10 pixels?
1. Change 290 → 300
2. Run script
3. Check result
4. Adjust
5. Repeat...

---

## ✨ The Solution: WPF (New Code)

### **Same Button in WPF/XAML**
```xml
<!-- New WPF way: 1 clean line -->
<Button x:Name="ConnectButton" 
		Content="Connect" 
		Style="{StaticResource ModernButtonStyle}"
		Width="120"/>
```

### **Change Button Color Globally**
Change **ONE line** in Resources:
```xml
<Color x:Key="PrimaryColor">#007ACC</Color>  <!-- Change this -->
```

**Result:** ALL buttons using that color update instantly! 🎨

---

## 🎯 Side-by-Side Comparison

### **Creating the Main Window**

#### ❌ OLD (WinForms)
```powershell
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Map My Drives'
$form.Size = New-Object System.Drawing.Size(580, 440)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Then for EACH control:
#  - Create object
#  - Set size
#  - Set location (requires pixel math!)
#  - Set color
#  - Set font
#  - Add event handlers
#  - Add to form

# Result: 400+ lines of code for simple GUI
```

#### ✅ NEW (WPF)
```xml
<!-- MainWindow.xaml: 150 lines total, mostly readable -->
<Window Title="Map My Drives" Height="500" Width="650">
	<Window.Resources>
		<!-- Colors defined ONCE -->
		<Color x:Key="PrimaryColor">#007ACC</Color>
		<!-- Styles defined ONCE, reused many times -->
		<Style x:Key="ModernButtonStyle" .../>
	</Window.Resources>

	<!-- Layout: responsive, no pixel calculations -->
	<DockPanel>
		<Border DockPanel.Dock="Top">...</Border>
		<StackPanel>
			<!-- Controls auto-arrange -->
			<ListBox ... />
			<Button ... />
		</StackPanel>
	</DockPanel>
</Window>
```

---

## 📊 Metrics

| Aspect | WinForms | WPF |
|--------|----------|-----|
| **Main Script** | 27.5 KB | 17.1 KB |
| **Settings** | Hardcoded in code | XML Resources |
| **Colors** | Change all 10 buttons | Edit 1 color line |
| **Reposition Button** | Recalculate pixels | Edit number or drag |
| **Time to resize window** | 5 min (pixel math) | 30 sec (change number) |
| **Visual editor support** | No | Yes (VS 2026) |
| **Button hover effect** | Manual code | Built-in |
| **Button styling** | Individual setup | Shared style |

---

## 🎨 Visual Editing

### **Old way (WinForms):**
1. Edit code: `$btn.Location = New-Object System.Drawing.Point(12, 290)`
2. Calculate new position
3. Test, adjust, repeat

### **New way (WPF):**

**Option A - Visual Designer (Easiest)**
1. Right-click MainWindow.xaml → Open
2. Click Design tab (visual preview)
3. Drag button with mouse
4. VS auto-updates XAML
5. Done!

**Option B - Edit XAML (Quick)**
1. Edit to: `Width="120"` (just change the number)
2. Save file
3. Test (no rebuild needed!)

---

## 🖼️ Styling Before & After

### **Color Scheme Change**

#### ❌ Old WinForms
```powershell
# Change button colors scattered everywhere
$btnConnect.BackColor = [System.Drawing.Color]::BlueViolet
$btnEdit.BackColor = [System.Drawing.Color]::BlueViolet
$btnAdmin.BackColor = [System.Drawing.Color]::BlueViolet
$btnRemove.BackColor = [System.Drawing.Color]::Red
$lblHeader.ForeColor = [System.Drawing.Color]::DarkBlue
# ... 20+ lines later: hope you got them all
```

#### ✅ New WPF
```xml
<!-- MainWindow.xaml: Edit once, everywhere updates -->
<Color x:Key="PrimaryColor">#8B00FF</Color>  <!-- Purple -->
<Color x:Key="DangerColor">#FF1744</Color>   <!-- Red -->
```
✨ **All buttons update automatically**

---

## 🚀 Enhancement Speed

### **Add Icons to Buttons**

#### ❌ WinForms (15 min)
1. Find or create .ico files
2. Add resource references
3. Configure ImageList
4. Assign to buttons
5. Test sizing...

#### ✅ WPF (2 min)
```xml
<Button>
	<StackPanel Orientation="Horizontal">
		<TextBlock Text="🔗" Margin="0,0,6,0"/>
		<TextBlock Text="Connect"/>
	</StackPanel>
</Button>
```
Done! Emoji are built-in.

---

## 💡 Key Advantages Gained

### **1. Separation of Concerns**
- **UI** (XAML): What it looks like
- **Logic** (PowerShell): How it works
- Easy to change one without breaking other

### **2. Reusable Styles**
Define style ONCE:
```xml
<Style x:Key="ModernButtonStyle" TargetType="Button">
	<Setter Property="Background" Value="{StaticResource PrimaryBrush}"/>
	<Setter Property="Padding" Value="12,8"/>
	<Setter Property="BorderThickness" Value="0"/>
	<!-- ... more properties ... -->
</Style>
```

Use everywhere:
```xml
<Button Style="{StaticResource ModernButtonStyle}" Content="Click me"/>
<Button Style="{StaticResource ModernButtonStyle}" Content="Click too"/>
<Button Style="{StaticResource ModernButtonStyle}" Content="And me"/>
```

Change style = ALL buttons update 🎯

### **3. Visual Designer Support**
- Open `.xaml` in VS 2026
- See live preview
- Drag controls
- See XAML auto-update
- No more guessing

### **4. Responsive Layout**
DockPanel, StackPanel, Grid = automatic sizing
- Window resizes? → Controls auto-fit
- Add new control? → Spacing auto-adjusts
- No pixel math needed!

### **5. Modern Effects**
Built-in from Windows 10:
- Rounded corners
- Animations
- Transparency
- Blur effects
- Smooth hover states

---

## 📝 Code Examples: Same Feature, Different Ways

### **Status Message With Timer**

#### ❌ WinForms (Complex)
```powershell
$statusLabel.Text = "Connected!"
[System.Windows.Forms.Application]::DoEvents()
Start-Sleep -Seconds 2
$statusLabel.Text = "Ready"
# This BLOCKS the UI while sleeping
```

#### ✅ WPF (Elegant)
```xaml
<!-- In XAML with animation -->
<TextBlock x:Name="StatusText" Text="Connected!" Opacity="1">
	<TextBlock.Triggers>
		<EventTrigger RoutedEvent="Loaded">
			<BeginStoryboard>
				<Storyboard>
					<DoubleAnimation 
						Storyboard.TargetProperty="Opacity" 
						From="1" To="0" 
						Duration="0:0:2"/>
				</Storyboard>
			</BeginStoryboard>
		</EventTrigger>
	</TextBlock.Triggers>
</TextBlock>
```
// No code-behind blocking!

---

## 🎓 Learning Curve

| Skill | WinForms | WPF |
|-------|----------|-----|
| **Basic setup** | Medium | Easy |
| **Add a button** | Medium | Easy |
| **Change colors** | Hard | Easy |
| **Styling** | Hard | Medium |
| **Visual editing** | No | Easy |
| **Responsive design** | Hard | Medium |

**TL;DR:** WPF is EASIER once you have the files!

---

## ✅ Checklist: Migration Complete

- ✅ **XAML files created** (4 windows)
- ✅ **PowerShell wrapper created** (loads XAML)
- ✅ **Modern styling applied** (colors, fonts, effects)
- ✅ **Layout system improved** (no pixel math)
- ✅ **All business logic preserved** (drive mapping works)
- ✅ **Visual editor compatible** (can edit in VS Designer)
- ✅ **Documentation** (guides + examples)

---

## 🚀 Your Next Steps

1. **Try it:**
   ```powershell
   cd C:\Users\itc\Desktop\MapNetworkDrives\gui
   pwsh map_drivesGUI_WPF.ps1
   ```

2. **Make a small change:**
   - Edit `MainWindow.xaml`
   - Change primary color `#007ACC` → `#E91E63` (pink)
   - Save & rerun to see instant change

3. **Open in Visual Studio:**
   - Right-click `MainWindow.xaml`
   - Click Design tab
   - Move a button with mouse
   - See XAML update automatically

4. **Read the enhancement guide:**
   - `WPF_ENHANCEMENT_GUIDE.md` has 10+ examples
   - Copy-paste code snippets
   - Customize to your needs

---

## 🎉 Result

**Before:** 400+ lines of hardcoded WinForms coordinate math  
**After:** Clean XAML + focused PowerShell logic  
**Benefit:** Visual editing + easier customization + modern look

**You now have the best of both worlds! 🚀**

