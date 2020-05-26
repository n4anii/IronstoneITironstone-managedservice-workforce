﻿#Requires -RunAsAdministrator
<#
    .NAME    
        Device_Install-IronSync.ps1

    .SYNOPSIS
        Syncs Office Templates and other files from Azure Blog Storage, and make them available in Word, PowerPoint and Excel.

    .DESCRIPTION
        Syncs Office Templates and other files from Azure Blog Storage, and make them available in Word, PowerPoint and Excel.
        You need to run this script in the DEVICE context in Intune.

    .NOTES
        Author:   Olav Rønnestad Birkeland @ Ironstone IT.
        Modified: 200526

    .EXAMPLE
        # From PowerShell ISE      
        & $psISE.'CurrentFile'.'FullPath' -CustomerAzureStorageAccountName 'istnoebptwironsync' -CustomerAzureStorageAccountBlobName 'files' -CustomerAzureStorageAccountSASToken '?sv=2019-10-10&ss=b&srt=co&sp=rl&se=2025-05-19T20:04:21Z&st=2020-05-19T12:04:21Z&spr=https&sig=zwP7mh8YBUvnWq%2FvSQcM3fjD5fALRn4KD2obSE1fm4c%3D'        

    .EXAMPLE
        # From CMD
        "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-IronSync.ps1' -CustomerAzureStorageAccountName 'istnoebptwironsync' -CustomerAzureStorageAccountBlobName 'files' -CustomerAzureStorageAccountSASToken '?sv=2019-10-10&ss=b&srt=co&sp=rl&se=2025-05-19T20:04:21Z&st=2020-05-19T12:04:21Z&spr=https&sig=zwP7mh8YBUvnWq%2FvSQcM3fjD5fALRn4KD2obSE1fm4c%3D'"

    .EXAMPLE
        # From Intune
        "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy "Bypass" -NoLogo -NonInteractive -NoProfile -WindowStyle "Hidden" -Command "& '.\Device_Install-IronSync.ps1' -CustomerAzureStorageAccountName 'istnoebptwironsync' -CustomerAzureStorageAccountBlobName 'files' -CustomerAzureStorageAccountSASToken '?sv=2019-10-10&ss=b&srt=co&sp=rl&se=2025-05-19T20:04:21Z&st=2020-05-19T12:04:21Z&spr=https&sig=zwP7mh8YBUvnWq%2FvSQcM3fjD5fALRn4KD2obSE1fm4c%3D'; exit $LASTEXITCODE"
#>



# Input parameters
[OutputType($null)]
Param (
    # Mandatory
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $CustomerAzureStorageAccountName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $CustomerAzureStorageAccountBlobName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $CustomerAzureStorageAccountSASToken,

    # Optional
    [Parameter(Mandatory = $false)]
    [switch] $ReadOnly
)



# Version
$Version = [string] '200525'



# Script Settings
$DeviceContext         = [bool] $true
$WriteToHKCUFromSystem = [bool] $true



################################################################################################
#region    Don't Touch This
################################################################################################
# PowerShell Preferences
## Output encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
## Output streams
$DebugPreference       = 'SilentlyContinue'
$InformationPreference = 'Continue'
$VerbosePreference     = 'Continue'
$WarningPreference     = 'Continue'
## Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'
## Behavior
$ErrorActionPreference = 'Stop'
$WhatIfPreference      = $false

# If OS is 64 bit and PowerShell got launched as x86, relaunch as x64
if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
    if (-not([string]::IsNullOrEmpty($MyInvocation.'Line'))) {
        & ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile $MyInvocation.'Line'
    }
    else {
        & ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($MyInvocation.'InvocationName')) $args
    }
    exit $LASTEXITCODE
}

# Dynamic Variables - Process & Environment
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ScriptContext' -Value ([string]$(if($DeviceContext){'Device'}else{'User'}))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ScriptNameFull' -Value ([string]($([string[]]($psISE.'CurrentFile'.'DisplayName',$MyInvocation.'MyCommand'.'Name')).Where{-not[string]::IsNullOrEmpty($_)}[0].Replace('.ps1','')))
if ($Script:ScriptNameFull -notlike ('{0}*' -f ($Script:ScriptContext))) {
    $null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ScriptNameFull' -Value ([string]('{0}_{1}' -f ($Script:ScriptContext,$Script:ScriptNameFull)))
}
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ScriptNameVerb' -Value ([string]$ScriptNameFull.Split('-')[0])
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ScriptNameNoun' -Value ([string]$ScriptNameFull.Split('-')[-1])
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureProcess' -Value ([string]$(if([System.Environment]::Is64BitProcess){'64'}else{'32'}))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureOS' -Value ([string]$(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'}))

# Dynamic Variables - User
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserNameRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name'))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrSIDRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value'))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsAdmin'  -Value ([bool]$(([System.Security.Principal.WindowsPrincipal]$([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsSystem' -Value ([bool]$($Script:StrSIDRunningAs -like ([string]$('S-1-5-18'))))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsCorrectUser' -Value ([bool]$(if($Script:DeviceContext -and ($Script:BoolIsSystem -or ($psISE -and $Script:BoolIsAdmin))){$true}elseif(-not $DeviceContext -and -not $Script:BoolIsSystem){$true}else{$false}))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolWriteToHKCUFromSystem' -Value ([bool]$(if($DeviceContext -and $WriteToHKCUFromSystem){$true}else{$false}))

# Dynamic Variables - Logging
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'Timestamp' -Value ([string]([datetime]::Now.ToString('yyMMdd-HHmmssffff')))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathDirLog' -Value ([string]('{0}\IronstoneIT\Logs\DeviceConfiguration' -f ($env:ProgramData)))
$null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathFileLog' -Value ([string]('{0}\{1}-{2}bit-{3}.txt' -f ($Script:PathDirLog,$Script:ScriptNameFull,$Script:StrArchitectureProcess,$Script:Timestamp)))
$null = Set-Variable -Option 'None' -Scope 'Script' -Force -Name 'ScriptSuccess' -Value ([bool]$($true))

# Start Transcript
if (-not [System.IO.Directory]::Exists($Script:PathDirLog)) {
    $null = [System.IO.Directory]::CreateDirectory($Script:PathDirLog)
}
$null = Start-Transcript -Path $Script:PathFileLog -Force -ErrorAction 'Stop'


# Wrap in Try/Catch, so we can always end the transcript
Try {
    # Output User Info, Exit if not $BoolIsCorrectUser
    Write-Output -InputObject ('Running as user "{0}" ({1}). Has admin privileges? {2}. $DeviceContext? {3}. Running as correct user? {4}.' -f ($Script:StrUserNameRunningAs,$Script:StrSIDRunningAs,$Script:BoolIsAdmin.ToString(),$Script:DeviceContext.ToString(),$Script:BoolIsCorrectUser.ToString()))
    if (-not $Script:BoolIsCorrectUser) {
        Throw 'Not running as correct user!'
        Break
    }


    # Output Process and OS Architecture Info
    Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($Script:StrArchitectureProcess,$Script:StrArchitectureOS))

    
    #region    Get SID and "Domain\Username" for Intune User only if $WriteToHKCUFromSystem
    # If running in Device Context as "NT Authority\System"
    if ($DeviceContext -and $Script:BoolIsCorrectUser -and $BoolWriteToHKCUFromSystem) {
        # Help function
        function Test-ValidIntuneSID {
            [OutputType([bool])]
            [Parameter(Mandatory=$true)]
            Param([string]$SID)

            -not [string]::IsNullOrEmpty($SID) -and
            $SID.'Length' -in [byte[]]$(40 .. 80) -and
            (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID)) -ErrorAction 'SilentlyContinue')
        }
        # Help variables
        $Script:RegistryLoadedProfiles = [string[]]$()
        $Local:SID                     = [string]::Empty            


        # Load User Profiles NTUSER.DAT (Registry) that is not available from current context
        $PathProfileList = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList')
        $SIDsProfileList = [string[]]($([string[]](Get-ChildItem -Path $PathProfileList -Recurse:$false).'Name').ForEach{$_.Split('\')[-1]}.Where{$_ -like 'S-1-12-*'})
        foreach ($SID in $SIDsProfileList) {
            if (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID)) -ErrorAction 'SilentlyContinue') {
                Write-Output -InputObject ('User with SID "{0}" is already logged in and/or NTUSER.DAT is loaded.' -f ($SID))
            }
            else {
                Write-Output -InputObject ('User with SID "{0}" is not logged in, thus NTUSER.DAT is not loaded into registry.' -f ($SID))
                    
                # Get User Directory
                $PathUserDirectory = [string]$(Get-ItemProperty -Path ('{0}\{1}' -f ($PathProfileList,$SID)) -Name 'ProfileImagePath' | Select-Object -ExpandProperty 'ProfileImagePath')
                if ([string]::IsNullOrEmpty($PathUserDirectory)) {
                    Throw ('ERROR: No User Directory was found for user with SID "{0}".' -f ($SID))
                }

                # Get User Registry File, NTUSER.DAT
                $PathFileUserRegistry = ('{0}\NTUSER.DAT' -f ($PathUserDirectory))
                if (-not(Test-Path -Path $PathFileUserRegistry)) {
                    Throw ('ERROR: "{0}" does not exist.' -f ($PathFileUserRegistry))
                }

                # Load NTUSER.DAT
                $null = Start-Process -FilePath ('{0}\reg.exe' -f ([string]([system.environment]::SystemDirectory))) -ArgumentList ('LOAD "HKEY_USERS\{0}" "{1}"' -f ($SID,$PathFileUserRegistry)) -WindowStyle 'Hidden' -Wait
                if (Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($SID))) {
                    Write-Output -InputObject ('{0}Successfully loaded "{1}".' -f ("`t",$PathFileUserRegistry))
                    $RegistryLoadedProfiles += @($SID)
                }
                else {
                    Throw ('ERROR: Failed to load registry hive for SID "{0}", NTUSER.DAT location "{1}".' -f ($SID,$PathFileUserRegistry))
                }
            }
        }


        # Get Intune User Information from Registry
        $IntuneUser = [PSCustomObject](
            [PSCustomObject[]]@(
                foreach ($x in [string[]]($([string[]](Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue').'Name').ForEach{$_.Split('\')[-1]}.Where{$_ -like 'S-1-12-*' -and $(Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($_)))})) {
                    [PSCustomObject]@{
                        'IntuneUserSID'  = [string]($(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'IntuneUserSID' -ErrorAction 'SilentlyContinue').'IntuneUserSID')
                        'IntuneUserName' = [string]($(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'IntuneUserName' -ErrorAction 'SilentlyContinue').'IntuneUserName')
                        'DateSet'        = [datetime]$(
                            Try{
                                [datetime]($(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'DateSet').'DateSet')
                            }
                            Catch{
                                [datetime]::MinValue
                            }
                        )
                    }
                }
            ).Where{
                -not ([string]::IsNullOrEmpty($_.'IntuneUserSID') -or [string]::IsNullOrEmpty($_.'IntuneUserName'))
            } | Sort-Object -Property 'DateSet' -Descending:$false | Select-Object -Last 1
        )


        # Get Intune User SID
        $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserSID' -Value (
            [string]$(
                # Initiate variable
                $Local:SID = [string]::Empty                                            
                    
                # If running from PowerShell ISE
                if ($psISE) {
                    $Local:SID = $Script:StrSIDRunningAs
                }
                    
                # Try by registry values in HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo
                if (-not (Test-ValidIntuneSID -SID $Local:SID) -and -not [string]::IsNullOrEmpty([string]($IntuneUser | Select-Object -ExpandProperty 'IntuneUserSID'))) {
                    $Local:SID = [string]($IntuneUser | Select-Object -ExpandProperty 'IntuneUserSID')
                }

                # If no valid SID yet, try Registry::HKEY_USERS
                if (-not (Test-ValidIntuneSID -SID $Local:SID)) {
                    # Get all potential SIDs from Registry::HKEY_USERS
                    $Local:SIDsFromRegistryAll = [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -like 'S-1-12-*' -and $_ -notlike '*_Classes' -and $Local:LengthInterval.Contains([byte]$_.'Length')})
                    $Local:SID = [string]$(
                        # If none where found - Return emtpy string: Finding SID by registry will not be possible
                        if (@($Local:SIDsFromRegistryAll).'Count' -le 0) {
                            [string]::Empty
                        }
                        # If only one where found - Return it
                        elseif (@($Local:SIDsFromRegistryAll).'Count' -eq 1) {
                            [string]([string[]]@($Local:SIDsFromRegistryAll | Select-Object -First 1))
                        }
                        # If multiple where found - Try to filter out unwanted SIDs
                        else {
                            # Try to get all where IronstoneIT folder exist withing HKU (HKCU) registry
                            $Local:SIDs = [string[]]@($([string[]]@($Local:SIDsFromRegistryAll)).Where{Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT' -f ($_))})
                            # If none or more than 1 where found - Try getting only SIDs with AAD joined info in HKU (HKCU) registry
                            if (@($Local:SIDs).'Count' -le 0 -or @($Local:SIDs).'Count' -ge 2) {
                                $Local:SIDs = [string[]]@($([string[]]@($Local:SIDsFromRegistryAll)).Where{Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_))})
                            }
                            # If none or more than 1 where found - Try matching Tenant ID for AAD joined HKLM with Tenant ID for AAD joined HKU (HKCU)
                            if (@($Local:SIDs).'Count' -le 0 -or @($Local:SIDs).'Count' -ge 2) {
                                if (-not([string]::IsNullOrEmpty(($Local:TenantGUIDFromHKLM = [string]$($x='Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'; Get-ItemProperty -Path ('{0}\{1}' -f ($x,[string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantId'))))) {
                                    $Local:SIDs = [string[]]@($([string[]]@($Local:SIDsFromRegistryAll)).Where{$Local:TenantGUIDFromHKLM -eq ([string]$($x=[string]('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_)); Get-ItemProperty -Path ('{0}\{1}' -f ($x,([string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]})))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantDomain'))})
                                }
                            }
                            if(@($Local:SIDs).'Count' -eq 1){
                                [string]([string[]]@($Local:SIDs | Select-Object -First 1))
                            }
                            else{
                                [string]::Empty
                            }
                        }
                    )
                }

                # If no valid SID yet, try by running process "Explorer"
                if (-not (Test-ValidIntuneSID -SID $Local:SID)) {
                    $Local:SID = [string]$(
                        $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.'ReturnValue' -eq 0 -and $Owner.'Domain' -notlike 'nt *' -and $Owner.'Domain' -notlike 'nt-*'){('{0}\{1}' -f ($Owner.'Domain',$Owner.'User'))})}) | Select-Object -Unique -First 1)
                        if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                            $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
                        }
                        if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                            [string]::Empty
                        }
                        else {
                            Try{
                                $Local:SID = [string]$([System.Security.Principal.NTAccount]::new($Local:UN).Translate([System.Security.Principal.SecurityIdentifier]).'Value')
                                if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.'Length'))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                                    [string]::Empty
                                }
                                else {
                                    $Local:SID
                                }
                            }
                            catch{
                                [string]::Empty
                            }
                        }
                    )
                }
                
                # If no valid SID yet, throw error
                if (-not (Test-ValidIntuneSID -SID $Local:SID)) {
                    Throw 'ERROR: Did not manage to get Intune user SID from SYSTEM context'
                }

                # If valid SID, return it
                else {
                    $Local:SID
                }
            )
        )
        

        # Get Intune User Domain\UserName
        $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserName' -Value (
            [string]$(
                # Initiate variable
                $Local:UN = [string]::Empty

                # If running from PowerShell ISE
                if ($psISE) {
                    $Local:UN = $Script:StrUserNameRunningAs
                }

                # Try by registry values in HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3 -and -not([string]::IsNullOrEmpty($IntuneUser.'IntuneUserName'))) {
                    $Local:UN = [string]($IntuneUser.'IntuneUserName')
                }
                
                # If no valid UN yet, try by convert $Script:StrIntuneUserSID to "Domain\Username"
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3 -and (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID)))) {
                    $Local:UN = [string]$(Try{[System.Security.Principal.SecurityIdentifier]::new($Script:StrIntuneUserSID).Translate([System.Security.Principal.NTAccount]).'Value'}Catch{[string]::Empty})
                }

                # If no valid UN yet, try by Registry::HKEY_USERS\$Script:StrIntuneUserSID\Volatile Environment
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3-and (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID)))) {
                    $Local:UN = [string]$(Try{$Local:x = Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrIntuneUserSID)) -Name 'USERDOMAIN','USERNAME' -ErrorAction 'SilentlyContinue';('{0}\{1}' -f ([string]($Local:x | Select-Object -ExpandProperty 'USERDOMAIN'),[string]($Local:x | Select-Object -ExpandProperty 'USERNAME')))}Catch{[string]::Empty})
                }
                
                # If no valid UN yet, try by running process Explorer.exe - Method 1
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                    $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object -Process {$($Owner = $_.GetOwner();if($Owner.'ReturnValue' -eq 0 -and $Owner.'Domain' -notlike 'nt *' -and $Owner.'Domain' -notlike 'nt-*'){('{0}\{1}' -f ($Owner.'Domain',$Owner.'User'))})}) | Select-Object -Unique -First 1)
                }
                
                # If no valid UN yet, try by running process Explorer.exe - Method 2
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                    $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object -FilterScript {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
                }                   

                # If no valid UN yet, throw Error
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                    Throw 'ERROR: Did not manage to get "Domain"\"UserName" for Intune User.'
                }

                # If valid UN, return it
                else {
                    $Local:UN
                }
            )
        )
    }
        

    # If running in User Context / Not running as "NT Authority\System"
    elseif (-not $DeviceContext -and -not $Script:BoolIsSystem) {
        $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserSID' -Value ([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value'))
        $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserName' -Value ([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name'))
        $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserPrincipalName' -Value ([string]$(Try{$x=&('{0}\whoami.exe'-f([System.Environment]::GetFolderPath('System')))'/upn';if($?){$x}else{''}}Catch{''}))

        #region    Write SID, UserName and UserPrincipalName to HKCU if running in User Context
            # Assets
            $Local:RegPath   = [string]('Registry::HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo')
            $Local:RegNames  = [string[]]('IntuneUserSID','IntuneUserName','IntuneUserPrincipalName','DateSet')
            $Local:RegValues = [string[]]($Script:StrIntuneUserSID,$Script:StrIntuneUserName,$Script:StrIntuneUserPrincipalName,[string]([datetime]::Now.ToString('o')))

            # Get Current Info
            $Local:CurrentUserSID           = [string]($(Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[0] -ErrorAction 'SilentlyContinue').($Local:RegNames[0]))
            $Local:CurrentUserName          = [string]($(Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[1] -ErrorAction 'SilentlyContinue').($Local:RegNames[1]))
            $Local:CurrentUserPrincipalName = [string]($(Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[2] -ErrorAction 'SilentlyContinue').($Local:RegNames[2]))
            $Local:CurrentUserDateSet       = [datetime]$(Try{[datetime](Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[3] -ErrorAction 'SilentlyContinue').($Local:RegNames[3])}catch{[datetime]::MinValue})

            # Set Info if any of the values does not match wanted values
            if (
                [bool](-not [string]::IsNullOrEmpty($Local:RegValues[0]) -and $Local:RegValues[0] -ne $Local:CurrentUserSID) -or
                [bool](-not [string]::IsNullOrEmpty($Local:RegValues[1]) -and $Local:RegValues[1] -ne $Local:CurrentUserName) -or
                [bool](-not [string]::IsNullOrEmpty($Local:RegValues[2]) -and $Local:RegValues[2] -ne $Local:CurrentUserPrincipalName) -or
                $Local:CurrentUserDateSet -eq [datetime]::MinValue
            ) {      
                # Create path if not exist
                if (-not(Test-Path -Path $Local:RegPath)) {
                    $null = New-Item -Path $Local:RegPath -Force -ErrorAction 'Stop'
                }
                # Set registry values
                foreach ($x in [byte[]]$(0 .. [byte]($Local:RegNames.'Length' - 1))) {
                    if (-not[string]::IsNullOrEmpty($Local:RegValues[$x])) {
                        $null = Set-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[$x] -Value $Local:RegValues[$x] -Force -ErrorAction 'Stop'
                    }
                }
            }
        #endregion Write SID and UserName to HKCU if running in User Context
    }
        
        
    # Output Intune User and SID if found
    if (-not [string]::IsNullOrEmpty($Script:StrIntuneUserSID)) {
        Write-Output -InputObject ('Intune User SID "{0}", Username "{1}".' -f ($Script:StrIntuneUserSID,$Script:StrIntuneUserName))
    }
    #endregion Get SID and "Domain\Username" for Intune User



    # End the Initialize Region
    Write-Output -InputObject ('**********************')
################################################################################################
#endregion Don't Touch This
################################################################################################
#region    Your Code Here
################################################################################################



#region    Assets
    # Verbose
    Write-Verbose -Message ('### Assets')

    #region    Assets & Variables
        # Verbose
        Write-Verbose -Message ('# Assets & Variables')

        # Prerequisites
        if ([string]::IsNullOrEmpty($ScriptNameNoun)){$BoolScriptSuccess = $false; Throw 'ERROR: $ScriptNameNoun is Empty!'; Break}
        else {Write-Verbose -Message ('{0}Prerequisites where met.' -f ("`t"))}

        # Help Variables
        $BoolScriptSuccess = [bool] $true
                
        <#
            *SB = ScriptBlock Variables (For passing into the installed PowerShell script file)
        #>
        #region    IronSync Folders
            $PathDirIronSyncSB      = [System.Management.Automation.ScriptBlock]{[string]$('{0}\IronstoneIT\{1}' -f ($env:ProgramW6432,$ScriptNameNoun))}
            $PathDirIronSync        = Invoke-Command -ScriptBlock $PathDirIronSyncSB
            $PathDirIronSyncLogsSB  = [System.Management.Automation.ScriptBlock]{[string]$('{0}\Logs' -f ($PathDirIronSync))}
            $PathDirIronSyncLogs    = Invoke-Command -ScriptBlock $PathDirIronSyncLogsSB
            $PathDirAzCopyJournalSB = [System.Management.Automation.ScriptBlock]{[string]$('{0}\AzCopyJournal' -f ($PathDirIronSync))}
            $PathDirAzCopyJournal   = Invoke-Command -ScriptBlock $PathDirAzCopyJournalSB
        #endregion IronSync Folders
                
        #region    File Sync Folders                                                
            # File Sync Folder - ScriptBlock Variables (For passing into the installed PowerShell script file)
            $PathDirSyncFilesSB     = [System.Management.Automation.ScriptBlock]{[string]$('{0}\Users\Public\IronSync' -f ($env:SystemDrive))}
            # File Sync Folder - Regular Variables (For use in current script)
            $PathDirSyncFiles       = Invoke-Command -ScriptBlock $PathDirSyncFilesSB
            # AzCopy Location - ScriptBlock Variables (For passing into the installed PowerShell script file)
            $PathFileAzCopySB       = [System.Management.Automation.ScriptBlock]{[string]$('{0}\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' -f (${env:ProgramFiles(x86)}))}
            # AzCopy Location - Regular Variables (For use in current script)
            $PathFileAzCopy         = Invoke-Command -ScriptBlock $PathFileAzCopySB
            # AzCopy10 Location - ScriptBlock Variables (For passing into the installed PowerShell script file)
            $PathFileAzCopy10SB     = [System.Management.Automation.ScriptBlock]{[string]$('{0}\IronstoneIT\Binaries\AzCopy\azcopy.exe' -f ($env:ProgramData))}
            # AzCopy10 Location - Regular Variables (For use in current script)
            $PathFileAzCopy10       = Invoke-Command -ScriptBlock $PathFileAzCopy10SB
        #endregion File Sync Folders
                
        # Verbose
        Write-Verbose -Message ('> Done.')
    #endregion     Assets & Variables


    #region    Install Files
        # Verbose
        Write-Verbose -Message ('# Install Files')

        # Regular Variables
        $NameFilePS1SB    = [System.Management.Automation.ScriptBlock]{[string]$('Run-{0}.ps1' -f ($ScriptNameNoun))}
        $NameFilePS1      = Invoke-Command -ScriptBlock $NameFilePS1SB
        $PathFilePS1      = [string]$('{0}\{1}' -f ($PathDirIronSync,$NameFilePS1))
        $EncodingFilePS1  = [string]$('utf8')
        $VariablesReplacementTable = [ordered]@{
            '###VARIABLESTATIC01###'    = $NameFilePS1
            '###VARIABLESTATIC02###'    = $CustomerAzureStorageAccountName
            '###VARIABLESTATIC03###'    = $CustomerAzureStorageAccountBlobName
            '###VARIABLESTATIC04###'    = $CustomerAzureStorageAccountSASToken
            '"###VARIABLEDYNAMIC01###"' = $PathDirIronSyncSB.ToString()
            '"###VARIABLEDYNAMIC02###"' = $PathDirIronSyncLogsSB.ToString()
            '"###VARIABLEDYNAMIC03###"' = $PathDirSyncFilesSB.ToString()
            '"###VARIABLEDYNAMIC04###"' = $PathFileAzCopySB.ToString()
            '"###VARIABLEDYNAMIC05###"' = $PathDirAzCopyJournalSB.ToString()
            '"###VARIABLEDYNAMIC06###"' = $PathFileAzCopy10SB.ToString()
        }
        $ContentFilePS1SB = [System.Management.Automation.ScriptBlock]{#Requires -RunAsAdministrator

<#
    .SYNAPSIS
        This script will sync down a Azure Storage Account Blob Container to specified folder

    .DESCRIPTION
        This script will sync down a Azure Storage Account Blob Container to specified folder

    .NOTES
        Author:   Olav Roennestad Birkeland @ Ironstone IT
        Modified: 200520
#>


#region    Initialize - Settings and Variables
    #region    Inserted Static Variables
        # IronSync
        $NameScript             = [string]$('###VARIABLESTATIC01###')
        # Azure Storage Account Connection Info
        $StorageAccountName     = [string]$('###VARIABLESTATIC02###')
        $StorageAccountBlobName = [string]$('###VARIABLESTATIC03###')
        $StorageAccountSASToken = [string]$('###VARIABLESTATIC04###')
    #endregion Inserted Static Variables

    #region    Dynamic Variables 1
        # IronSync
        $NameScriptNoun         = [string]$($NameScript.Split('-')[-1].Replace('.ps1',''))
    #endregion Dynamic Variables 1

    #region    Inserted Dynamic Variables
        # IronSync
        $PathDirIronSync        = "###VARIABLEDYNAMIC01###"
        $PathDirLog             = "###VARIABLEDYNAMIC02###"
        # Folder for Synced Files
        $PathDirSync            = "###VARIABLEDYNAMIC03###"
        # AzCopy
        $PathFileAzCopy         = "###VARIABLEDYNAMIC04###"
        $PathDirAzCopyJournal   = "###VARIABLEDYNAMIC05###"
        $PathFileAzCopy10       = "###VARIABLEDYNAMIC06###"
    #endregion Inserted Dynamic Variables
    
    
    #region    Dynamic Variables 2
        # IronSync - Log
        $NameFileLog            = [string]$('{0}-runlog-{1}.log' -f ($ScriptNameNoun,[datetime]::Now.ToString('yyMMdd-HHmmss')))
        $PathFileLog            = [string]$('{0}\{1}' -f ($PathDirLog,$NameFileLog))
        # Azure Storage Account Connection Info
        $StorageAccountBlobURL  = [string]$('https://{0}.blob.core.windows.net/{1}' -f ($StorageAccountName,$StorageAccountBlobName))
    #endregion Dynamic Variables 2


    #region    Help Variables
        $BoolScriptSuccess      = [bool]$($true)
    #endregion Help Variables
  
     
    #region    Settings - PowerShell
        $DebugPreference        = 'SilentlyContinue'
        $ErrorActionPreference  = 'Stop'
        $InformationPreference  = 'SilentlyContinue'
        $ProgressPreference     = 'SilentlyContinue'
        $VerbosePreference      = 'Continue'
        $WarningPreference      = 'Continue'
    #endregion Settings - PowerShell
#endregion Initialize - Settings and Variables



#region Try
#################################
Try {
#################################


# Logging
## Create log dir if not exist
if (-not(Test-Path -Path $PathDirLog)) {
    New-Item -Path $PathDirLog -ItemType 'Directory' -Force
}
## Start logging
$null = Start-Transcript -Path $PathFileLog -Force

    


# Prerequisites & Tests
## Check what AzCopy version is available - Prefer v10, fallback to v8.1.0
Write-Output -InputObject ('# Check what AzCopy version is available - Prefer v10, fallback to v8.1.0')
$UseAzCopy10 = [bool][System.IO.File]::Exists($PathFileAzCopy10)
if ($UseAzCopy10) {
    $PathFileAzCopy = $PathFileAzCopy10
}

## Check if neccessary paths exist
Write-Output -InputObject ('# Check if neccessary paths exist')
$PathsToCheck = [string[]]$($PathDirSync,$PathFileAzCopy,$(if(-not$UseAzCopy10){$PathDirAzCopyJournal}))
foreach ($Path in $PathsToCheck) {
    if (Test-Path -Path $Path) {
        Write-Output -InputObject ('{0}SUCCESS - "{1}" does exist.' -f ("`t",$Path))
    }
    else {
        Write-Output -InputObject ('{0}ERROR   - "{1}" does NOT exists. Can not continue without it' -f ("`t",$Path))
        $BoolScriptSuccess = $false
    }
}
if (-not($BoolScriptSuccess)) {
    Break
}


## Check if running already
Write-Output -InputObject ('# Check if running already')
if (
    [array](
        Get-Process -Name 'AzCopy' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Path' | ForEach-Object -Process {
            $_.Replace(('\{0}' -f ($_.Split('\')[-1]),''))
        } | Sort-Object -Unique
    ) -contains [string]$(if($PathFileAzCopy[-1] -eq '\'){$PathFileAzCopy.Substring(0,$PathFileAzCopy.'Length'-1)}else{$PathFileAzCopy})
) {
    Write-Output -InputObject ('{0}ERROR   - AzCopy is already running.' -f ("`t",$Path))
    $BoolScriptSuccess = $false
}
if (-not($BoolScriptSuccess)) {
    Break
}
        
## Check if AzCopy.exe v8.1.0 journal leftovers are left from previous runs
if (-not $UseAzCopy10) {
    Write-Output -InputObject ('# Check if AzCopy journal leftovers from previous runs')
    ### Get AzCopy journal files
    $JournalFiles = [array](Get-ChildItem -Path $PathDirAzCopyJournal -File -Recurse:$false)
    ### If any found, delete them if more than 1 day old. Else: Error.
    if ($JournalFiles.'Count' -ge 1) {
        Write-Output -InputObject 'Found AzCopy journal files.'
        if ([bool[]]$($JournalFiles.ForEach{$_.'LastWriteTime' -le [datetime]::Now.AddDays(-1)}) -contains $false) {
            Write-Output -InputObject 'AzCopy journal files are not older than 24h. Will not delete.'
            $BoolScriptSuccess = $false
        }
        else {
            # Attempt to delete
            $DeleteJournalFilesSuccess = [bool[]]$(
                $JournalFiles.ForEach{
                    Try{
                        $null=Remove-Item -Path $_.'FullName' -Recurse:$false -ErrorAction 'SilentlyContinue'
                        [bool]($? -and -not [bool](Test-Path -Path $_.'FullName'))
                    }
                    Catch{
                        [bool]($false)
                    }
                }
            )
            if ($DeleteJournalFilesSuccess -contains $false) {
                Write-Output -InputObject ('{0}ERROR   - Failed to delete some of the journal files.' -f ("`t"))
                $BoolScriptSuccess = $false
            }
        }
    }
    if (-not($BoolScriptSuccess)) {
        Break
    }
}

## Check Internet Connectivity
Write-Output -InputObject ('# Check Internet Connectivity')
if ([bool]$($null = Resolve-DnsName -Name 'blob.core.windows.net' -ErrorAction 'SilentlyContinue';$?)) {
    Write-Output -InputObject ('{0}SUCCESS - Could resolve "blob.core.windows.net".' -f ("`t"))
}
else {
    Write-Output -InputObject ('{0}ERROR   - Could not resolve "blob.core.windows.net".' -f ("`t"))
    Write-Output -InputObject ('{0}{0}Either no internet connectivity, or Azure Storage is down.' -f ("`t"))
    $BoolScriptSuccess = $false
}
if (-not($BoolScriptSuccess)) {
    Break
}




# Sync with AzCopy
<#
    Switches v10.x.x
        azcopy sync <source> <destination> [flags]
        --cap-mbps=<n>            = Cap bandwidth in megabits per second
        --check-md5=<option>      = How strict to check downloaded content checksum. Default = FailIfDifferent.
        --recursive=<true/false>  = Recurse
        --output-type=<json/text> = Whether output from azcopy.exe should be formatted as JSON or string (default)        

    Switches v8.1.0
        /Z        = Journal file folder, for AzCopy to resume operation
        /Y        = Surpress all confirmations
        /S        = Specifies recursive mode for copy operations. In recursive mode, AzCopy will copy all blobs or files that match the specified file pattern, including those in subfolders.
        /CheckMD5 = See if destination matches source MD5
        /L        = Specifies a listing operation only; no data is copied.
        /MT       = Sets the downloaded file's last-modified time to be the same as the source blob or file's.
        /XN       = Excludes a newer source resource. The resource will not be copied if the source is the same or newer than destination.
        /XO       = Excludes an older source resource. The resource will not be copied if the source resource is the same or older than destination.
#>

            
# If Files In Use - Exit and set $BoolScriptSuccess to $false to keep log
if (@(Get-ChildItem -Path $PathDirSync -Recurse -Force -File | Where-Object -FilterScript {$_.'Name' -Like '~$*' -and $_.'Mode' -eq '-a-h--'}).'Count' -ge 1) {
    Write-Output -InputObject ('Files are in use, AzCopy would have failed. Exiting.')
    $BoolScriptSuccess = $false
}
else {
    # Build argument    
    $Arguments = [string[]]$(
        if ($UseAzCopy10) {            
            ('"{0}"' -f ($PathFileAzCopy10)),                                  # AzCopy.exe v10.x.x path
            ('sync'),                                                          # Sync flag
            ('"{0}{1}"' -f ($StorageAccountBlobURL,$StorageAccountSASToken)),  # Source URL with SAS token
            ('"{0}"' -f ($PathDirSync)),                                       # Destination
            ('--cap-mbps=0'),                                                  # Do not cap bandwidth (0 = no cap)
            ('--check-md5=FailIfDifferent'),                                   # Check MD5 sum, fail if different
            ('--delete-destination=true'),                                     # Delete files from destination not in source anymore
            ('--output-type=text'),                                            # Output from azcopy.exe
            ('--recursive=true')                                               # Recurse
        }
        else {
            ('"{0}"' -f ($PathFileAzCopy)),                                    # AzCopy v8.1.0 path
            ('/Source:"{0}"' -f ($StorageAccountBlobURL)),                     # Source
            ('/Dest:"{0}"' -f ($PathDirSync)),                                 # Destination
            ('/SourceSAS:"{0}"' -f ($StorageAccountSASToken)),                 # SAS key
            ('/Z:"{0}"' -f ($PathDirAzCopyJournal)),                           # AzCopy journal directory
            ('/Y'),                                                            # Surpress all confirmations
            ('/S'),                                                            # Specifies recursive mode for copy operations
            ('/MT'),                                                           # Sets the downloaded file's last-modified time to be the same as the source blob or file's
            ('/XO')                                                            # Excludes an older source resource
        }
    )

    # Syncronize files down from Azure Storage Account Blob
    $AzCopyExitCode = [byte] 0
    Try {
        Write-Output -InputObject ('#### Start AzCopy Output ####')
        Write-Verbose -Message ('& cmd /c {0}' -f ($Arguments -join ' '))
        & 'cmd' '/c' ($Arguments -join ' ')
        $AzCopyExitCode = $LASTEXITCODE
    }
    Catch {
        $AzCopyExitCode    = 1
        $BoolScriptSuccess = $false
    }
    Finally {
        Write-Output -InputObject ('#### End AzCopy Output ####')
    }
    Write-Output -InputObject ('AzCopy Exit Code: {0}.' -f ($AzCopyExitCode))


    # If Fail - Write Output and set $BoolScriptSuccess to keep log
    if ($AzCopyExitCode -ne 0) {
        Write-Output -InputObject ('ERROR   - Last Exit Code Does Not Smell Like Success: {0}.' -f ($AzCopyExitCode.ToString()))
        $BoolScriptSuccess = $false
    }
    elseif ($([array](Get-ChildItem -Path $PathDirSync -File -Force -Recurse)).'Count' -le 0) {
        Write-Output -InputObject ('ERROR   - No files found in directory "{0}" after AzCopy finished.' -f ($PathDirSync))
        $BoolScriptSuccess = $false
    }
    else {
        Write-Output -InputObject ('SUCCESS - Healthy Exit Code and 1 or more files files found in sync path.')
    }
}




#################################
}
#################################
#endregion Try



# Catch
Catch {
    $BoolScriptSuccess = $false
}



# Finally
Finally {
    # Stop Transcript
    $null = Stop-Transcript
    # Don't keep the log file if success
    if ($BoolScriptSuccess) {
        Remove-Item -Path $PathFileLog -Force
    }
}
    }
                
        # Verbose
        Write-Verbose -Message ('{0}Done.' -f ("`t"))             
    #endregion Install Files        
            



    #region    Registry Values
        # Verbose
        Write-Verbose -Message ('# Registry Values')
                
        # Registry Values
        $RegValuesSID = [string]$(if($BoolIsSystem){$Script:StrIntuneUserSID}else{$Script:StrSIDRunningAs})
        $RegValues = [PSCustomObject[]]@(                    
            [PSCustomObject]@{
                'Path'  = [string]$('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Excel\Options' -f ($RegValuesSID))
                'Name'  = [string]'PersonalTemplates'
                'Value' = $PathDirSyncFiles
                'Type'  = [string]'ExpandString'
            },
            [PSCustomObject]@{
                'Path'  = [string]$('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\PowerPoint\Options' -f ($RegValuesSID))
                'Name'  = [string]'PersonalTemplates'
                'Value' = $PathDirSyncFiles
                'Type'  = [string]'ExpandString'
            },
            [PSCustomObject]@{
                'Path'  = [string]$('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0\Word\Options' -f ($RegValuesSID))
                'Name'  = [string]'PersonalTemplates'
                'Value' = $PathDirSyncFiles
                'Type'  = [string]'ExpandString'
            }
        )

        # Verbose
        Write-Verbose -Message ('> Done.')
    #endregion Registry Values
            


    #region    Dynamic Assets
        # Verbose
        Write-Verbose -Message ('# Dynamic Assets')

        # Paths to create if does not exist
        $PathsToCreate = [string[]](
            $PathDirIronSync,
            $PathDirIronSyncLogs,
            $PathDirAzCopyJournal,
            $PathDirSyncFiles
        )
        # Paths to remove if exist
        $PathsToRemove = [string[]](
            # IronSync Path(s)
            @($PathDirIronSync) +
            @(Get-ChildItem -Path ('{0}\IronstoneIT' -f ($env:ProgramW6432)) -Directory -Force -Filter '*IronSync*OfficeTemplates*' | Select-Object -ExpandProperty 'FullName' | Where-Object {$_ -notlike $PathDirIronSync}) +                                         
            ('{0}\IronstoneIT\IronSync' -f ($env:ProgramW6432))
        ) | Select-Object -Unique
                
        # Verbose
        Write-Verbose -Message ('> Done.')
    #endregion Dynamic Assets

    # Verbose
    Write-Verbose -Message ('Done')
#endregion Assets




#region    Functions
    #region    Write-ReadOnly
    function Write-ReadOnly {Write-Verbose -Message ('ReadOnly = {0}, will not write any changes.' -f ($ReadOnly))}
    #endregion Write-ReadOnly
#endregion Functions




#region    Cleanup Previous Install           
    # Verbose
    Write-Verbose -Message ('### Cleanup Previous Install')
            
    # Directories
    foreach ($Path in $PathsToRemove) {
        # Skip if invalid path
        if ($Path -like ('{0}:*\\*' -f ($env:SystemDrive))) {Write-Error -Message 'ERROR: "{0}" is not a valid path.' -ErrorAction 'Stop'}

        # Skip unless path exist
        if (Test-Path -Path $Path) {
            $Attempt  = [byte]$(1)
            $Attempts = [byte]$(3)
                    
            while ($Attempt -le $Attempts) {
                $null = Remove-Item -Path $Path -Recurse -Force -ErrorAction 'SilentlyContinue'
                if ((-not($?)) -or [bool]$(Test-Path -Path $Path)) {
                    # Wait some time in case other process(es) are using the path / file(s)
                    $null = Start-Sleep -Seconds 5
                    # Increment $Attempt
                    $Attempt++
                    # Error if $Attempt is greater than $Attempts
                    if ($Attempt -gt $Attempts) {
                        Write-Error -Message ('ERROR: Failed to delete "{0}" recursively.' -f ($Path)) -ErrorAction 'Stop'
                    }
                }
                else {
                    $Attempt = 4
                }
            }
                    
            # Stats - Exit if failed
            $SuccessCleanup = [bool]$(-not(Test-Path -Path $Path))                                                          
            Write-Verbose -Message ('Deleting "{0}". Success? {1}.' -f ($Path,$SuccessCleanup.ToString()))
            if (-not $SuccessCleanup) {
                Write-Error -Message 'Failed to delete previous resources.' -ErrorAction 'Stop'
            }
        }
    }

    # Scheduled Task
    $null = $(
        Get-ScheduledTask
    ).Where{
        $_.'Author' -like 'Ironstone*' -and (
            $_.'TaskName' -like 'IronSync*' -or 
            $_.'TaskName' -like ('*{0}' -f ($ScriptNameNoun)) -or 
            $_.'TaskName' -like $ScriptNameFull -or $_.'TaskName' -like '*IronSync(*OfficeTemplates*)'
        ) -and
        $_.'TaskName' -notlike '*trigger*' -and
        $_.'TaskName' -notlike '*locker*'
    } | Unregister-ScheduledTask -Confirm:$false

    # Verbose
    Write-Verbose -Message ('Done.')
#endregion Cleanup Previous Install




#region    Create Template folder & IronSync Folder - For Schedule, Log Files and AzCopy Journal Files
    # Verbose
    Write-Verbose -Message ('### Create Template folder & IronSync Folder - For Schedule, Log Files and AzCopy Journal Files')

    # Do it
    foreach ($Dir in $PathsToCreate) {
        if (Test-Path -Path $Dir) {
            Write-Verbose -Message ('Path "{0}" already exist.' -f ($Dir))
        }
        else {
            Write-Verbose -Message ('Path "{0}" does not already exist.' -f ($Dir))
            if ($ReadOnly) {Write-ReadOnly}
            else {
                $null = New-Item -Path $Dir -ItemType 'Directory' -Force
                Write-Verbose -Message ('Creating.. Success? {0}' -f ($?))
            }
        }
    }

    # Verbose
    Write-Verbose -Message ('Done.')
#endregion Create Template folder & IronSync Folder - For Schedule, Log Files and AzCopy Journal Files




#region    Set Template folder to be hidden
    # Verbose
    Write-Verbose -Message ('### Set Template folder to be hidden')
            
    # Do it
    Write-Verbose -Message ('Setting folder "{0}" to be ReadOnly and Hidden' -f ($PathDirSyncFiles))
    if ($ReadOnly) {Write-ReadOnly}
    else {
        (Get-Item $PathDirSyncFiles -Force).'Attributes' = 'Hidden, ReadOnly, Directory'
        Write-Verbose -Message ('Success? {0}' -f ($?))
    }

    # Verbose
    Write-Verbose -Message ('Done.')
#endregion Set Template folder to be hidden




#region    Registry - Set template folder for O365 application
    # Verbose
    Write-Verbose -Message ('### Registry - Set template folder for O365 application')
            
    # Do it
    foreach ($Item in $RegValues) {
        Write-Verbose -Message ('Path: "{0}".' -f ($Item.'Path'))

        # Check if $Item.Path exist, create it if not
        if (-not(Test-Path -Path $Item.'Path')){
            Write-Verbose -Message ('   Path did not exist, creating it.')
            $null = New-Item -Path $Item.'Path' -ItemType 'Directory' -Force -ErrorAction 'Stop'                        
        }
        
        # Set Value / ItemPropery
        Write-Verbose -Message ('   Name: {0} | Value: {1} | Type: {2}' -f ($Item.'Name',$Item.'Value',$Item.'Type'))
        $null = Set-ItemProperty -Path $Item.'Path' -Name $Item.'Name' -Value $Item.'Value' -Type $Item.'Type' -Force -ErrorAction 'Stop'
    }

    # Verbose
    Write-Verbose -Message ('Done.')
#endregion Registry - Set template folder for O365 application




#region    Install IronSync
    # Verbose
    Write-Verbose -Message ('### Install IronSync')
            
    # Do it
    Write-Verbose -Message ('Installing IronSync file to "{0}"' -f ($PathFilePS1))
    if ($ReadOnly) {Write-ReadOnly}
    else {
        # Convert scriptblock to string
        $ContentFilePS1SB = [string] $ContentFilePS1SB.ToString()

        # Replace variables with value                                
        foreach ($Variable in $VariablesReplacementTable.GetEnumerator()) {
            $ContentFilePS1SB = $ContentFilePS1SB.Replace($Variable.'Name',$Variable.'Value')
        }

        # Output to a file
        $null = Out-File -Force -FilePath $PathFilePS1 -Encoding $EncodingFilePS1 -InputObject $ContentFilePS1SB
                
        # Verbose
        Write-Verbose -Message ('Success? {0}.' -f ($?.ToString()))
    }

    # Verbose
    Write-Verbose -Message ('Done.')
#endregion Install IronSync



#region    Create Scheduled Tasks                    
    # Verbose
    Write-Verbose -Message ('### Create Scheduled Tasks')
            
    #region    Create Scheduled Task running PS1 using PowerShell.exe - Every Day Every Hour When Powered On - Random Second to Not Flood Azure Storage Account
        # Verbose
        Write-Verbose -Message ('# Create Scheduled Task running PS1 using PowerShell.exe - Every Day Every Hour When Powered On')
                
        # Assets
        $PathFilePowerShell       = [string]$('%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe') # Works regardless of 64bit vs 32bit
        $NameScheduledTask        = [string]$($ScriptNameNoun)
        $DescriptionScheduledTask = [string]$('Runs IronSync, which syncs down files from Azure Blob Storage using AzCopy.')

        # Construct Scheduled Task
        $ScheduledTask = New-ScheduledTask `
            -Action    (New-ScheduledTaskAction -Execute ('"{0}"' -f ($PathFilePowerShell)) -Argument ('-ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File "{0}"' -f ($PathFilePS1))) `
            -Principal (New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -RunLevel 'Highest') `
            -Trigger   (New-ScheduledTaskTrigger -Once -At ([datetime]::Today.AddSeconds(([System.Random]::new()).Next(3599))) -RepetitionInterval ([timespan]::FromHours(1))) `
            -Settings  (New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([timespan]::FromMinutes(10)) -Compatibility 4 -StartWhenAvailable:$false -WakeToRun:$false -RunOnlyIfNetworkAvailable)
        $ScheduledTask.Author      = 'Ironstone'
        $ScheduledTask.Description = ('{0}Runs a PowerShell script. {1}Execute: "{2}". {1}Arguments: "{3}".' -f (
            $(if([string]::IsNullOrEmpty($DescriptionScheduledTask)){''}else{('{0} {1}' -f ($DescriptionScheduledTask,"`r`n"))}),"`r`n",
            [string]($ScheduledTask | Select-Object -ExpandProperty Actions | Select-Object -ExpandProperty 'Execute'),
            [string]($ScheduledTask | Select-Object -ExpandProperty Actions | Select-Object -ExpandProperty 'Arguments')
        ))
                
        # Register Scheduled Task
        $null = Register-ScheduledTask -TaskName $NameScheduledTask -InputObject $ScheduledTask -Force -Verbose:$false -Debug:$false
                
        # Check if success registering Scheduled Task
        $SuccessCreatingScheduledTask = [bool]$($? -and [bool]$([byte](@(Get-ScheduledTask -TaskName $NameScheduledTask).Count) -eq 1))
        Write-Verbose -Message ('Success creating scheduled task "{0}"? "{1}".' -f ($NameScheduledTask,$SuccessCreatingScheduledTask.ToString()))
                
        # Run Scheduled Task if Success Creating It
        if ($SuccessCreatingScheduledTask) {
            $null = Start-ScheduledTask -TaskName $NameScheduledTask
            Write-Verbose -Message ('Success starting scheduled task? "{0}".' -f ($?.ToString()))
        }
        else {Write-Error -Message 'ERROR: Failed to create scheduled task.'}

        # Verbose
        Write-Verbose -Message ('> Done')
    #endregion Create Scheduled Task running PS1 using PowerShell.exe - Every Day Every Hour When Powered On - Random Second to Not Flood Azure Storage Account

    #region    Create Scheduled Task running previous Scheduled Task  - Every Laptop Startup
        # Verbose
        Write-Verbose -Message ('# Create Scheduled Task running previous Scheduled Task  - Every Laptop Startup')

        # Assets
        $NameScheduledTaskRunAtStartup = ('{0}-RunAtStartup' -f ($NameScheduledTask))
                
        # Construct Scheduled Task
        $ScheduledTask = New-ScheduledTask                                                    `
            -Action    (New-ScheduledTaskAction -Execute ('Schtasks.exe') -Argument ('/Run /TN "{0}"' -f ($NameScheduledTask)))         `
            -Principal (New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -RunLevel 'Highest')                                            `
            -Trigger   (New-ScheduledTaskTrigger -AtStartup)                                                                                `
            -Settings  (New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::FromMinutes(10)) -Compatibility 4 -StartWhenAvailable)
        $ScheduledTask.Author      = 'Ironstone'
        $ScheduledTask.Description = ('Runs Scheduled Task "{0}" at Windows startup.' -f ($NameScheduledTask))

        # Register Scheduled Task
        $null = Register-ScheduledTask -TaskName $NameScheduledTaskRunAtStartup -InputObject $ScheduledTask -Force -Verbose:$false -Debug:$false
                
        # Check if success registering Scheduled Task
        $SuccessCreatingScheduledTask = [bool]$($? -and [bool]$([byte](@(Get-ScheduledTask -TaskName $NameScheduledTaskRunAtStartup).Count) -eq 1))
        Write-Verbose -Message ('Success creating scheduled task "{0}"? "{1}".' -f ($NameScheduledTaskRunAtStartup,$SuccessCreatingScheduledTask.ToString()))

        # Verbose
        Write-Verbose -Message ('> Done')
    #endregion Create Scheduled Task running previous Scheduled Task  - Every Laptop Startup

    # Verbose
    Write-Verbose -Message ('Done.')
#endregion Create Scheduled Tasks


#region    Add version information to the registry
    $RegPath = [string]('Registry::\HKEY_LOCAL_MACHINE\SOFTWARE\IronstoneIT\Intune\{0}' -f ($ScriptNameNoun))
    if (-not (Test-Path -Path $RegPath)) {
        $null = New-Item -Path $RegPath -ItemType 'Directory' -Force
    }
    $null = Set-ItemProperty -Path $RegPath -Name 'Version' -Value $Version -Type 'String' -Force
#endregion Add version information to the registry



################################################################################################
#endregion Your Code Here
################################################################################################
#region    Don't touch this
################################################################################################
}
Catch {
    # Set ScriptSuccess to false
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
    # Unload Users' Registry Profiles (NTUSER.DAT) if any were loaded
    if ($Script:BoolIsSystem -and $BoolWriteToHKCUFromSystem -and ([string[]]@($RegistryLoadedProfiles | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))})).'Count' -gt 0) {
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
                    Write-Output -InputObject ('ERROR: Failed to unload user registry hive "{0}".' -f ($PathUserHive)) -ErrorAction 'Continue'
                }
                else {
                    Write-Output -InputObject ('Successfully unloaded user registry hive "{0}".' -f ($PathUserHive))
                }
            }
        }
    }
    
    # Stop Transcript
    Stop-Transcript
}
# Exit script
if ($ScriptSuccess) {
    Exit 0
}
else {
    Exit 1
}
################################################################################################
#endregion Don't touch this
################################################################################################
