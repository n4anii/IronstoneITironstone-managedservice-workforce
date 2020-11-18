<#
    .NAME
        Device_Configure-O365&OD4B.ps1

    .SYNAPSIS
        Will configure Office 365 and OneDrive to Ironstone default for BPTW.

    .DESCRIPTION
        Will configure Office 365 and OneDrive to Ironstone default for BPTW.
            * Office 365 - General settings like file format, disable wizards etc.
            * OneDrive - Silent Auto Configuration
            * OneDrive - Known Folder Move - Automatically with notification and wizard (Microsoft best practice)

    .NOTES
        * In Intune, remember to set "Run this script using the logged in credentials"  according to the $DeviceContext variable.
            * Intune -> Device Configuration -> PowerShell Scripts -> $NameScriptFull -> Properties -> "Run this script using the logged in credentials"
            * DEVICE (Local System) or USER (Logged in user).
        * Only edit $NameScript and add your code in the #region Your Code Here.
        * You might want to touch "Settings - PowerShell - Output Preferences" for testing / development. 
            * $VerbosePreference, eventually $DebugPreference, to 'Continue' will print much more details.
#>


# Script Settings
$OD4BKFMEnable         = [bool]   $false

# Script Name & Settings
$NameScript            = [string] 'Configure-O365&OD4B'
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
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserNameRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrSIDRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsAdmin'  -Value ([bool]$([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsSystem' -Value ([bool]$($Script:StrSIDRunningAs -like ([string]$('S-1-5-18'))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsCorrectUser' -Value ([bool]$(if($Script:DeviceContext -and $Script:BoolIsSystem){$true}elseif(((-not($DeviceContext))) -and (-not($Script:BoolIsSystem))){$true}else{$false}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolWriteToHKCUFromSystem' -Value ([bool]$(if($DeviceContext -and $WriteToHKCUFromSystem){$true}else{$false}))

# Dynamic Variables - Logging
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'Timestamp' -Value ([string]$([datetime]::Now.ToString('yyMMdd-HHmmssffff')))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathDirLog' -Value ([string]$('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ([string]$(if($BoolIsSystem){$env:ProgramW6432}else{[System.Environment]::GetEnvironmentVariable('AppData')}))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathFileLog' -Value ([string]$('{0}{1}-{2}bit-{3}.txt' -f ($Script:PathDirLog,$Script:NameScriptFull,$Script:StrArchitectureProcess,$Script:Timestamp)))

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
        if ($myInvocation.Line) {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile $myInvocation.Line}
        else {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args}
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
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                        # Get all potential SIDs from Registry::HKEY_USERS
                        $Local:SIDsFromRegistryAll = [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -like 'S-1-12-*' -and $_ -notlike '*_Classes' -and $Local:LengthInterval.Contains([byte]$_.Length)})
                        $Local:SID = [string]$(
                            # If none where found - Return emtpy string: Finding SID by registry will not be possible
                            if (@($Local:SIDsFromRegistryAll).Count -le 0) {
                                [string]::Empty
                            }
                            # If only one where found - Return it
                            elseif (@($Local:SIDsFromRegistryAll).Count -eq 1) {
                                [string]([string[]]@($Local:SIDsFromRegistryAll | Select-Object -First 1))
                            }
                            # If multiple where found - Try to filter out unwanted SIDs
                            else {
                                # Try to get all where IronstoneIT folder exist withing HKU (HKCU) registry
                                $Local:SIDs = [string[]]@([string[]]@($Local:SIDsFromRegistryAll) | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\IronstoneIT' -f ($_))})
                                # If none or more than 1 where found - Try getting only SIDs with AAD joined info in HKU (HKCU) registry
                                if (@($Local:SIDs).Count -le 0 -or @($Local:SIDs).Count -ge 2) {
                                    $Local:SIDs = [string[]]@([string[]]@($Local:SIDsFromRegistryAll) | Where-Object {Test-Path -Path ('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_))})
                                }
                                # If none or more than 1 where found - Try matching Tenant ID for AAD joined HKLM with Tenant ID for AAD joined HKU (HKCU)
                                if (@($Local:SIDs).Count -le 0 -or @($Local:SIDs).Count -ge 2) {
                                    if (-not([string]::IsNullOrEmpty(($Local:TenantGUIDFromHKLM = [string]$($x='Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'; Get-ItemProperty -Path ('{0}\{1}' -f ($x,[string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]}))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantId'))))) {
                                        $Local:SIDs = [string[]]@(@($Local:SIDsFromRegistryAll) | Where-Object {$Local:TenantGUIDFromHKLM -eq ([string]$($x=[string]('Registry::HKEY_USERS\{0}\Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\AADNGC' -f ($_)); Get-ItemProperty -Path ('{0}\{1}' -f ($x,([string](Get-ChildItem -Path $x -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]})))) -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantDomain'))})
                                    }
                                }
                                if(@($Local:SIDs).Count -eq 1){
                                    [string]([string[]]@($Local:SIDs | Select-Object -First 1))
                                }
                                else{
                                    [string]::Empty
                                }
                            }
                        )
                    }

                    # If no valid SID yet, try by running process "Explorer"
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
                        $Local:SID = [string]$(
                            $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0 -and $Owner.Domain -notlike 'nt *' -and $Owner.Domain -notlike 'nt-*'){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1)
                            if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
                                $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
                            }
                            if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
                                [string]::Empty
                            }
                            else {
                                Try{
                                    $Local:SID = [string]([System.Security.Principal.NTAccount]::new($Local:UN).Translate([System.Security.Principal.SecurityIdentifier]).Value)
                                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
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
                    if ([string]::IsNullOrEmpty($Local:SID) -or (-not($Local:LengthInterval.Contains([byte]$Local:SID.Length))) -or (-not(Test-Path -Path ('Registry::HKEY_USERS\{0}' -f ($Local:SID)) -ErrorAction 'SilentlyContinue'))) {
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
                    if (-not([string]::IsNullOrEmpty($IntuneUser.IntuneUserName))) {
                        $Local:UN = [string]($IntuneUser.IntuneUserName)
                    }
                
                    # If no valid UN yet, try by convertid $Script:StrIntuneUserSID to "Domain\Username"
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3 -and (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID)))) {
                        $Local:UN = [string]$(Try{[System.Security.Principal.SecurityIdentifier]::new($Script:StrIntuneUserSID).Translate([System.Security.Principal.NTAccount]).Value}Catch{[string]::Empty})
                    }

                    # If no valid UN yet, try by Registry::HKEY_USERS\$Script:StrIntuneUserSID\Volatile Environment
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3-and (-not([string]::IsNullOrEmpty($Script:StrIntuneUserSID)))) {
                        $Local:UN = [string]$(Try{$Local:x = Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrIntuneUserSID)) -Name 'USERDOMAIN','USERNAME' -ErrorAction 'SilentlyContinue';('{0}\{1}' -f ([string]($Local:x | Select-Object -ExpandProperty 'USERDOMAIN'),[string]($Local:x | Select-Object -ExpandProperty 'USERNAME')))}Catch{[string]::Empty})
                    }
                
                    # If no valid UN yet, try by running process Explorer.exe - Method 1
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
                        $Local:UN = [string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0 -and $Owner.Domain -notlike 'nt *' -and $Owner.Domain -notlike 'nt-*'){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1)
                    }
                
                    # If no valid UN yet, try by running process Explorer.exe - Method 2
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
                        $Local:UN = [string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName' | Where-Object {$_ -notlike 'nt *' -and $_ -notlike 'nt-*'}) | Select-Object -Unique -First 1)
                    }                   

                    # If no valid UN yet, throw Error
                    if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3) {
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
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserSID' -Value ([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value))
            $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrIntuneUserName' -Value ([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().Name))

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

                    foreach ($x in [byte[]]@(0 .. [byte]($Local:RegNames.Length - 1))) {
                        $null = Set-ItemProperty -Path $Local:RegPath -Name $Local:RegNames[$x] -Value $Local:RegValues[$x] -Force -ErrorAction 'Stop'
                    }
                }
            #endregion Write SID and UserName to HKCU if running in User Context            
        }
        Write-Output -InputObject ('Intune User SID "{0}", Username "{1}".' -f ($Script:StrIntuneUserSID,$Script:StrIntuneUserName))
    #endregion Get SID and "Domain\Username" for Intune User



    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################





    #region    Functions
        #region    Set Registry Values from ANY context
        function WriteTo-Registry {
            [CmdletBinding()]
            Param(
                [Parameter(Mandatory=$true)]
                [ValidateNotNullOrEmpty()]
                [PSCustomObject[]] $RegistryValues,

                [Parameter(Mandatory=$false)]
                [ValidateSet($true,$false)]
                [bool] $WriteChanges = [bool] $true
            )
    
    
            #region    Catch and Fix common errors
                # Fix common errors
                foreach ($Item in @($RegistryValues)) {
                    foreach ($X in @('///','//','/','\\\','\\')) {
                        $Item.Path = $Item.Path.Replace($X,'\')
                    }
                }

                # Only continue if $CountValidPaths = @($RegistryValues).Count
                $Paths = [string[]]@($RegistryValues | Select-Object -ExpandProperty 'Path')
        
                # Valid Patterns
                $StringValidPathsHKCU = [string[]]@('HKCU:\*','Registry::HKCU\*','Registry::HKEY_CURRENT_USER\*')
                $StringValidPathsHKLM = [string[]]@('HKLM:\*','Registry::HKLM\*','Registry::HKEY_LOCAL_MACHINE\*')
                $StringValidPathsHKU  = [string[]]@('HKU:\*', 'Registry::HKU\*', 'Registry::HKEY_USERS\*')
                $StringValidPathsAll  = [string[]]@($StringValidPathsHKCU + $StringValidPathsHKLM + $StringValidPathsHKU)

                # Count Valid Patterns
                $ValidHKCU = $ValidHKLM = $ValidHKU = $ValidAll = [uint16]::MinValue

                $CountValidPathsAll = [uint16]$(
                    :ForEachPath foreach ($Path in @($RegistryValues | Select-Object -ExpandProperty 'Path')) {
                        foreach ($Pattern in @($StringValidPathsHKCU)) {if ($Path -like $Pattern) {$ValidHKCU++;$ValidAll++;Continue ForEachPath}}
                        foreach ($Pattern in @($StringValidPathsHKLM)) {if ($Path -like $Pattern) {$ValidHKLM++;$ValidAll++;Continue ForEachPath}}
                        foreach ($Pattern in @($StringValidPathsHKU))  {if ($Path -like $Pattern) {$ValidHKU++; $ValidAll++;Continue ForEachPath}}
                    }
                )

                if ($ValidAll -ne @($RegistryValues).Count) {
                    Write-Error -Message 'ERROR: $RegistryValues contains invalid paths.' -ErrorAction 'Stop'
                }
            #endregion Catch and Fix common errors



            #region    Make sure we have priveliges to perform these Registry Edits     
                $Local:BoolIsAdmin  = [bool]$(Get-Variable -Name 'BoolIsAdmin' -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue';if(-not($?)){([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)})
                $Local:BoolIsSystem = [bool]$(Get-Variable -Name 'BoolIsSystem' -Scope 'Script' -ValueOnly -ErrorAction 'SilentlyContinue';if(-not($?)){(([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) -eq ([string]('S-1-5-18')))})
                Write-Verbose -Message ('Is Admin? {0}, Is System? {1}.' -f ($Local:BoolIsAdmin,$Local:BoolIsSystem))

                # HKLM = Need Admin Permissions
                if ($ValidHKLM -ge 1 -and (-not($Local:BoolIsAdmin))) {
                    Throw 'ERROR: Can`t write to HKLM without Admin permissions.'
                }
    
                # HKCU or HKU & System Context = Need Admin Permissions
                if ($ValidHKCU -ge 1) {
                    if ($Local:BoolIsSystem) {
                        if ($Local:BoolIsAdmin) {
                            # HKCU from SYSTEM context, using 'Registry::HKEY_USERS'
                            $PathDirRootCU = [string]('Registry::HKEY_USERS\{0}' -f ([string]$(if([string]::IsNullOrEmpty($Script:StrIntuneUserSID)){[System.Security.Principal.NTAccount]::new((Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).Value}else{$Script:StrIntuneUserSID})))
                            if ((-not($?)) -or $PathDirRootCU -eq 'Registry::HKEY_USERS\') {
                                Throw 'ERROR: Did not manage to get required variables to write to HKCU from SYSTEM context.'
                            }
                        }
                        else {
                            Throw 'ERROR: Can`t write to HKCU from System context without admin priveliges.'
                        }
                    }
                }
            #endregion Make sure we have priveliges to perform these Registry Edits

           
            #region    Foreach Item in $RegistryValues
            foreach ($Item in $RegistryValues) {
                #region    Check & Correct Path
                    # Create $Path variable:
                    $Path = [string] $Item.Path
        
                    # Switch HKCU: with HKU:
                    foreach ($Pattern in $StringValidPathsHKCU) {
                        if ($Path -like $Pattern) {
                            $Path = $Path.Replace('HKCU:\',('{0}{1}' -f ($PathDirRootCU,$(if(([string]$PathDirRootCU[-1]) -ne '\'){'\'}))))
                        }
                    }

                    # Replace "HKU:\*" with "Registry::HKEY_USERS\*" because "HKU:\" is not a reistered PSDrive
                    if ($Path -like 'HKU:\*') {$Path = $Path.Replace('HKU:\','Registry::HKEY_USERS')}

                    # Verbose the path
                    Write-Verbose -Message ('Path: "{0}".' -f ($Path))


                    # Check if $Path is valid
                    if ($Path -like '*\\*') {Throw 'Not a valid path! Will not continue.'}
                #endregion Check & Correct Path


                # Check if $Path exist, create it if not
                if ($WriteChanges -and (-not(Test-Path -Path $Path))) {
                    $null = New-Item -Path $Path -ItemType 'Directory' -Force
                    Write-Verbose -Message ('   Path did not exist. Successfully created it? {0}.' -f (([bool] $Local:SuccessCreatePath = $?).ToString()))
                    if (-not($Local:SuccessCreatePath)){Continue}
                }
        
                # Set Value / ItemPropery
                if ($WriteChanges) {Set-ItemProperty -Path $Path -Name $Item.Name -Value $Item.Value -Type $Item.Type -Force}
                Write-Verbose -Message ('   Name: {0} | Value: {1} | Type: {2} | Success? {3}' -f ($Item.Name,$Item.Value,$Item.Type,$?.ToString()))
            }
            #endregion Foreach Item in $RegValues
        }
        #endregion Set Registry Values from ANY context
    #endregion Functions




    #region    Assets
        # Known Folder Move
        if ($OD4BKFMEnable) {
            $TenantId = [string](Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\{0}' -f ((Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo' -ErrorAction 'SilentlyContinue' | Select-Object -First 1 -ExpandProperty 'Name').Split('\')[-1])) -Name 'TenantId' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantId')
            if (-not($?) -or $TenantId -notmatch '^[a-fA-F0-9]{8}[-][a-fA-F0-9]{4}[-][a-fA-F0-9]{4}[-][a-fA-F0-9]{4}[-][a-fA-F0-9]{12}$') {Throw 'ERROR: Could not obtain Tenant Id.'}
        }

        # User dependant
        if ([string]::IsNullOrEmpty($Script:StrIntuneUserSID)){Throw 'ERROR: Could not write to HKCU:\ from System context.'}

        # Generic
        $PathDirRegOfficeHKCU   = [string]('Registry::HKEY_USERS\{0}\Software\Microsoft\Office\16.0' -f ($Script:StrIntuneUserSID))
        $PathDirRegOfficeHKLM   = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Office\16.0')
        $PathDirRegOneDriveHKCU = [string]('Registry::HKEY_USERS\{0}\Software\Microsoft\OneDrive' -f ($Script:StrIntuneUserSID))
        $PathDirRegOneDriveHKLM = [string]('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive')
    


        #region     $RegistryValuesAdd
            $RegistryValuesAdd = [PSCustomObject[]]@(
                <#
                    Office 365
                #>
                # Office 365 / 2016 | HKCU | Common 
                [PSCustomObject]@{Path=[string]'{0}\Common' -f $PathDirRegOfficeHKCU;         Name=[string]'QMEnable';                      Value=[byte]1;          Type=[string]'DWord'},
                # Office 365 / 2016 | HKCU | Common \ General
                [PSCustomObject]@{Path=[string]'{0}\Common\General' -f $PathDirRegOfficeHKCU; Name=[string]'ShownFileFmtPrompt';            Value=[byte]1;          Type=[string]'DWord'},
                [PSCustomObject]@{Path=[string]'{0}\Common\General' -f $PathDirRegOfficeHKCU; Name=[string]'ShownFirstRunOptin';            Value=[byte]1;          Type=[string]'DWord'},
                # Office 365 / 2016 | HKCU | Common \ PTWatson
                [PSCustomObject]@{Path=[string]'{0}\Common\PTWatson' -f $PathDirRegOfficeHKCU;Name=[string]'PTWOptIn';                      Value=[byte]1;          Type=[string]'DWord'},
                # Office 365 / 2016 | HKCU | FirstRun
                [PSCustomObject]@{Path=[string]'{0}\FirstRun' -f $PathDirRegOfficeHKCU;       Name=[string]'BootedRTM';                     Value=[byte]1;          Type=[string]'DWord'},
                [PSCustomObject]@{Path=[string]'{0}\FirstRun' -f $PathDirRegOfficeHKCU;       Name=[string]'DisableMovie';                  Value=[byte]1;          Type=[string]'DWord'},
                # Office 365 / 2016 | HKCU | Registration
                [PSCustomObject]@{Path=[string]'{0}\Registration' -f $PathDirRegOfficeHKCU;   Name=[string]'AcceptAllEulas';                Value=[byte]1;          Type=[string]'DWord'},
                # Office 365 / 2016 | HKLM | Common \ General
                [PSCustomObject]@{Path=[string]'{0}\Common\General' -f $PathDirRegOfficeHKLM; Name=[string]'ShownFileFmtPrompt';            Value=[byte]1;          Type=[string]'DWord'},
                [PSCustomObject]@{Path=[string]'{0}\Common\General' -f $PathDirRegOfficeHKLM; Name=[string]'ShownFirstRunOptin';            Value=[byte]1;          Type=[string]'DWord'},
                # Office 365 / 2016 | HKLM | Registration
                [PSCustomObject]@{Path=[string]'{0}\Registration' -f $PathDirRegOfficeHKLM;   Name=[string]'AcceptAllEulas';                Value=[byte]1;          Type=[string]'DWord'},
        

                <#
                    OneDrive - Silent Autoconfig
                #>

                # OneDrive - Silent Autoconfig - Enable ADAL
                [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKCU;                       Name=[string]'EnableADAL';                    Value=[byte]1;          Type=[string]'DWord'},
                # OneDrive - Silent Autoconfig - Files On Demand
                [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;                       Name=[string]'FilesOnDemandEnabled';          Value=[byte]1;          Type=[string]'DWord'},
                # OneDrive - Silent Autoconfig - Silent Account Config
                [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;                       Name=[string]'SilentAccountConfig';           Value=[byte]1;          Type=[string]'DWord'}
            )


            <#
                OneDrive - Known Folder Move
            #>
            if ($OD4BKFMEnable) {
                $RegistryValuesAdd += [PSCustomObject[]]@(              
                    # OneDrive - Known Folder Move - Silent with Notification & Wizard
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;                       Name=[string]'KFMOptInWithWizard';            Value=[string]$TenantId;Type=[string]'String'},
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;                       Name=[string]'KFMSilentOptIn';                Value=[string]$TenantId;Type=[string]'String'},
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;                       Name=[string]'KFMSilentOptInWithNotification';Value=[byte]1;          Type=[string]'DWord'},
                    # OneDrive - Known Folder Move - Generic
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;                       Name=[string]'KFMBlockOptOut';                Value=[byte]1;          Type=[string]'DWord'}
                )
            }
        #endregion $RegistryValuesAdd



        #region    $RegistryValuesRemove
            $RegistryValuesRemove = [PSCustomObject[]]@(
                [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKCU;Name=[string]'KFMBlockOptIn'},
                [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;Name=[string]'KFMBlockOptIn'}
            )

            if (-not($OD4BKFMEnable)){
                $RegistryValuesRemove += [PSCustomObject[]]@(
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKCU;Name=[string]'KFMOptInWithWizard'},
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;Name=[string]'KFMOptInWithWizard'},
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKCU;Name=[string]'KFMSilentOptIn'},
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;Name=[string]'KFMSilentOptIn'},
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKCU;Name=[string]'KFMBlockOptOut'},
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;Name=[string]'KFMBlockOptOut'}
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKCU;Name=[string]'KFMSilentOptInWithNotification'},
                    [PSCustomObject]@{Path=[string]$PathDirRegOneDriveHKLM;Name=[string]'KFMSilentOptInWithNotification'}
                )
            }
        #endregion $RegistryValuesRemove


    #endregion Assets




    #region    Set Registry Values from SYSTEM / DEVICE context
        #region    Remove
            foreach ($Item in $RegistryValuesRemove) {
                if (-not([string]::IsNullOrEmpty((Get-ItemProperty -Path $Item.Path -Name $Item.Name -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'PSPath')))) {               
                    $null = Remove-ItemProperty -Path $Item.Path -Name $Item.Name -Force
                    Write-Verbose -Message ('Found item "{0}\{1}". Removing. Success? {2}.' -f ($Item.Path,$Item.Name,$?.ToString()))
                }
            }
        #endregion Remove


        #region    Add
            WriteTo-Registry -RegistryValues $RegistryValuesAdd -WriteChanges $true -Verbose
        #endregion Add
    #endregion Set Registry Values from SYSTEM / DEVICE context





################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = [string]('{0} finished with errors:' -f ($Script:NameScriptFull))
    $ErrorMessage += ('{0}{0}Exception:{0}{1}'           -f ("`r`n",$_.Exception))
    $ErrorMessage += ('{0}{0}Activity:{0}{1}'            -f ("`r`n",$_.CategoryInfo.Activity))
    $ErrorMessage += ('{0}{0}Error Category:{0}{1}'      -f ("`r`n",$_.CategoryInfo.Category))
    $ErrorMessage += ('{0}{0}Error Reason:{0}{1}'        -f ("`r`n",$_.CategoryInfo.Reason))
    # Write Error Message
    Write-Error -Message $ErrorMessage
}
Finally {
    # Unload Users' Registry Profiles (NTUSER.DAT) if any were loaded
    if ($Script:BoolIsSystem -and $BoolWriteToHKCUFromSystem -and ([string[]]@($RegistryLoadedProfiles | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))})).Count -gt 0) {
        # Close Regedit.exe if running, can't unload hives otherwise
        $null = Get-Process -Name 'regedit' -ErrorAction 'SilentlyContinue' | ForEach-Object -Process{Stop-Process -InputObject $_ -ErrorAction 'SilentlyContinue'}
            
        # Get all logged in users
        $SIDsLoggedInUsers = [string[]]@(([string[]]@(Get-Process -Name 'explorer' -IncludeUserName | Select-Object -ExpandProperty 'UserName' -Unique | ForEach-Object -Process {Try{[System.Security.Principal.NTAccount]::new(($_)).Translate([System.Security.Principal.SecurityIdentifier]).Value}Catch{}} | Where-Object -FilterScript {-not([string]::IsNullOrEmpty($_))}) + @([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value))) | Select-Object -Unique)

        foreach ($SID in $RegistryLoadedProfiles) {
            # If SID is found in $SIDsLoggedInUsers - Don't Unload Hive
            if ([bool]$(([string[]]@($SIDsLoggedInUsers | ForEach-Object -Process {$_.Trim().ToUpper()})).Contains($SID.Trim().ToUpper()))) {
                Write-Output -InputObject ('User with SID "{0}" is currently logged in, will not unload registry hive.' -f ($SID))
            }
            # If SID is not found in $SIDsLoggedInUsers - Unload Hive
            else {
                $PathUserHive = [string]('Registry::HKEY_USERS\{0}' -f ($SID))
                $null = Start-Process -FilePath ('{0}\reg.exe' -f ([string]([system.environment]::SystemDirectory))) -ArgumentList ('UNLOAD "{0}"' -f ($PathUserHive)) -WindowStyle 'Hidden' -Wait

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
#endregion Don't touch this