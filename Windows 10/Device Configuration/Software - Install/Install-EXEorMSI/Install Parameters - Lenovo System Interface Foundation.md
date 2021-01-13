# Lenovo System Interface Foundation - Install Parameters


## App Information
### Name
.Lenovo System Interface Foundation vLatest x86

### Description
Lenovo System Interface Foundation

### Publisher
Lenovo



## Program
### Install command
#### Intune
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Install-EXEorMSI.ps1' -ProductName 'FileZilla client' -Uri 'https://filedownload.lenovo.com/enm/sift/core/SystemInterfaceFoundation.exe' -InstallerType 'EXE' -ArgumentList '/SP- /VERYSILENT /NORESTART /SUPPRESSMSGBOXES /TYPE=installpackageswithreboot' -UserContext:$false -InstallVerifyPath ('{0}\System32\ImController.InfInstaller.exe' -f ($env:windir))"
#### Test from PowerShell as admin
& '.\Install-EXEorMSI.ps1' -ProductName 'FileZilla client' -Uri 'https://filedownload.lenovo.com/enm/sift/core/SystemInterfaceFoundation.exe' -InstallerType 'EXE' -ArgumentList '/SP- /VERYSILENT /NORESTART /SUPPRESSMSGBOXES /TYPE=installpackageswithreboot' -UserContext:$false -InstallVerifyPath ('{0}\System32\ImController.InfInstaller.exe' -f ($env:windir))

### Uninstall command
"%windir%\System32\ImController.InfInstaller.exe" -Uninstall

### Install behavior
No specific action

### Return codes
0  = Success.
1  = Error - Failed, unknown reason.
10 = Failproof - Running in wrong context (user vs system).
11 = Failproof - Running as x86 process on x64 OS.
12 = Failproof - Working directory dynamically fetched does not exist.
13 = Failproof - Already installed.
20 = Error - Failed to remove existing installer before downloading new.
21 = Error - Failed to download installer.            
22 = Error - Installer failed.
23 = Error - Installer succeeded, but $InstallVerifyPath does not exist.
24 = Error - Failed to remove installer after script is done. 



## Requirements
### Architecture
32-bit and 64-bit

### OS Version
Windows 10 1607

### Configure additional rules
#### Registry
Key path:					HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\BIOS
Value name:					SystemManufacturer
Registry key requirement:	String comparison
Operator:					Equals
Value:						LENOVO
Associated with a 32-bit app on 64-bit clients: No
#### Script
Script name:										User_Boolean-LenovoSystemUpdateDoesNotRun.ps1
Run script as 32-bit process on 64-bit client:		No
Run this script using the logged on credentials:	Yes
Enforce script signature check:						No
Select output data type:							Boolean
Operator:											Equals
Value:												Yes



## Detection rules
### Manual
#### File
Rule type:			File
Path:				%SystemRoot%\System32
File or folder:		ImController.InfInstaller.exe
Detection method:	String (version)
Operator:			Exists
Associated with a 32-bit app on 64-bit clients: No