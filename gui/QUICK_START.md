# Quick Start: WPF Version

## 🚀 Run It
```powershell
cd gui
pwsh map_drivesGUI_WPF.ps1
```

## 📝 Files Created
| File | Purpose |
|------|---------|
| `MainWindow.xaml` | Main app window |
| `CredentialWindow.xaml` | Login dialog |
| `AddEditDriveWindow.xaml` | Add/edit drive dialog |
| `EditDrivesWindow.xaml` | Manage drives list |
| `map_drivesGUI_WPF.ps1` | PowerShell engine |
| `WPF_ENHANCEMENT_GUIDE.md` | Full enhancement guide |

## ✨ Key Differences from Old Version

| Old (WinForms) | New (WPF) |
|---|---|
| ❌ Hardcoded pixel coordinates | ✅ Responsive layout panels |
| ❌ Edit = find & calculate pixels | ✅ Edit = change XAML numbers |
| ❌ Hard to theme | ✅ Colors in one Resource section |
| ❌ Limited styling | ✅ Modern rounded buttons, effects |
| ❌ No visual designer support | ✅ Works with VS designer |

## 🎨 Quick Color Change
1. Open `MainWindow.xaml`
2. Find line: `<Color x:Key="PrimaryColor">#007ACC</Color>`
3. Change `#007ACC` to your color (e.g., `#FF6B6B` for red)
4. Save & run `map_drivesGUI_WPF.ps1` - colors update instantly!

## 🔲 Quick Window Size Change
In `MainWindow.xaml`, line 1:
```xml
<Window ... Height="500" Width="650">
```
Change numbers and re-run (no PS restart needed)

## 🆚 Comparing Features
Both versions do the same thing:
- ✓ Map network drives
- ✓ Save/load drive list
- ✓ Credentials dialog
- ✓ Connect as admin
- ✓ Edit/add/remove drives

New WPF version adds:
- ✨ Modern UI
- ✨ Easy to customize visually
- ✨ No more pixel calculations
- ✨ Better color/font control

## 🎯 Top 3 Quick Enhancements

### 1. Add Icons to Buttons
In `MainWindow.xaml`, change:
```xml
<Button Content="Connect" />
```
To:
```xml
<Button Content="🔗 Connect" />
```

### 2. Change Button Colors
In `MainWindow.xaml` at line 10-20:
```xml
<Color x:Key="PrimaryColor">#007ACC</Color>      <!-- Change this -->
```

### 3. Make Buttons Round
Already done! Corner radius = 4px, hover effects included.

## 📚 Learn More
See `WPF_ENHANCEMENT_GUIDE.md` for 10+ enhancement examples with code.

## 🐛 Testing Tips
- Test PS version first: `pwsh map_drivesGUI_WPF.ps1`
- Changes to .xaml take effect immediately on next run
- Don't need to rebuild EXE until you're happy
- Build EXE when ready: `pwsh buildGUIExe.ps1`

## 📋 Quick Checklist for First Run
- [ ] Run WPF version: `pwsh map_drivesGUI_WPF.ps1`
- [ ] Test "Connect" button
- [ ] Test "Edit List" button
- [ ] Add a test drive
- [ ] Remove test drive
- [ ] Close app
- [ ] Edit a color in MainWindow.xaml
- [ ] Run again and see color change

## ❓ FAQ

**Q: Do I need the old version?**  
A: No, WPF is the new one. Old `map_drivesGUI.ps1` is a backup.

**Q: Will the EXE rebuild work?**  
A: Yes! `buildGUIExe.ps1` auto-detects the WPF version.

**Q: Can I edit XAML in VS Designer?**  
A: Yes! Open any .xaml file, look for Design tab.

**Q: What if I break the XAML?**  
A: Just undo, git checkout, or restore from backup.

**Q: Do I need to know WPF/XAML?**  
A: No! The guide explains each change. Copy-paste code snippets.

## 🔗 Useful WPF Resources
- Colors: Use [colorhexa.com](https://www.colorhexa.com) for hex codes
- Icons: Use emoji (🗂️ ➕ ✏️) or Unicode symbols
- Fonts: System default "Segoe UI" is already set

---

**Version:** WPF 1.0  
**Based on:** Original map_drivesGUI.ps1  
**Last Updated:** 2025
