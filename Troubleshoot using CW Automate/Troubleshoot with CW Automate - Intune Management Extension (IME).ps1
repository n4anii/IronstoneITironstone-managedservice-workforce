<#
    .SYNOPSIS
        PowerShell to troubleshoot Intune Management Extension and enrollment + deployment in general.
#>



# IME is running
## PowerShell
Get-Service -Name '*intune*' | Format-List

## WMI
### Running info
Get-WmiObject -Class 'win32_service' | Where-Object -Property 'Name' -Like '*intune*' | Select-Object -Property 'Name','DisplayName','State','PathName' | Format-List
### Version info
Get-Item -Path ((Get-WmiObject -Class 'win32_service' | Where-Object -Property 'Name' -Like '*intune*').'PathName').Replace('"','') | Select-Object -Property 'Name','FullName',@{'Name'='Version';'Expression'={[string]$_.'VersionInfo'.'FileVersion'}} | Format-List



# IME is installed
## File system
Get-ChildItem -Path ('{0}\Microsoft Intune Management Extension'-f${env:ProgramFiles(x86)}) -File -Filter '*.exe'

## Registry
$([PSCustomObject[]](
    $(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall').'Name'.ForEach{
        [PSCustomObject](Get-ItemProperty -Path ('Registry::{0}'-f$_))
    }
)).Where{$_.'DisplayName' -eq 'Microsoft Intune Management Extension'}



# IME logs
## File system
### Path
'%ProgramData%\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'
### PowerShell
#### All
Get-Content -Path ('{0}\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'-f$env:ProgramData)
#### 100 last lines (newest)
(Get-Content -Path ('{0}\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'-f$env:ProgramData)) -split [System.Environment]::NewLine | Select-Object -Last 100
#### 100 first lines (oldest)
(Get-Content -Path ('{0}\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log'-f$env:ProgramData)) -split [System.Environment]::NewLine | Select-Object -First 100



# MDM logs
## File system
### Path
'%SystemRoot%\System32\config\systemprofile\AppData\Local\mdm'
### PowerShell
##### All
Get-ChildItem -Path ('{0}\System32\config\systemprofile\AppData\Local\mdm'-f$env:SystemRoot) -File -Force | Select-Object -Property 'Name','LastWriteTime','Length' | Format-Table -AutoSize
##### IME MSI Install Log
Get-Content -Path ('{0}\System32\config\systemprofile\AppData\Local\mdm\{1}.log'-f$env:SystemRoot,'{25212568-E605-43D5-9AA2-7AE8DB2C3D09}')

## Registry
### MSI
#### Path
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement\<SID>\MSI\<SOME_GUID>'
#### PowerShell
$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EnterpriseDesktopAppManagement').'Name'.Where{$_ -like '*\S-1-12-*'}.ForEach{Get-ChildItem -Path ('Registry::{0}\MSI'-f$_)}
### Policies
#### Path
'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies'
#### PowerShell
##### 1
Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies' | Select-Object -ExpandProperty 'Name'
##### 2
$(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Policies').'Name'.ForEach{Get-ChildItem -Path ('Registry::{0}'-f$_)}
