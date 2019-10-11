## App information
### Name
.Mozilla Firefox x64 vLatest en-US
### Description
Mozilla Firefox x64 vLatest en-US
### Publisher
Ironstone IT, Mozilla Foundation

## Program
### Install
#### x64 enUS
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-MozillaFirefox.ps1' -Language 'en-US' -Architecture 'win64'; exit $LASTEXITCODE"
#### x64 nbNO
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-MozillaFirefox.ps1' -Language 'nb-NO' -Architecture 'win64'; exit $LASTEXITCODE"
### Uninstall
#### x64
"%ProgramW6432%\Mozilla Firefox\uninstall\helper.exe" -ms
#### x86
"%ProgramFiles(x86)%\Mozilla Firefox\uninstall\helper.exe" -ms
### Install behavior
System

## Requirements
Operating system architecture:	32-bit and 64-bit
Minimum operating system:		Windows 10 1607
Disk space required:			200mb
### PowerShell
Script name:								 		Device_Boolean-MozillaFirefoxDoesNotRun.ps1
Run script as 32-bit process on 64-bit clients:		No
Run this script using the logged on credentials:	No
Enforce script signature check:						No
Output data type:									Boolean
Operator:											Equals
Value:												Yes
### File - Firefox x64
Path:						%ProgramW6432%\Mozilla Firefox
File or folder:				firefox.exe
Detection method:			File or folder does not exist
Associated with a 32-bit app on 64-bit clients: No
### File - Firefox x86
Path:						%ProgramFiles(x86)%\Mozilla Firefox
File or folder:				firefox.exe
Detection method:			File or folder does not exist
Associated with a 32-bit app on 64-bit clients: No


## Detection rule
### File - Firefox x64
Path:						%ProgramW6432%\Mozilla Firefox
File or folder:				firefox.exe
Detection method:			File or folder exists
Associated with a 32-bit app on 64-bit clients: No
### File - Firefox x86
Path:						%ProgramFiles(x86)%\Mozilla Firefox
File or folder:				firefox.exe
Detection method:			File or folder exists
Associated with a 32-bit app on 64-bit clients: No

## Return codes
0  = Success	= Success.
1  = Failed 	= Error - Failed, unknown reason.
10 = Failed		= Failproof - Can't install x64 Mozilla Firefox on x86 OS.
11 = Failed		= Failproof - Firefox already installed, same architecture.
12 = Failed		= Failproof - Firefox already installed, other architecture.
13 = Failed		= Failproof - Firefox already installed, non-default location. Install path is mentioned in error message.
14 = Retry		= Error - Failed to remove existing installer before downloading new.
15 = Retry		= Error - Failed to download installer.
16 = Retry		= Error - Installer failed.
17 = Failed 	= Error - Failed to remove installer after script is done.