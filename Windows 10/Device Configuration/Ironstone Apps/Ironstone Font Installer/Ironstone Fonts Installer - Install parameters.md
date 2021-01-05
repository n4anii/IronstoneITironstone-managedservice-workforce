# Ironstone Fonts Installer - Install parameters
## How
* Add fonts (*.ttf) to .\Fonts
* Create custom uninstall script for given font
* Package ".\Fonts", "Device_Install-Fonts.ps1" and "Device_Uninstall-Fonts(<Custom>).ps1" to Win32



## App information
### Name
.Ironstone Fonts Installer - Meta

### Description
Installs fonts.

### Publisher
Ironstone



## Program
### Install command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-Fonts.ps1'"

### Uninstall command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-Fonts(Meta).ps1'"

### Install behavior
System



## Requirements
### Operating system architecture
32-bit or 64-bit

### Minimum operating system
Windows 10 1607



## Detection rules
### Manually configure detection rules
#### Registry
Path:	HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
Name:	Meta Corr Offc Pro (TrueType)
Value:	MetaCorrOffcPro.ttf
Associated with a 32-bit app on 64-bit clients: No