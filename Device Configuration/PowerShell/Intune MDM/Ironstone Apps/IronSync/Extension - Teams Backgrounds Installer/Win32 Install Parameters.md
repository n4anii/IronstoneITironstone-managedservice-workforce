# Win32 Install Parameters



## App information
### Name
.Ironstone - IronSync - Teams Background extension v200519

### Description
Syncs Teams background images out from IronSync to Teams background folder location.

### Publisher
Ironstone



## Program
### Install & Uninstall
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\User_Install-TeamsBackgroundsFromIronSync.ps1'; exit $LASTEXITCODE"

### Install behavior
User

### Device restart behavior
No specific action

### Exit codes
0 = Success
1 = Fail



## Requirements
### Operating system architecture
64 bit

### Minimum operating system
Windows 10 1607

### Configure additional requirement script
#### Script file
Device_Require-IronSyncTeamsBackgroundsArePresent.ps1
#### Runs cript as 32-bit process on 64-bit clients
No
#### Run this script using the logged on credentials
No
#### Enforce script signature check
No
#### Select output data type
Boolean
#### Operator
Equals
#### Value
Yes



## Dependencies
### 1 - AzCopy
#### Name
.Ironstone - Binaries - Microsoft AzCopy v10.4.3 x64
#### Automatically install
Yes

### 2 - IronSync
#### Name
.Ironstone - Ironsync v<yearmonthday>
#### Automatically install
Yes