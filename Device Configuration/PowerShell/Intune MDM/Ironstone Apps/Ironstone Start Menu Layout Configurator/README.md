# Ironstone Start Meny Layout Configurator

## App Information
### Name
* .Ironstone Start Meny Layout Configurator

### Description
* Sets start menu layout to a simple, non bloated view that the user can edit afterwards. Script has to run before the user profile is created on the machine.

### Publisher
* Ironstone


## Program
### Install command
* ```"%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Import-StartMenuLayout.ps1'; exit $LASTEXITCODE"```

### Uninstall command
*  ```cmd /c "del /f "%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml""```

### Install behavior
* System


## Requirements
### Operating system architecture
* 32-bit and 64-bit

### Minimum operating system
* Windows 10 1607

### Configure additional requirement rules
#### PowerShell - Device_Boolean-NoAzureADUserProfileExistYet.ps1
* Script name:												Device_Requirement-BooleanNoAzureADUserProfileExistYet.ps1
* Run script as 32-bit process on 64-bit clients: 			No
* Run this script using the logged on credentials: 			No
* Enforce script signature check:							No
* Select output data type:									Boolean
* Operator:													Equals
* Value:													Yes

#### File
* Path:														%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell
* File or folder:											LayoutModification.xml
* Property:													File or folder does not exist
* Associated with a 32-bit app on 64-bit clients:			No


## Detection rules
### Custom script
Name:														Device_DetectionRule-IronstoneStartMenuLayoutConfigurator.ps1
* Run script as 32-bit process on 64-bit clients:			No
* Enforce script signature check and run script silently:	No

### File (Don't use)
* Path:														%SystemDrive%\Users\Default\AppData\Local\Microsoft\Windows\Shell
* File or folder:											LayoutModification.xml
* Property:													File or folder exists
* Associated with a 32-bit app on 64-bit clients:			No


## Return codes
* 0 = Success
* 1 = Fail


## Other required Intune setup
### Device Enrollment
#### Enrollment status page
* Block device use until these required apps are installed if they are assigned to the user/device: Selected
    * .Ironstone Start Meny Layout Configurator