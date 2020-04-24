# Install required modules (requires running as administrator)
Install-Module -Name 'IntuneBackupAndRestore' -Scope 'AllUsers' -Force # https://www.powershellgallery.com/packages/IntuneBackupAndRestore
Install-Module -Name 'MSGraphFunctions' -Scope 'AllUsers' -Force       # https://www.powershellgallery.com/packages/MSGraphFunctions


# Import modules
Import-Module -Name 'IntuneBackupAndRestore' -Force
Import-Module -Name 'MSGraphFunctions' -Force


# Connect (no need to disconnect)
Connect-Graph


# Export all config to a folder on you desktop
Start-IntuneBackup -Path ([string]$('{0}\Intune Backup {1}' -f ([System.Environment]::GetFolderPath('Desktop'),[datetime]::Now.ToString('yyyyMMdd-HHmmss'))))
