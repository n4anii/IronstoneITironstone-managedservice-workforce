# Win32 Install Parameters



## Program
### Install
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Create-Shortcut(QuickAssist).ps1'; exit $LASTEXITCODE"

### Uninstall
"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Remove-Shortcut(QuickAssist).ps1'; exit $LASTEXITCODE"

### Install behavior
User

### Device restart behavior
No specific action

### Return code
0 = Success
1 = Failed



## Requirements
Operating system architecture:		32 and 64 bit
Minimum operating system:			Windows 10 1607



## Detection rule
Rules format:						Use a custom detection script
Script file:						*.ps1
Run script as 32-bit on 64-bit OS:	No
Enforce script signature check:		No



## Dependencies
None



## Scope tags
None



## Assignments
### Assignment settings
Mode:								Included

### App settings
End user notifications:				Hide all toast notifications
Time zone:							Device time zone
App availability:					As soon as possible
App installation deadline:			As soon as possible