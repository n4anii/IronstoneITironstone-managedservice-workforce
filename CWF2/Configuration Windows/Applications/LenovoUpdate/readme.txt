APP INFO

Name
Lenovo System Update

Description
Installs latest version of System Update and runs a scan for available firmware updates during Autopilot.
After installation it creates a scheduled task to check for critical and recommended updates on a weekly basis.

Publisher
Lenovo/Ironstone


Install command
powershell.exe -ExecutionPolicy Bypass -File .\Invoke-SystemUpdate.ps1
Uninstall command
cmd.exe /c
Install behavior
System

ADD Requirement rule

Key path- HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\BIOS
Value name- SystemManufacturer
String comparison
Equals
Value- LENOVO

Detection rules

Manually configure - file or folder exists
Path- %ProgramData%\Lenovo\SystemUpdate\sessionSE
file or folder- update_history.txt