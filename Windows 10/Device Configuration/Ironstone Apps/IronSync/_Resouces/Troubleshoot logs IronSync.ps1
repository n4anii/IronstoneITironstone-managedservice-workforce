# Troubleshoot - Logs
## IronSync main
### ClientApps (new log location)
Get-Content -Raw -Path $(Get-ChildItem -Path ('{0}\IronstoneIT\Logs\ClientApps' -f ($env:ProgramData)) -File -Filter '*device*ironsync*.txt' | Sort-Object -Property 'LastWriteTime' -Descending)[0].'FullName'

### DeviceConfiguration (old log location)
Get-Content -Raw -Path $(Get-ChildItem -Path ('{0}\IronstoneIT\Logs\DeviceConfiguration' -f ($env:ProgramData)) -File -Filter '*device*ironsync*.txt' | Sort-Object -Property 'LastWriteTime' -Descending)[0].'FullName'

## IronSync Teams background installer
Get-Content -Raw -Path $(Get-ChildItem -Path ('{0}\IronstoneIT\Logs\ClientApps' -f ($env:ProgramData)) -File -Filter 'User_Install-TeamsBackgroundsFromIronSync-*.txt' | Sort-Object -Property 'LastWriteTime' -Descending)[0].'FullName'




# Troubleshoot - SIDs
## Get SIDs of users
### Way 1
(Get-Process -Name 'explorer' -IncludeUserName).'UserName' | Sort-Object -Unique
### Way 2
(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').'Name'.Where{$_.Split('\')[-1] -notlike 'S-1-5-*'}.ForEach{
    [PSCustomObject]@{
        'SID'      = [string] $_.Split('\')[-1]
        'UserPath' = [string](Get-ItemPropertyValue -Path ('Registry::{0}'-f$_) -Name 'ProfileImagePath')
        'UserName' = [string] [System.Security.Principal.SecurityIdentifier]::new($_.Split('\')[-1]).Translate([System.Security.Principal.NTAccount]).'Value'
    }
} | Format-List




# Troubleshoot - Other
## Restart IntuneManagementExtension
[bool]$(
    Try {
        $Service = Get-Service -Name 'IntuneManagementExtension'
        if ($?) {
            $null = Stop-Service -Name $Service.'Name'
            $null = Start-Sleep -Seconds 2
            $null = Start-Service -InputObject $Service
            $?
        }
        else {
            $false
        }
    }
    Catch {
        $false
    }
)




# All files
## ProgramData \ ClientApps
Get-ChildItem -Path ('{0}\IronstoneIT\Logs\ClientApps' -f ($env:ProgramData)) -File | Sort-Object -Property 'LastWriteTime' -Descending

## ProgramData \ DeviceConfiguration
Get-ChildItem -Path ('{0}\IronstoneIT\Logs\DeviceConfiguration' -f ($env:ProgramData)) -File | Sort-Object -Property 'LastWriteTime' -Descending

## ProgramFiles \ IronstoneIT \ IronSync
Get-ChildItem -Path ('{0}\IronstoneIT\IronSync\Logs' -f ($env:ProgramW6432)) -File | Sort-Object -Property 'LastWriteTime' -Descending

## Public \ IronSync
Get-ChildItem -Path ('{0}\IronSync' -f ($env:PUBLIC)) -File -Recurse | Sort-Object -Property 'FullName' | Format-Table -Property 'Name','LastWriteTime','Length','FullName'

## Teams backgrounds
### Using C:\Users
Get-ChildItem -Path ('{0}\AppData\Roaming\Microsoft\Teams\Backgrounds\Uploads' -f ($(Get-ChildItem -Path ('{0}\Users' -f ($env:SystemDrive)) -Directory | Sort-Object -Property 'CreationTime' -Descending)[0].'FullName'))
### Using explorer.exe
Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\Microsoft\Teams\Backgrounds\Uploads' -f (
    $env:SystemDrive,
    $($(Get-Process -Name 'explorer' -IncludeUserName).'UserName' | Sort-Object -Unique).Split('\')[-1]
))
### Using registry
Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\Microsoft\Teams\Backgrounds\Uploads' -f (
    $env:SystemDrive,
    [System.Security.Principal.SecurityIdentifier]::new($(Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').'Name'.ForEach{$_.Split('\')[-1]}.Where{$_ -like 'S-1-12-*'}).Translate([System.Security.Principal.NTAccount]).'Value'.Split('\')[-1]
))
