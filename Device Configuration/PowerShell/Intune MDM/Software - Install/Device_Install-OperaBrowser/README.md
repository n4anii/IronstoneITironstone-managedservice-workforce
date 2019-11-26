# Device_Install-OperaBrowser.ps1
## App information
### Name
.Opera Browser vLatest x64

### Description
Install script version 1.0.0.0.
Installs latest version of Opera Browser.
Architecture is set by script parameters.
Language is set to match OS by default, can be changed by the end user. Not possible to set with install parameters.

### Publisher
Ironstone, Opera Software

### Logo
Opera logo 200x200px.png


## Program
### Install x64
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-OperaBrowser.ps1' -Architecture 'x64'; exit $LASTEXITCODE"

### Install x86
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-OperaBrowser.ps1' -Architecture 'x86'; exit $LASTEXITCODE"

### Uninstall x64
"%ProgramW6432%\Opera\Launcher.exe" /uninstall /silent

### Uninstall x86
"%ProgramFiles(x86)%\Opera\Launcher.exe" /uninstall /silent

### Install Behavior
System

### Device restart behavior
No specific action



## Requirements
### Operating system architecture
64 bit (x64) or 32 bit and 64 bit (x86)

### Minimum operating system
Windows 10 1607

### Disk space required (MB)
200

### Configure additional requirement rules
#### Script - "Device_Boolean-OperaBrowserDoesNotRun.ps1"
* Script name: Device_Boolean-OperaBrowserDoesNotRun.ps1
* Run script as 32-bit process on 64-bit clients: No
* Run this script using the logged on credentials: No
* Enforce script signature check: No
* Select output data type: Boolean
* Operator: Equals
* Value: Yes

#### File - 64-bit
* Path: 			%ProgramW6432%\Opera
* File or folder:	launcher.exe
* Property:			File or folder does not exist
* Associated with a 32-bit app on 64-bit clients: No

#### File - 32-bit
* Path: 			%ProgramFiles(x86)%\Opera
* File or folder:	launcher.exe
* Property:			File or folder does not exist
* Associated with a 32-bit app on 64-bit clients: No



## Detection rules
### File
* Path (if x64):	%ProgramW6432%\Opera
* Path (if x86):	%ProgramFiles(x86)%\Opera
* File or folder:	launcher.exe
* Property:			File or folder exists
* Associated with a 32-bit app on 64-bit clients: No



## Return codes
* 0  = Success	= Success.
* 1  = Failed	= Error - Failed, unknown reason.
* 10 = Failed	= Failproof - Can't install x64 Mozilla Firefox on x86 OS.
* 11 = Failed	= Failproof - Already installed, same architecture.
* 12 = Failed	= Failproof - Already installed, other architecture.
* 13 = Failed	= Failproof - Already installed, non-default location. Install path is mentioned in error message.
* 14 = Retry	= Error - Failed to remove existing installer before downloading new.
* 15 = Retry	= Error - Failed to fetch available versions.
* 16 = Retry	= Error - Failed to download installer.
* 17 = Retry	= Error - Installer failed.
* 18 = Failed	= Error - Failed to remove installer after script is done.