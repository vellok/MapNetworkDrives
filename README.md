# App to manage and connect to a list of network drives

This repository contains two versions of the drive mapper:

- CLI version:
  - `cli\map_drives.ps1`
  - `cli\MapMyDrives.cmd`
  - command-line/terminal interaction only

- GUI version:
  - `gui\map_drives.gui.ps1`
  - `gui\MapMyDrivesGUI.cmd`
  - `gui\MapMyDrivesGUI.exe`
  - runs a Windows Forms GUI and supports normal or elevated mapping

To rebuild the GUI executable after changes:
- `pwsh .\buildGUIExe.ps1`
