#Require -RunAsAdministrator
<#
    .SYNOPSIS
        Sets screen saver to trigger lock screen/ require password to unlock.
#>


# PowerShell preferences
$DebugPreference       = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'
$ConfirmPreference     = 'None'
$InformationPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'


# Get SID of all Intune users
$IntuneSIDs = [string[]](
    $(
        [string[]](
            Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Recurse:$false
        ).'Name'
    ).ForEach{
        $_.Split('\')[-1]
    }.Where{
        $_ -like 'S-1-12-*'
    }
)

# Get SID of logged in Intune users
$LoggedOnIntuneSIDs = [string[]](
    $(
        [string[]](
            (Get-ChildItem -Path 'Registry::HKEY_USERS').'Name'
        )
    ).ForEach{
        $_.Split('\')[-1]
    }.Where{
        $_ -in $IntuneSIDs
    }
)


# Get SID of not logged in Intune users
$NotLoggedOnIntuneSIDs = [string[]]($IntuneSIDs.Where{$_ -notin $LoggedOnIntuneSIDs})


# Load registry hive for not logged in Intune users
$NotLoggedOnIntuneSIDs.ForEach{
    $ProfilePath = [string](
        '{0}\NTUSER.DAT' -f (
            Get-ItemPropertyValue -Path ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\{0}' -f $_) -Name 'ProfileImagePath'
        )
    )
    $null = cmd /c ('{0}\reg.exe'-f[system.environment]::SystemDirectory) 'LOAD' ('"HKEY_USERS\{0}"' -f $_) $ProfilePath
}


# Set registry values for Intune users
$IntuneSIDs.ForEach{
    $Path = [string] 'Registry::HKEY_USERS\{0}\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop' -f $_

    if (-not(Test-Path -Path $Path)) {
        $null = New-Item -Path $Path -ItemType 'Directory' -Force
    }

    $null = Set-ItemProperty -Path $Path -Name 'ScreenSaverIsSecure' -Value 1 -Type 'String' -Force
}


# Unload registry hive for not logged in Intune users
$NotLoggedOnIntuneSIDs.ForEach{
    $null = cmd /c ('{0}\reg.exe'-f[system.environment]::SystemDirectory) 'UNLOAD' ('"HKEY_USERS\{0}"' -f $_)
}
