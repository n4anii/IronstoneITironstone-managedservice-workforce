# Win32 Install Parameters



## App Information
### Name
.Ironstone - Ironsync v200525

### Description
Syncs Office Templates and other files from Azure Blog Storage, and make them available in Word, PowerPoint and Excel.

### Publisher
Ironstone



## Program
### Install command
#### Ironstone
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-IronSync.ps1' -CustomerAzureStorageAccountName 'istnoebptwironsync' -CustomerAzureStorageAccountBlobName 'files' -CustomerAzureStorageAccountSASToken '?sv=2019-10-10&ss=b&srt=co&sp=rl&se=2025-05-19T20:04:21Z&st=2020-05-19T12:04:21Z&spr=https&sig=zwP7mh8YBUvnWq%2FvSQcM3fjD5fALRn4KD2obSE1fm4c%3D'; exit $LASTEXITCODE"

### Uninstall command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-IronSync.ps1'; exit $LASTEXITCODE"

### Install behavior
System

### Device restart behavior
No specific action

### Return codes
0 = Success
1 = Fail



## Requirements
### Operating system architecture
x64

### Minimum operating system
Windows 10 1607



## Detection rules
### Use a custom detection script
#### Script file
Device_Detect-IronSync.ps1
#### Run script as 32-bit process on 64-bit clients
No
#### Enforce script signature check and run script silently
No



## Dependencies
### AzCopy v10
#### Name
.Ironstone - Binaries - Microsoft AzCopy v10.4.3 x64
#### Automatically install
Yes