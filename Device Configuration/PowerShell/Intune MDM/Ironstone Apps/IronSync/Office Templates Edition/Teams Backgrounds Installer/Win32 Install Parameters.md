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

## Install behavior
User

## Device restart behavior
No specific action

## Exit codes
0 = Success
1 = Fail
