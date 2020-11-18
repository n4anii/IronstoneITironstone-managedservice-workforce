# Device_Install-GoogleChrome.ps1
## App information
### Name
.Google Chrome vLatest x64

### Description
Install script version 1.0.0.0.
Installs latest Google Chrome x86, if system is x64 it will automatically upgrade to x64 Chrome later during auto update.
Language is decided by OS language, but can also be changed by end user later. Can not be set using install parameters.

### Publisher
Ironstone, Alphabet

### Logo
Chrome Logo 200x200px



## Program

### Install
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-GoogleChromeBrowser.ps1'; exit $LASTEXITCODE"

### Uninstall
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-GoogleChromeBrowser.ps1'; exit $LASTEXITCODE"

### Install behavior
System

### Device restart behavior
No specific action



## Requirements
### Operating system architecture
32-bit & 64-bit

### Minimum operating system
Windows 10 1607

### Disk space required (MB)
500

### Configure additional requirement rules
#### File - Not installed
* Path:					%ProgramFiles(x86)%\Google\Chrome\Application
* File or folder:		chrome.exe
* Detection method:		File or folder does not exist
* Associated with a 32-bit app on 64-bit clients: No

#### Script - Not running
* Script name:										Device_Boolean-GoogleChromeBrowserIsNotRunning.ps1
* Run script as 32-bit process on 64-bit clients:	No
* Run this script using the logged on credentials:	No
* Enforce script signature check:					No
* Select output data type:							Boolean
* Operator:											Equals
* Value:											Yes

#### DON'T USE ### Script - Not installed (Use "File - Not installed" instead)
* Script name:										Device_Boolean-GoogleChromeBrowserIsNotInstalled.ps1
* Run script as 32-bit process on 64-bit clients:	No
* Run this script using the logged on credentials:	No
* Enforce script signature check:					No
* Select output data type:							Boolean
* Operator:											Equals
* Value:											Yes



## Detection rules
### Manually configure detection rules
#### File
* Path:				%ProgramFiles(x86)%\Google\Chrome\Application
* File or folder:	chrome.exe
* Detection method:	File or folder exists
* Associated with a 32-bit app on 64-bit clients: No



## Return codes
* 00 = Success	= Install successfull.
* 01 = Failed	= Error - Failed, unknown reason.
* 10 = Failed	= Failproof - Already installed.
* 11 = Failed	= Failproof - Already installed, non-default location. Install path is mentioned in error message.
* 12 = Retry	= Error - Failed to remove existing installer before downloading new.
* 13 = Retry	= Error - Failed to download installer.
* 14 = Retry	= Error - Installer failed.
* 15 = Failed	= Error - Failed to remove installer after script is done.