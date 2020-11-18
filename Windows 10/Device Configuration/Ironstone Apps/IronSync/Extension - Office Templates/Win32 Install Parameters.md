# IronSync - Extension - Office Templates - Win32 Install Parameters
## App information
### Name
.Ironstone IronSync - Extension - Office Templates v201116

### Description
Sets Office templates folder for Excel, PowerPoint and Word per user on the device.

### Publisher
Ironstone IT


## Program
### Install command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\User_Install-IronSync_Extension_OfficeTemplates.ps1'; exit $LASTEXITCODE"

### Uninstall command
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\User_Uninstall-IronSync_Extension_OfficeTemplates.ps1'"

### Install behavior
User

### Device restart behavior
No specific action

### Return codes
0 = Success
1 = Fail


## Requirements
### Operating system architecture
64-bit

### Minimum operating system
Windows 10 1607

### Configure additional requirement rules
#### File
Path: 			%PUBLIC%
File or Folder:	IronSync
Property: 		File or folder exists
Associated with a 32-bit app on 64-bit client: No


## Detection rule
### Use a custom detection script
User_Detect-IronSync_Extension_OfficeTemplates.ps1
Run script as 32-bit process on 64-bit clients: No
Enforce script signature check and run script silently: No



## Dependencies
AzCopy
IronSync