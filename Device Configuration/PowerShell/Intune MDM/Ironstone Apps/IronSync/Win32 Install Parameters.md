# Win32 Install Parameters



## App Information
### Name
.Ironstone - IronSync v201008

### Description
Syncs Office Templates and other files from Azure Blog Storage, and make them available in Word, PowerPoint and Excel.

### Publisher
Ironstone



## Program
### Install command
#### Ironstone
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-IronSync.ps1' -CustomerAzureStorageAccountName 'istnoebptwironsync' -CustomerAzureStorageAccountBlobName 'files' -CustomerAzureStorageAccountSASToken '?sv=2019-10-10&ss=b&srt=co&sp=rl&se=2025-05-19T20:04:21Z&st=2020-05-19T12:04:21Z&spr=https&sig=zwP7mh8YBUvnWq%2FvSQcM3fjD5fALRn4KD2obSE1fm4c%3D'; exit $LASTEXITCODE"

#### Bergans
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-IronSync.ps1' -CustomerAzureStorageAccountName 'bergansclientstorage' -CustomerAzureStorageAccountBlobName 'office365-templates' -CustomerAzureStorageAccountSASToken '?sv=2019-12-12&ss=b&srt=co&sp=rl&se=2025-10-08T16:09:16Z&st=2020-09-08T08:09:16Z&spr=https&sig=RWHNoHKIwmgQsdq4wkUP2B5ykoa211tghy5zqh%2FjGgA%3D'; exit $LASTEXITCODE"

#### Block Watne
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-IronSync.ps1' -CustomerAzureStorageAccountName 'cid01peuwbptwo365stg' -CustomerAzureStorageAccountBlobName 'office-templates' -CustomerAzureStorageAccountSASToken '?sv=2019-02-02&ss=b&srt=co&sp=rl&se=2030-11-11T12:00:00Z&st=2019-11-11T12:00:00Z&spr=https&sig=ITFe7S1QtiL8qTdnpGPfUrwx4o%2B%2FpWg8n0IYNWDOWkk%3D'; exit $LASTEXITCODE"

### De nasjonale (FEK)
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-IronSync.ps1' -CustomerAzureStorageAccountName 'fekclientstorage' -CustomerAzureStorageAccountBlobName 'office365-templates' -CustomerAzureStorageAccountSASToken '?sv=2019-12-12&ss=b&srt=co&sp=rl&se=2025-09-09T16:29:19Z&st=2020-09-09T08:29:19Z&spr=https&sig=qOTyfP26%2FAkJWug%2Fips6mAC5pNoHbZlgFCTZ0Rnt12Q%3D'; exit $LASTEXITCODE"

### Feiring
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-IronSync.ps1' -CustomerAzureStorageAccountName 'feipnoeclientstoragestg' -CustomerAzureStorageAccountBlobName 'files' -CustomerAzureStorageAccountSASToken '?sv=2019-12-12&ss=b&srt=co&sp=rl&se=2025-11-06T16:57:57Z&st=2020-11-06T08:57:57Z&spr=https&sig=SD30b0XlK0pEV3CDnksXrwYp%2B0tnmwOuVjusY%2B53pqM%3D'; exit $LASTEXITCODE"

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
Device_Detect-IronSync-v201008.ps1
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