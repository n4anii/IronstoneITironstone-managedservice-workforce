# FileZilla client - Install Parameters


## App Information
### Name
.FileZilla client x64 vLatest

### Description
Installs FileZilla client in system context if not already installed.

### Publisher
FileZilla


## Program
### Install command
#### Intune
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Install-EXEorMSI.ps1' -ProductName 'FileZilla client' -Uri 'https://download.filezilla-project.org/client/FileZilla_latest_win64-setup.exe' -InstallerType 'EXE' -ArgumentList '/S /user=all' -UserContext:$false -InstallVerifyPath ('{0}\FileZilla FTP Client\filezilla.exe' -f ($env:ProgramW6432))"
#### Test from PowerShell as admin
& '.\Install-EXEorMSI.ps1' -ProductName 'FileZilla client' -Uri 'https://download.filezilla-project.org/client/FileZilla_latest_win64-setup.exe' -InstallerType 'EXE' -ArgumentList '/S /user=all' -UserContext:$false -InstallVerifyPath ('{0}\FileZilla FTP Client\filezilla.exe' -f ($env:ProgramW6432))

### Uninstall command
"%ProgramW6432%\FileZilla FTP Client\uninstall.exe" /S

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
64-bit

### OS Version
Windows 10 1607



## Detection rules
### Manual
#### File
Path:	%ProgramW6432%\FileZilla FTP Client
File:	filezilla.exe
Rule:	Exists
Associated with a 32-bit app on 64-bit clients: No