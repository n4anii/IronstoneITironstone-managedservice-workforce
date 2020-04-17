# IronLockScreenImageEnforcer
## Detection Rule
### Powershell
Detect-IronLockScreenImageEnforcer.ps1
### Manual - Simplest
Path:   HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization
Name:   LockScreenImage
Method: Value exist
### Manual - Medium
#### Registry Key
Type:     Registry
Path:     HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization
Name:     LockScreenImage
Method:   String comparison
Operator: Equals
Value:    %ProgramW6432%\IronstoneIT\IronLockScreenImageEnforcer\LockScreenImage.jpg
#### File Path
Type:     File
Path:     %ProgramW6432%\IronstoneIT\IronLockScreenImageEnforcer
File:     LockScreenImage.jpg
Method:   File or folder exist

### Manual - Advanced
#### Registry Key
Path:   HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization
Name:   LockScreenImage
Method: String comparison
Value:  %SystemDrive%\Program Files\IronstoneIT\IronLockScreenImageEnforcer\LockScreenImage.jpg
#### Path Exist 1
Path:   %HOMEDRIVE%\Program Files\IronstoneIT
Name:   IronLockScreenImageEnforcer
Method: File or directory exist
#### Path Exist 2
Path:   %HOMEDRIVE%\Program Files\IronstoneIT\IronLockScreenImageEnforcer
Name:   LockScreenImage.jpg
Method: File or directory exist