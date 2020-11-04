# ConnectWise Automate Agent Uninstaller Script
## App Information
### Name
.ConnectWise Automate Agent Uninstaller Script

### Description
Uninstalls ConnectWise Automate agent if wrong server password is detected in registry, or other obvious errors are present.

### Publisher
Ironstone



## Program
### Install command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-ConnectWiseAutomateAgent.ps1'"

### Uninstall command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Uninstall-ConnectWiseAutomateAgent.ps1'"

### Install behavior
System

### Device restart behavior
No specific action

### Return codes
0 = Success
1 = Fail



## Requirements
Require-CheckIfConnectWiseAutomateMustBeUninstalled.ps1
Boolean = $true


## Detection rule
Detect-ConnectWiseAutomateAgentPasswordUninstalled.ps1