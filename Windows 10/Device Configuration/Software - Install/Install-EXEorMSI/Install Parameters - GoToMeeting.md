# Visual Studio Code

## App Information
### Name
.GoToMeeting vLatest x64

### Description
Installs GoToMeeting in system context if not already installed.

### Publisher
GoToMeeting


## Program
### Install command
#### Intune
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Install-EXEorMSI.ps1' -ProductName 'Visual Studio Code' -Uri 'https://go.microsoft.com/fwlink/?Linkid=852157' -InstallerType 'EXE' -ArgumentList '/VERYSILENT /NORESTART /NOCLOSEAPPLICATIONS /NORESTARTAPPLICATIONS /MERGETASKS=!runcode' -UserContext:$false -InstallVerifyPath ('{0}\Microsoft VS Code\Code.exe' -f ($env:ProgramW6432))"

### Uninstall command
msiexec /u

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
Path:	%ProgramW6432%\Microsoft VS Code
File:	Code.exe
Rule:	Exists
Associated with a 32-bit app on 64-bit clients: No
