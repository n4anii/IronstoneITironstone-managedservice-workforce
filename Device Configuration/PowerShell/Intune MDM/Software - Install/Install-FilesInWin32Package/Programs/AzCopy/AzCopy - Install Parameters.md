# Ironstone Binaries - Microsoft AzCopy 10 x64



## App Information
### Name
.Ironstone - Binaries - Microsoft AzCopy v10.7.0 x64

### Description
Installs Ironstone binary/ dependency AzCopy.exe for use with other solutions developed by Ironstone.

### Publisher
Microsoft; Ironstone



## Program
### Install command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Install-FilesInWin32Package.ps1' -OutputPath ('{0}\IronstoneIT\Binaries\AzCopy'-f($env:ProgramData)) -Overwrite -AddToEnvVariables; exit $LASTEXITCODE"

### Uninstall command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "[System.IO.Directory]::Delete(('{0}\IronstoneIT\Binaries\AzCopy'-f$env:ProgramData),$true)"

### Install behavior
System

### Device restart behavior
No specific action

### Return codes
00   =  Success  =  Success.
01   =  Failed   =  Unhandeled error.
10   =  Failed   =  Not running as 64 bit on 64 bit OS.
11   =  Failed   =  Source directory does not exist.
12   =  Failed   =  Source directory does not contain any items.
13   =  Failed   =  Did not find RoboCopy.
14   =  Failed   =  Output path is too close to root.
20   =  Failed   =  Output path already exist, and input parameter $Overwrite is set to $false.
21   =  Failed   =  Robocopy failed to sync files over to destination directory. Permissions?
30   =  Failed   =  Failed to add output path to environmental variables.



## Requirements
### Operating system architecture
x64

### Minimum operating system
Windows 10 1607

### Configure additional requirement rules
#### Script
##### Script name
Require-AzCopyDoesNotRun.ps1
##### Run script as 32-bit process on 64-bit clients
No
##### Run this script using the logged on credentials
No
##### Enforce script signature check
No
##### Output type
Boolean
##### Operator
Equals
##### Value
Yes



## Detection rules
Detect-AzCopyInstalledVersion.ps1



## Dependencies
None