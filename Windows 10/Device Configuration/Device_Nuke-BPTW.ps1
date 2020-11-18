#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Cleans most common Ironstone scheduled tasks, file paths, and registry paths, both for system/ device context, and user context.
        
    .DESCRIPTION
        Cleans most common Ironstone scheduled tasks, file paths, and registry paths, both for system/ device context, and user context.
          * Must run as administrator.
          * Remember to change $WriteChanges to your liking, will not delete anything if set to $false

        Get content of latest log
            Get-Content -Path $([array](Get-ChildItem -Path ([string]('{0}\Temp\Nuke-BPTW-*.txt' -f ($env:windir))) | Sort-Object -Property 'LastWriteTime' -Descending))[0].'FullName' -Raw
#>



# Input parameters
[OutputType($null)]
Param ()



# Settings
## Script settings
$WriteChanges = [bool] $true

## PowerShell Preferences
$ConfirmPreference     = 'None'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'
$WarningPreference     = 'Continue'
$WhatIfPreference      = $false

## Help variables
$ScriptSuccess = $true



# Tests
## Make sure we're running in 64 bit
if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
    Throw 'ERROR: Not running as 64 bit process on 64 bit operating system.'
    Exit 1
}

## Make sure we're running as administrator
if (-not $([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Throw 'ERROR: Not running as admin.'
    Exit 1
}


# Logging
$LogPath = [string]('{0}\Temp\Nuke-BPTW-{1}.txt' -f ($env:windir,[datetime]::Now.ToString('yyyyMMdd-HHmmss')))
$null = Start-Transcript -Path $LogPath -Force



#region Try
#######################
#######################
Try {
#######################
#######################



# Scheduled tasks
## Introduce
Write-Output -InputObject '# Scheduled Tasks'

## Assets
$ScheduledTasks = [array](Get-ScheduledTask -TaskName '*' | Where-Object -Property 'Author' -Like 'Ironstone*')

## Remove
foreach ($ScheduledTask in $ScheduledTasks) {
    Write-Output -InputObject ('Found "{0}" by author "{1}"' -f ($ScheduledTask.'TaskName',$ScheduledTask.'Author'))
    if ($WriteChanges) {
        $null = Unregister-ScheduledTask -InputObject $ScheduledTask -Confirm:$false      
        Write-Output -InputObject ('{0}Success? {1}' -f ("`t",$?.ToString()))
    }
    else {
        Write-Output -InputObject ('{0}WriteChanges is $false' -f ("`t"))
    }
}



# File System Paths - System context
## Introduce
Write-Output -InputObject ('{0}# File system paths - System Context' -f ([System.Environment]::NewLine))

## Assets
$FileSystemPaths = [string[]](
    ('{0}\Ironstone*' -f (${env:ProgramFiles(x86)})),
    ('{0}\Ironstone*' -f ($env:ProgramW6432)),
    ('{0}\Ironstone*' -f ($env:ProgramData)),
    ('{0}\Ironstone*' -f ($env:APPDATA)),
    ('{0}\Ironstone*' -f ($env:LOCALAPPDATA)),
    ('{0}\Users\Public\Ironstone*' -f ($env:SystemDrive)),
    ('{0}\Users\Public\OfficeTemplates*' -f ($env:SystemDrive))
)

## Remove
foreach ($Path in $FileSystemPaths) {
    $FoundPaths = [string[]](Get-ChildItem -Path $Path -Recurse:$false -Directory -Force | Select-Object -ExpandProperty 'FullName')
    foreach ($FoundPath in $FoundPaths) {
        Write-Output -InputObject ('Found "{0}"' -f ($FoundPath))
        if ($WriteChanges) {
            $null = Remove-Item -Path $FoundPath -Recurse -Force
            Write-Output -InputObject ('{0}Success? {1}' -f ("`t",$?.ToString()))
        }
        else {
            Write-Output -InputObject ('{0}WriteChanges is $false' -f ("`t"))
        }
    }
}



# File System Paths - User context
## Introduce
Write-Output -InputObject ('{0}# File system paths - User Context' -f ([System.Environment]::NewLine))

## Assets
### Get by SIDs
$IntuneUsers = [string[]](
    [string[]](
        # Get by ProfileList in registry
        [array](
            Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Depth 0 | `
            Select-Object -ExpandProperty 'Name'
        ).ForEach{
            $_.Split('\')[-1]
        }.Where{
            $_ -like 'S-1-12-*'
        }.ForEach{
            [System.Security.Principal.SecurityIdentifier]::new($_).Translate([System.Security.Principal.NTAccount]).'Value'
        }.ForEach{
            $_.Split('\')[-1]
        } +
        # Get by folder names in C:\Users
        [array](
            Get-ChildItem -Path ('{0}\Users' -f ($env:SystemDrive)) -Recurse:$false
        ).'Name'.Where{
            [bool]$(
                Try {
                    [System.Security.Principal.NTAccount]::new([string]('AzureAD\{0}'-f$_)).Translate([System.Security.Principal.SecurityIdentifier]).'Value'
                    $?
                }
                Catch {
                    $false
                }
            )
        }
    ) | Sort-Object -Unique
)
### Plan B: Get by file system
if ($IntuneUsers.'Count' -eq 0 -or [bool[]]($IntuneUsers.ForEach{Test-Path -Path ('{0}\Users\{1}' -f ($env:SystemDrive,$_))}) -contains $false) {
    $IntuneUsers = [string[]](
        [array](
            Get-ChildItem -Path ('{0}\Users' -f ($env:SystemDrive)) -Recurse:$false -Directory -Force | Select-Object -ExpandProperty 'Name'
        ).Where{
            $_ -notin [string[]]('All Users','Default','Default User','Public')
        }
    )
}

## Remove
foreach ($UserName in $IntuneUsers) {
    # Find paths with "Ironstone*"
    $FoundPaths = [string[]](
        [array](
            [array](Get-ChildItem -Path ('{0}\Users\{1}\AppData\Local\Ironstone*' -f ($env:SystemDrive,$UserName)) -Force -Directory) +
            [array](Get-ChildItem -Path ('{0}\Users\{1}\AppData\LocalLow\Ironstone*' -f ($env:SystemDrive,$UserName)) -Force -Directory) +
            [array](Get-ChildItem -Path ('{0}\Users\{1}\AppData\Roaming\Ironstone*' -f ($env:SystemDrive,$UserName)) -Force -Directory)
        ).'FullName'.Where{$_ -notlike '*.hostedrmm.*'}
    )

    # Remove
    foreach ($FoundPath in $FoundPaths) {
        Write-Output -InputObject ('Found "{0}"' -f ($FoundPath))
        if ($WriteChanges) {
            $null = Remove-Item -Path $FoundPath -Recurse -Force
            Write-Output -InputObject ('{0}Success? {1}' -f ("`t",$?.ToString()))
        }
        else {
            Write-Output -InputObject ('{0}WriteChanges is $false' -f ("`t"))
        }
    }
}



# Registry - System Context
## Introduce
Write-Output -InputObject ('{0}# Registry - System Context' -f ([System.Environment]::NewLine))

## Assets
$RegistryPaths = [string[]](
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Ironstone*',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Ironstone*'
)

## Remove
foreach ($RegistryPath in $RegistryPaths) {
    $FoundPaths = [string[]](Get-ChildItem -Path $RegistryPath -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'PSPath')
    foreach ($FoundPath in $FoundPaths) {
        Write-Output -InputObject ('Found "{0}"' -f ($FoundPath))
        if ($WriteChanges) {
            $null = Remove-Item -Path $FoundPath -Recurse -Force
            Write-Output -InputObject ('{0}Success? {1}' -f ("`t",$?.ToString()))
        }
        else {
            Write-Output -InputObject ('{0}WriteChanges is $false' -f ("`t"))
        }
    }
}



# Registry - User Context
## Introduce
Write-Output -InputObject ('{0}# Registry - User Context' -f ([System.Environment]::NewLine))

## Assets
$RegistryPaths = [string[]](
    'Registry::HKEY_USERS\{0}\SOFTWARE\Ironstone*',
    'Registry::HKEY_USERS\{0}\SOFTWARE\WOW6432Node\Ironstone*'
)

## Load User Profiles NTUSER.DAT (Registry) that is not available from current context
Write-Output -InputObject '## Load registry hive for Intune users'
$RegistryLoadedProfiles = [string[]]$()
$PathProfileList = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList')
$SIDsProfileList = [string[]](Get-ChildItem -Path $PathProfileList -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object -Process {$_.Split('\')[-1]} | Where-Object -FilterScript {$_ -like 'S-1-12-*'})
foreach ($SID in $SIDsProfileList) {
    if (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID)) -ErrorAction 'SilentlyContinue') {
        Write-Output -InputObject ('Hive (NTUSER.DAT) for SID "{0}" is already loaded.' -f ($SID))
    }
    else {
        Write-Output -InputObject ('Hive (NTUSER.DAT) for SID "{0}" is not loaded into registry.' -f ($SID))
                    
        # Get User Directory
        $PathUserDirectory = [string]$(Get-ItemProperty -Path ('{0}\{1}' -f ($PathProfileList,$SID)) -Name 'ProfileImagePath' | Select-Object -ExpandProperty 'ProfileImagePath')
        if ([string]::IsNullOrEmpty($PathUserDirectory)) {
            Throw ('ERROR: No User Directory was found for user with SID "{0}".' -f ($SID))
        }

        # Get User Registry File, NTUSER.DAT
        $PathFileUserRegistry = ('{0}\NTUSER.DAT' -f ($PathUserDirectory))
        if (-not(Test-Path -Path $PathFileUserRegistry)) {
            $ScriptSuccess = $false
            Throw ('ERROR: "{0}" does not exist.' -f ($PathFileUserRegistry))
        }

        # Load NTUSER.DAT
        $null = Start-Process -FilePath ('{0}\reg.exe' -f ([string]([system.environment]::SystemDirectory))) -ArgumentList ('LOAD "HKEY_USERS\{0}" "{1}"' -f ($SID,$PathFileUserRegistry)) -WindowStyle 'Hidden' -Wait
        if (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID))) {
            Write-Output -InputObject ('{0}Successfully loaded "{1}".' -f ("`t",$PathFileUserRegistry))
            $RegistryLoadedProfiles += [string[]]($SID)
        }
        else {
            $ScriptSuccess = $false
            Throw ('ERROR: Failed to load registry hive for SID "{0}", NTUSER.DAT location "{1}".' -f ($SID,$PathFileUserRegistry))
        }
    }
}

## Remove
Write-Output -InputObject '## Remove'
foreach ($SID in $SIDsProfileList) {
    foreach ($RegistryPath in $RegistryPaths) {
        $FoundPaths = [string[]](Get-ChildItem -Path ($RegistryPath -f ($SID)) -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'PSPath')
        foreach ($FoundPath in $FoundPaths) {
            Write-Output -InputObject ('Found "{0}"' -f ($FoundPath))
            if ($WriteChanges) {
                $null = Remove-Item -Path $FoundPath -Recurse -Force
                Write-Output -InputObject ('{0}Success? {1}' -f ("`t",$?.ToString()))
            }
            else {
                Write-Output -InputObject ('{0}WriteChanges is $false' -f ("`t"))
            }
        }
    }
}

## Unload Users' Registry Profiles (NTUSER.DAT) if any were loaded
Write-Output -InputObject '## Unload hive for Intune users'
if ($RegistryLoadedProfiles.Where{-not([string]::IsNullOrEmpty($_))}.'Count' -gt 0) {
    # Close Regedit.exe if running, can't unload hives otherwise
    $null = Get-Process -Name 'regedit' -ErrorAction 'SilentlyContinue' | ForEach-Object -Process {Stop-Process -InputObject $_ -ErrorAction 'SilentlyContinue'}

    # Get all logged in users
    $SIDsLoggedInUsers = [string[]]$(([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' -Unique | ForEach-Object -Process {Try{[System.Security.Principal.NTAccount]::new(($_)).Translate([System.Security.Principal.SecurityIdentifier]).'Value'}Catch{}} | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))}),[string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value')) | Select-Object -Unique)

    foreach ($SID in $RegistryLoadedProfiles) {
        # If SID is found in $SIDsLoggedInUsers - Don't Unload Hive
        if ([bool]$(([string[]]@($SIDsLoggedInUsers | ForEach-Object -Process {$_.Trim().ToUpper()})).Contains($SID.Trim().ToUpper()))) {
            Write-Output -InputObject ('User with SID "{0}" is currently logged in, will not unload registry hive.' -f ($SID))
        }
        # If SID is not found in $SIDsLoggedInUsers - Unload Hive
        else {
            $PathUserHive = [string]('HKEY_USERS\{0}' -f ($SID))
            $null = Start-Process -FilePath ('{0}\reg.exe' -f ([string]$([system.environment]::SystemDirectory))) -ArgumentList ('UNLOAD "{0}"' -f ($PathUserHive)) -WindowStyle 'Hidden' -Wait

            # Check success
            if (Test-Path -Path ('Registry::{0}' -f ($PathUserHive)) -ErrorAction 'SilentlyContinue') {
                $ScriptSuccess = [bool] $false
                Write-Output -InputObject ('ERROR: Failed to unload user registry hive "{0}".' -f ($PathUserHive)) -ErrorAction 'Continue'
            }
            else {
                Write-Output -InputObject ('Successfully unloaded user registry hive "{0}".' -f ($PathUserHive))
            }
        }
    }
}
else {
    Write-Output -InputObject 'No hives where loaded.'
}



#######################
#######################
}
#######################
#######################
#endregion Try



Catch {
    # Set script success to false
    $ScriptSuccess = [bool] $false
    
    # Construct error message
    ## Generic content
    $ErrorMessage = [string]$('{0}Catched error:' -f ([System.Environment]::NewLine))    
    ## Last exit code if any
    if (-not[string]::IsNullOrEmpty($LASTEXITCODE)) {
        $ErrorMessage += ('{0}# Last exit code ($LASTEXITCODE):{0}{1}' -f ([System.Environment]::NewLine,$LASTEXITCODE))
    }
    ## Exception
    $ErrorMessage += [string]$('{0}# Exception:{0}{1}' -f ([System.Environment]::NewLine,$_.'Exception'))
    ## Dynamically add info to the error message
    foreach ($ParentProperty in [string[]]$($_.GetType().GetProperties().'Name')) {
        if ($_.$ParentProperty) {
            $ErrorMessage += ('{0}# {1}:' -f ([System.Environment]::NewLine,$ParentProperty))
            foreach ($ChildProperty in [string[]]$($_.$ParentProperty.GetType().GetProperties().'Name')) {
                ### Build ErrorValue
                $ErrorValue = [string]::Empty
                if ($_.$ParentProperty.$ChildProperty -is [System.Collections.IDictionary]) {
                    foreach ($Name in [string[]]$($_.$ParentProperty.$ChildProperty.GetEnumerator().'Name')) {
                        if (-not[string]::IsNullOrEmpty([string]$($_.$ParentProperty.$ChildProperty.$Name))) {
                            $ErrorValue += ('{0} = {1}{2}' -f ($Name,[string]$($_.$ParentProperty.$ChildProperty.$Name),[System.Environment]::NewLine))
                        }
                    }
                }
                else {
                    $ErrorValue = [string]$($_.$ParentProperty.$ChildProperty)
                }
                if (-not[string]::IsNullOrEmpty($ErrorValue)) {
                    $ErrorMessage += ('{0}## {1}\{2}:{0}{3}' -f ([System.Environment]::NewLine,$ParentProperty,$ChildProperty,$ErrorValue.Trim()))
                }
            }
        }
    }
    # Write Error Message
    Write-Error -Message $ErrorMessage -ErrorAction 'Continue'
}



Finally {
    $null = Stop-Transcript
}



# Exit
if ($ScriptSuccess) {    
    Write-Output -InputObject ('{0}# Done' -f ([System.Environment]::NewLine))
    Exit 0
}
else {
    Throw 'Script did not succeed.'
    Exit 1
}
