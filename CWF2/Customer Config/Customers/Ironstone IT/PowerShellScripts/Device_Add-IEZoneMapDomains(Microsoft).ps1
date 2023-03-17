﻿<#
    .SYNOPSIS


    .DESCRIPTION


    .NOTES
        * In Intune, remember to set "Run this script using the logged in credentials"  according to the $DeviceContext variable.
            * Intune -> Device Configuration -> PowerShell Scripts -> $NameScriptFull -> Properties -> "Run this script using the logged in credentials"
            * DEVICE (Local System) or USER (Logged in user).
        * Only edit $DeviceContext and $NameScript in the template, add your code in the #region Your Code Here.
        * You might want to touch "Settings - PowerShell - Output Preferences" for testing / development. 
            * $VerbosePreference, eventually $DebugPreference, to 'Continue' will print much more details.
#>

# Customer Variables (If any)
$Context = [byte]$(2) # 0 = User, 1 = Device, 2 = Both

# Script Name & Settings
$NameScript            = [string] 'Add-IEZoneMapDomains(Microsoft)'
$DeviceContext         = [bool]   $true
$WriteToHKCUFromSystem = [bool]   $true

# Settings - PowerShell - Output Preferences
$DebugPreference       = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'

#region    Don't Touch This
# Settings - PowerShell - Interaction
$ConfirmPreference     = 'None'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'

# Settings - PowerShell - Behaviour
$ErrorActionPreference = 'Continue'

# Dynamic Variables - Process & Environment
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptFull' -Value ([string]('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript)))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptVerb' -Value ([string]$NameScript.Split('-')[0])
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptNoun' -Value ([string]$NameScript.Split('-')[-1])
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureProcess' -Value ([string]$(if([System.Environment]::Is64BitProcess){'64'}else{'32'}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureOS' -Value ([string]$(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'}))

# Dynamic Variables - User
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserNameRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name'))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrSIDRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value'))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsAdmin'  -Value ([bool]$(([System.Security.Principal.WindowsPrincipal]$([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsSystem' -Value ([bool]$($Script:StrSIDRunningAs -like ([string]$('S-1-5-18'))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsCorrectUser' -Value ([bool]$(if($Script:DeviceContext -and $Script:BoolIsSystem){$true}elseif(((-not($DeviceContext))) -and (-not($Script:BoolIsSystem))){$true}else{$false}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolWriteToHKCUFromSystem' -Value ([bool]$(if($DeviceContext -and $WriteToHKCUFromSystem){$true}else{$false}))

# Dynamic Variables - Logging
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'Timestamp' -Value ([string]$([datetime]::Now.ToString('yyMMdd-HHmmssffff')))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathDirLog' -Value ([string]$('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ([string]$(if($BoolIsSystem){$env:ProgramW6432}else{[System.Environment]::GetEnvironmentVariable('LocalAppData')}))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathFileLog' -Value ([string]$('{0}{1}-{2}bit-{3}.txt' -f ($Script:PathDirLog,$Script:NameScriptFull,$Script:StrArchitectureProcess,$Script:Timestamp)))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ScriptSuccess' -Value ([bool]$($true))

# Start Transcript
if (-not(Test-Path -Path $Script:PathDirLog)) {$null = New-Item -ItemType 'Directory' -Path $Script:PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $Script:PathFileLog -ErrorAction 'Stop'


# Wrap in Try/Catch, so we can always end the transcript
Try {
    # Output User Info, Exit if not $BoolIsCorrectUser
    Write-Output -InputObject ('Running as user "{0}" ({1}). Has admin privileges? {2}. $DeviceContext? {3}. Running as correct user? {4}.' -f ($Script:StrUserNameRunningAs,$Script:StrSIDRunningAs,$Script:BoolIsAdmin.ToString(),$Script:DeviceContext.ToString(),$Script:BoolIsCorrectUser.ToString()))
    if (-not($Script:BoolIsCorrectUser)){Throw 'Not running as correct user!'; Break}


    # Output Process and OS Architecture Info
    Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($Script:StrArchitectureProcess,$Script:StrArchitectureOS))


    # If OS is 64 bit, and PowerShell got launched as x86, relaunch as x64
    if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if (-not([string]::IsNullOrEmpty($MyInvocation.'Line'))) {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile $MyInvocation.'Line'}
        else {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($MyInvocation.'InvocationName')) $args}
        exit $LASTEXITCODE
    }

    
    #region    Get SID and "Domain\Username" for Intune User only if $WriteToHKCUFromSystem
        # If running in Device Context as "NT Authority\System"
        if ($DeviceContext -and $Script:BoolIsSystem -and $BoolWriteToHKCUFromSystem) {
            # Help Variables
            $Script:RegistryLoadedProfiles = [string[]]@()
            $Local:SID                     = [string]::Empty
            $Local:LengthInterval          = [byte[]]@(40 .. 80)


            # Load User Profiles NTUSER.DAT (Registry) that is not available from current context
            $PathProfileList = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList')
            $SIDsProfileList = [string[]]@(Get-ChildItem -Path $PathProfileList -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object -Process {$_.Split('\')[-1]} | Where-Object -FilterScript {$_ -like 'S-1-12-*'})
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
            $IntuneUser = [PSCustomObject]([PSCustomObject[]]@(
                foreach ($x in [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {[bool]$($_ -like 'S-1-12-*') -and [bool]$(Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($_)))})) {
                    [PSCustomObject]@{
                        'IntuneUserSID' =[string](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'IntuneUserSID' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'IntuneUserSID');
                        'IntuneUserName'=[string](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'IntuneUserName' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'IntuneUserName');
                        'DateSet'       =Try{[datetime](Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT\Intune\UserInfo' -f ($x)) -Name 'DateSet' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'DateSet')}Catch{[datetime]::MinValue};
                    }
                }) | Where-Object {-not([string]::IsNullOrEmpty($_.IntuneUserSID) -or [string]::IsNullOrEmpty($_.IntuneUserName))} | Sort-Object -Property 'DateSet' -Descending:$false | Select-Object -Last 1
            )


            # Get Intune User SID
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserSID' -Value (
                [string]$(
                    $Local:SID = [string]::Empty
                    # Try by registry values in HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo
                    if (-not([string]::IsNullOrEmpty([string]($IntuneUser | Select-Object -ExpandProperty 'IntuneUserSID')))) {
                        $Local:SID = [string]($IntuneUser | Select-Object -ExpandProperty 'IntuneUserSID')
                    }

                    # If no valid SID yet, try Registry::HKEY_USERS
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.'Length'))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
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
                                $Local:SIDs = [string[]]@([string[]]@($Local:SIDsFromRegistryAll) | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT' -f ($_))})
                                # If none or more than 1 where found - Try getting only SIDs with AAD joined info in HKU (HKCU) registry
                                if (@($Local:SIDs).'Count' -le 0 -or @($Local:SIDs).'Count' -ge 2) {
                                    $Local:SIDs = [string[]]@([string[]]@($Local:SIDsFromRegistryAll) | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_))})
                                }
                                # If none or more than 1 where found - Try matching Tenant ID for AAD joined HKLM with Tenant ID for AAD joined HKU (HKCU)
                                if (@($Local:SIDs).'Count' -le 0 -or @($Local:SIDs).'Count' -ge 2) {
                                    if (-not([string]::IsNullOrEmpty(($Local:TenantGUIDFromHKLM = [string]$($x='Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'; Get-ItemProperty -Path ('{0}\{1}' -f ($x,[string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantId'))))) {
                                        $Local:SIDs = [string[]]@(@($Local:SIDsFromRegistryAll) | Where-Object {$Local:TenantGUIDFromHKLM -eq ([string]$($x=[string]('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_)); Get-ItemProperty -Path ('{0}\{1}' -f ($x,([string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]})))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantDomain'))})
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
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.'Length'))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
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
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.'Length'))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
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
                    # Help Variables
                    $Local:UN = [string]::Empty

                    # Try by registry values in HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo
                    if (-not([string]::IsNullOrEmpty($IntuneUser.'IntuneUserName'))) {
                        $Local:UN = [string]($IntuneUser.'IntuneUserName')
                    }
                
                    # If no valid UN yet, try by convertid $Script:StrIntuneUserSID to "Domain\Username"
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3 -and (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID)))) {
                        $Local:UN = [string]$(Try{[System.Security.Principal.SecurityIdentifier]::new($Script:StrIntuneUserSID).Translate([System.Security.Principal.NTAccount]).Value}Catch{[string]::Empty})
                    }

                    # If no valid UN yet, try by Registry::HKEY_USERS\$Script:StrIntuneUserSID\Volatile Environment
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3-and (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID)))) {
                        $Local:UN = [string]$(Try{$Local:x = Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrIntuneUserSID)) -Name 'USERDOMAIN','USERNAME' -ErrorAction 'SilentlyContinue';('{0}\{1}' -f ([string]($Local:x | Select-Object -ExpandProperty 'USERDOMAIN'),[string]($Local:x | Select-Object -ExpandProperty 'USERNAME')))}Catch{[string]::Empty})
                    }
                
                    # If no valid UN yet, try by running process Explorer.exe - Method 1
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                        $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.'ReturnValue' -eq 0 -and $Owner.'Domain' -notlike 'nt *' -and $Owner.'Domain' -notlike 'nt-*'){('{0}\{1}' -f ($Owner.'Domain',$Owner.'User'))})}) | Select-Object -Unique -First 1)
                    }
                
                    # If no valid UN yet, try by running process Explorer.exe - Method 2
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.'Length' -lt 3) {
                        $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
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
        elseif ((-not($Script:BoolIsSystem)) -and (-not($DeviceContext))) {
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserSID' -Value ([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value'))
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserName' -Value ([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().'Name'))

            #region    Write SID and UserName to HKCU if running in User Context
                # Assets
                $Local:RegPath   = [string]('Registry::HKEY_CURRENT_USER\Software\IronstoneIT\Intune\UserInfo')
                $Local:RegNames  = [string[]]@('IntuneUserSID','IntuneUserName','DateSet')
                $Local:RegValues = [string[]]@($Script:StrIntuneUserSID,$Script:StrIntuneUserName,([string]([datetime]::Now.ToString('o'))))

                # Get Current Info
                $Local:CurrentUserSID     = [string](Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[0] -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty $Local:RegNames[0] -ErrorAction 'SilentlyContinue')
                $Local:CurrentUserName    = [string](Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[1] -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty $Local:RegNames[1] -ErrorAction 'SilentlyContinue')
                $Local:CurrentUserDateSet = [datetime]$(Try{[datetime](Get-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[2] -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty $Local:RegNames[2] -ErrorAction 'SilentlyContinue')}catch{[datetime]::MinValue})

                # Set Info if any of the values does not match wanted values
                if ($Local:CurrentUserSID -ne $Local:RegValues[0] -or $Local:CurrentUserName -ne $Local:RegValues[1] -or $Local:CurrentUserDateSet -eq [datetime]::MinValue) {      
                    if (-not(Test-Path -Path $Local:RegPath)) {
                        $null = New-Item -Path $Local:RegPath -Force -ErrorAction 'Stop'
                    }

                    foreach ($x in [byte[]]@(0 .. [byte]($Local:RegNames.'Length' - 1))) {
                        $null = Set-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[$x] -Value $Local:RegValues[$x] -Force -ErrorAction 'Stop'
                    }
                }
            #endregion Write SID and UserName to HKCU if running in User Context            
        }
        
        
        # Output Intune User and SID if found
        if (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID))) {
            Write-Output -InputObject ('Intune User SID "{0}", Username "{1}".' -f ($Script:StrIntuneUserSID,$Script:StrIntuneUserName))
        }
    #endregion Get SID and "Domain\Username" for Intune User



    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################



# PowerShell Preferences
$VerbosePreference = 'SilentlyContinue'

# Domains, 'lync.com' in the list means 'http://*.lync.com','http://www.*.lync.com','https://*.lync.com','http://www.*.lync.com'
$Domains = [ordered]@{
    # Microsoft sites
    ## Various
    'dynamics.com'=2
    'outlook.com'=2
    'powerbi.com'=2
    'powerapps.com'=2 
    'sway.com'=2
    'onenote.com'=2
    ## Account / General / Multi purpose
    'aadrm.com'=2
    'azure.com'=2
    'azure.net'=2
    'azurerms.com'=2
    'azureedge.net'=2
    'cloudapp.net'=2
    'cloudappsecurity.com'=2
    'live.com'=2
    'microsoft.com'=2
    'microsoftonline.com'=2
    'microsoftonline-p.net'=2
    'microsoftstream.com'=2
    'msecnd.net'=2
    'office.com'=2
    'office.net'=2
    'office365.com'=2
    'trafficmanager.net'=2
    'virtualearth.net'=2
    'windows.com'=2
    'windows.net'=2
    'windowsazure.com'=2
    ## OneDrive for Business and SharePoint
    'log.optimizely.com'=2
    'onedrive.com'=2
    'sharepoint.com'=2
    'sharepointonline.com'=2
    ## Skype for Business and Teams 
    'lync.com'=2
    'sfbassets.com'=2
    'skypeassets.com'=2
    'skypeforbusiness.com'=2
    'skype.com'=2
    ## Yammer
    'assets-yammer.com'=2
    'yammer.com'=2
    'yammerusercontent.com'=2
    ## Seamless Single Sign-In (S-SSO)
    'aadg.windows.net.nsatc.net'=2
    'microsoftazuread-sso.com'=2                   # autologon.microsoftazuread-sso.com
    'msappproxy.net'=2
}
    

# Registry directories
$PathBase = [string]$('Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\{0}')
$Paths = [string[]]$(
    if ($Context -ne 1) {
        [string]$([string]$('Registry::{0}\' -f ([string]$(if([string]::IsNullOrEmpty($Script:StrIntuneUserSID)){'HKEY_CURRENT_USER'}else{'HKEY_USERS\{0}'-f$Script:StrIntuneUserSID}))+$PathBase))
    }
    if ($Context -ge 1) {
        [string]$('Registry::HKEY_LOCAL_MACHINE\'+$PathBase)
    }
)


# Set registry values
foreach ($Domain in [string[]]$($Domains.GetEnumerator().'Name')) {
    foreach ($Path in $Paths) {                      
        # Create Paths Dynamically
        $PathDynamicBase = [string]($Path -f ($Domain))
        $PathsDynamic = [string[]]$($PathDynamicBase,[string]$($PathDynamicBase+'\www.*'))
        
        # Trust both HTTP and HTTPS on intranet (1), HTTPS only on internet (2)
        $Names = [string[]]$(if($Domains.$Domain -le 1){'http'},'https')

        # Set ZoneMap for Domain
        foreach ($PathDynamic in $PathsDynamic) {
            # Create Path if it does not exist
            if(-not(Test-Path -Path $PathDynamic)){$null = New-Item -Path $PathDynamic -ItemType 'Directory' -Force}
                   
            # Set ZoneMap for domain
            foreach ($Name in $Names) {
                # Set-ItemProperty
                Set-ItemProperty -Path $PathDynamic -Name $Name -Value $Domains.$Domain -Type 'DWord' -Force

                Write-Verbose -Message ('Set-ItemProperty -Path "{0}" -Name "{1}" -Value "{2}" -Type "DWord" -Force{3}   Success? {4}.' -f ($PathDynamic,$Name,$Domains.$Domain,"`r`n",$?.ToString()))

                # Write out success
                Write-Output -InputObject ('Adding "{0}://{1}*.{2}" to InternetExplorer Zone Map. Success? {3}' -f ($Name,$(if($PathDynamic -like '*\www.?'){'www.'}),$Domain,$?.ToString()))
            }
        }
    }
}



################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Set ScriptSuccess to false
    $null = Set-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'ScriptSuccess' -Value ([bool]$($false))
    # Construct Message
    ## Generic 
    $ErrorMessage = [string]$('{0}Finished with errors:' -f ("`r`n"))
    $ErrorMessage += [string]$('{0}# Exception:{0}{1}' -f ("`r`n",$_.'Exception'))
    ## Dynamically add info to the error message
    foreach ($ParentProperty in [string[]]$($_ | Get-Member -MemberType 'Property' | Select-Object -ExpandProperty 'Name')) {
        if ($_.$ParentProperty) {
            $ErrorMessage += ('{0}# {1}:' -f ("`r`n",$ParentProperty))
            foreach ($ChildProperty in [string[]]$($_.$ParentProperty | Get-Member -MemberType 'Property' | Select-Object -ExpandProperty 'Name')) {
                ### Build ErrorValue
                $ErrorValue = [string]::Empty
                if ($_.$ParentProperty.$ChildProperty -is [System.Collections.IDictionary]) {
                    foreach ($Name in [string[]]$($_.$ParentProperty.$ChildProperty.GetEnumerator().'Name')) {
                        $ErrorValue += ('{0} = {1}{2}' -f ($Name,[string]$($_.$ParentProperty.$ChildProperty.$Name),"`r`n"))
                    }
                }
                else {
                    $ErrorValue = [string]$($_.$ParentProperty.$ChildProperty)
                }
                if (-not[string]::IsNullOrEmpty($ErrorValue)) {
                    $ErrorMessage += ('{0}## {1}\{2}:{0}{3}' -f ("`r`n",$ParentProperty,$ChildProperty,$ErrorValue.Trim()))
                }
            }
        }
    }
    ## Last exit code
    if (-not[string]::IsNullOrEmpty($LASTEXITCODE)) {
        $ErrorMessage += ('{0}# Last exit code:{0}{1}' -f ("`r`n",$LASTEXITCODE))
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
        $SIDsLoggedInUsers = [string[]]$(([string[]]@(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique | ForEach-Object -Process {Try{[System.Security.Principal.NTAccount]::new(($_)).Translate([System.Security.Principal.SecurityIdentifier]).'Value'}Catch{}} | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))}),[string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value')) | Select-Object -Unique)

        foreach ($SID in $RegistryLoadedProfiles) {
            # If SID is found in $SIDsLoggedInUsers - Don't Unload Hive
            if ([bool]$(([string[]]@($SIDsLoggedInUsers | ForEach-Object -Process {$_.Trim().ToUpper()})).Contains($SID.Trim().ToUpper()))) {
                Write-Output -InputObject ('User with SID "{0}" is currently logged in, will not unload registry hive.' -f ($SID))
            }
            # If SID is not found in $SIDsLoggedInUsers - Unload Hive
            else {
                $PathUserHive = [string]('Registry::HKEY_USERS\{0}' -f ($SID))
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
#endregion Don't touch this