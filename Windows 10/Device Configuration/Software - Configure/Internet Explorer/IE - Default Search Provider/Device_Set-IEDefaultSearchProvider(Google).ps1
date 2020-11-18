<#

.SYNOPSIS
Sets Google as default search provider in Internet Explorer.


.DESCRIPTION
Sets Google as default search provider in Internet Explorer.


.NOTES
- You need to run this script in the DEVICE context in Intune.
- Use together with OMA-URI to disable ability to change default search provider
	Intune Values
		OMA Name	DisableSearchProviderChange
		Desc		Disables ability to change default search provider.
		OMA-URI		./Device/Vendor/MSFT/Policy/Config/InternetExplorer/DisableSearchProviderChange
		Value		<enabled/>
	Info
		Scope		Device, User
		GP Name		NoSearchProvider
		Reg Key		Software\Policies\Microsoft\Internet Explorer\Infodelivery\Restrictions
		Note		Enable for Device & User	
		MS DOC		https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-internetexplorer#internetexplorer-disablesearchproviderchange
#>


# Script Name & Settings
$NameScript    = [string] 'Set-IEDefaultSearchProvider(Google)'
$DeviceContext = [bool]   $true

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
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsAdmin'  -Value ([bool]$([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsSystem' -Value ([bool]$(([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) -eq ([string]('S-1-5-18'))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsCorrectUser' -Value ([bool]$(if($Script:DeviceContext -and $Script:BoolIsSystem){$true}elseif((-not($DeviceContext)) -and (-not($Script:BoolIsSystem))){$true}else{$false}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserNameRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name))

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
    Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}. Running as correct user? {3}.' -f ($Script:StrUserNameRunningAs,$Script:BoolIsAdmin.ToString(),$Script:DeviceContext.ToString(),$Script:BoolIsCorrectUser.ToString()))
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

    # Get Intune User SID
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserIntuneSID' -Value (
        [string]$(
            if ($Script:BoolIsSystem) {
                $Local:SID = [string]$(Try{$Local:SIDs = [string[]]@(Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -like 'S-1-12-*' -and $_ -notlike '*_Classes'});if(@($Local:SIDs).Count -eq 1){$Local:SIDs}else{[string]::Empty}}Catch{[string]::Empty})
                if ([string]::IsNullOrEmpty($Local:SID)) {
                    $Local:SID = [string]$(Try{[System.Security.Principal.NTAccount]::new(([string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1))).Translate([System.Security.Principal.SecurityIdentifier]).Value}catch{[string]::Empty})
                }
                if ([string]::IsNullOrEmpty($Local:SID)) {
                    $Local:SID = [string]$(Try{[System.Security.Principal.NTAccount]::new([string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName') | Select-Object -Unique -First 1)).Translate([System.Security.Principal.SecurityIdentifier]).Value}catch{[string]::Empty})
                }
                if ([string]::IsNullOrEmpty($Local:SID)) {
                    $Local:SID = [string]$(Try{Get-ChildItem -Path 'Registry::HKEY_USERS' -Recurse:$false | Select-Object -ExpandProperty 'Name' | ForEach-Object {$_.Split('\')[-1]} | Where-Object {$_ -notlike '.DEFAULT' -and $_ -notlike 'S-1-5-??' -and $_ -notlike '*_Classes'} | Sort-Object -Descending:$false | Select-Object -Last 1}Catch{[string]::Empty})
                }
                if ([string]::IsNullOrEmpty($Local:SID) -or $Local:SID.Length -gt 70 -or $Local:SID -like '* *') {
                    Throw 'ERROR: Did not manage to get Intune user SID from SYSTEM context'
                }
                else {
                    $Local:SID
                }
            }
            else {
                [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)
            }
        )
    )
    Write-Output -InputObject ('Getting Intune User SID (Security Identifier). Success? {0}, Value? "{1}".' -f (([bool](-not([string]::IsNullOrEmpty($Script:StrUserIntuneSID)))).ToString(),$Script:StrUserIntuneSID))
    
    # Get Intune User Domain\UserName
    $null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserIntuneName' -Value (
        [string]$(
            if ($Script:BoolIsSystem) {
                $Local:UN = [string]::Empty
                if ((-not([string]::IsNullOrEmpty($Script:StrUserIntuneSID)))) {
                    $Local:UN = [string]$(Try{[System.Security.Principal.SecurityIdentifier]::new($Script:StrUserIntuneSID).Translate([System.Security.Principal.NTAccount]).Value}Catch{[string]::Empty})
                }
                if ([string]::IsNullOrEmpty($Local:UN)){
                    $Local:UN = [string]$(Try{[string]([string[]]@(Get-WmiObject -Class 'Win32_Process' -Filter "Name='Explorer.exe'" -ErrorAction 'SilentlyContinue' | ForEach-Object {$($Owner = $_.GetOwner();if($Owner.ReturnValue -eq 0){('{0}\{1}' -f ($Owner.Domain,$Owner.User))})}) | Select-Object -Unique -First 1)}Catch{[string]::Empty})   
                }
                if ([string]::IsNullOrEmpty($Local:UN)) {
                    $Local:UN = [string]$(Try{[string]([string[]]@(Get-Process -Name 'explorer' -IncludeUserName -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'UserName') | Select-Object -Unique -First 1)}Catch{[string]::Empty})
                }   
                if ([string]::IsNullOrEmpty($Local:UN) -and (-not([string]::IsNullOrEmpty($Script:StrUserIntuneSID)))) {
                    $Local:UN = [string]$(Try{$Local:x = Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrUserIntuneSID)) -Name 'USERDOMAIN','USERNAME';('{0}\{1}' -f ([string]($Local:x | Select-Object -ExpandProperty 'USERDOMAIN'),[string]($Local:x | Select-Object -ExpandProperty 'USERNAME')))}Catch{[string]::Empty}) 
                }
                if ([string]::IsNullOrEmpty($Local:UN) -or $Local:UN.Length -lt 3){
                    Throw 'ERROR: Did not manage to get "Domain"\"UserName" for Intune User.'
                }
                else {
                    $Local:UN
                }
            }
            else {
                [string]([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
            }
        )
    )
    Write-Output -InputObject ('Getting Intune User "Domain"\"Username". Success? {0}, Value? "{1}".' -f (([bool](-not([string]::IsNullOrEmpty($Script:StrUserIntuneName)))).ToString(),$Script:StrUserIntuneName))

    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################




    #region    Settings
        $VerbosePreference = 'Continue'
    #endregion Settings


    #region    Assets
        $PathDirUserProfile = [string]$(Get-ItemProperty -Path ('Registry::HKEY_USERS\{0}\Volatile Environment' -f ($Script:StrUserIntuneSID)) -Name 'USERPROFILE' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'USERPROFILE'; if(-not($?)){('{0}\Users\{1}' -f ($env:SystemDrive,$Script:StrUserIntuneName.Split('\')[-1]))})
    #endregion Assets


    #region    Main
        # Google as search provider
        $IDGoogle = [string]('{AAAE0891-8409-4828-8996-7F83B5C9A6F3}')
        $Paths    = [string[]]@(
            ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\SearchScopes'),
            ('Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0}' -f ($IDGoogle)),
            ('Registry::HKEY_USERS\{0}\Software\Microsoft\Internet Explorer\SearchScopes' -f ($Script:StrUserIntuneSID)),
            ('Registry::HKEY_USERS\{0}\Software\Microsoft\Internet Explorer\SearchScopes\{1}' -f ($Script:StrUserIntuneSID,$IDGoogle))
        )
        $RegValues = [PSCustomObject[]]@(
            # HKEY_LOCAL_MACHINE
                # Set Default Search Provider: Google
                [PSCustomObject]@{Path=$Paths[0];Name=[string]'DefaultScope';         Type=[string]'String';Value=[string]'{AAAE0891-8409-4828-8996-7F83B5C9A6F3}';},
                # Add Search Provider: Google
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'DisplayName';          Type=[string]'String';Value=[string]'Google'},
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'FaviconPath';          Type=[string]'String';Value=[string]('{0}\AppData\LocalLow\Microsoft\Internet Explorer\Services\search_{1}.ico' -f ($PathDirUserProfile,$IDGoogle));},
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'FaviconURL';           Type=[string]'String';Value=[string]'https://www.google.com/favicon.ico';},
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'FaviconURLFallback';   Type=[string]'String';Value=[string]'https://www.google.com/favicon.ico';},
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'OSDFileURL';           Type=[string]'String';Value=[string]'https://www.microsoft.com/cms/api/am/binary/RWilsM';},
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'ShowSearchSuggestions';Type=[string]'DWord'; Value=[byte]1;},
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'SortIndex';            Type=[string]'DWord'; Value=[byte]1;},
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'SuggestionsURL';       Type=[string]'String';Value=[string]'https://www.google.com/complete/search?q={searchTerms}&client=ie8&mw={ie:maxWidth}&sh={ie:sectionHeight}&rh={ie:rowHeight}&inputencoding={inputEncoding}&outputencoding={outputEncoding}';},
                [PSCustomObject]@{Path=$Paths[1];Name=[string]'URL';                  Type=[string]'String';Value=[string]'https://www.google.com/search?q={searchTerms}&sourceid=ie7&rls=com.microsoft:{language}:{referrer:source}&ie={inputEncoding?}&oe={outputEncoding?}';},
            # HKEY_CURRENT_USER
                # Set Default Search Provider: Google
                [PSCustomObject]@{Path=$Paths[2];Name=[string]'DefaultScope';         Type=[string]'String';Value=[string]'{AAAE0891-8409-4828-8996-7F83B5C9A6F3}';},
                # Add Search Provider: Google
                [PSCustomObject]@{Path=$Paths[3];Name=[string]'FaviconURL';           Type=[string]'String';Value=[string]'https://www.google.com/favicon.ico';},
                [PSCustomObject]@{Path=$Paths[3];Name=[string]'FaviconURLFallback';   Type=[string]'String';Value=[string]'https://www.google.com/favicon.ico';}               
        )


        #region    Remove other search providers
            # HKEY_LOCAL_MACHINE
                Get-ChildItem -Path $Paths[0] | Where-Object {$_.PSChildName -ne $IDGoogle} | ForEach-Object {Remove-Item -Path $_.Name.Replace('HKEY_LOCAL_MACHINE','Registry::HKEY_LOCAL_MACHINE') -Recurse -Force}
            # HKEY_CURRENT_USER
                Get-ChildItem -Path $Paths[2] | Select-Object -Property * | ForEach-Object {Remove-Item -Path ('{0}\{1}' -f ($Paths[2],$_.PSChildName)) -Recurse -Force}         
        #endregion Remove other search providers



        #region    Set Registry Values from SYSTEM / DEVICE context
        foreach ($Item in $RegValues) {
            Write-Verbose -Message ('Path = "{0}"' -f ($Item.Path))
            
            # Check if $Path exist, create it if not
            if (-not(Test-Path -Path $Item.Path)){
                $null = New-Item -Path $Item.Path -ItemType 'Directory' -Force -ErrorAction 'Stop'
                Write-Verbose -Message ('   Path did not exist. Successfully created it? {0}.' -f (($?).ToString()))
            }
        
            # Set Value / ItemPropery
            $null = Set-ItemProperty -Path $Item.Path -Name $Item.Name -Value $Item.Value -Type $Item.Type -Force
            Write-Verbose -Message ('   Name: {0} | Value: {1} | Type: {2} | Success? {3}' -f ($Item.Name,$Item.Value,$Item.Type,$?.ToString()))
        }
        #endregion Set Registry Values from SYSTEM / DEVICE context
    #endregion Main




################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = [string]('{0} finished with errors:' -f ($Script:NameScriptFull))
    $ErrorMessage += ('{0}{0}Exception:{0}' -f ("`r`n"))
    $ErrorMessage += $_.Exception
    $ErrorMessage += ('{0}{0}Activity:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += ('{0}{0}Error Category:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += ('{0}{0}Error Reason:{0}' -f ("`r`n"))
    $ErrorMessage += $_.CategoryInfo.Reason
    # Write Error Message
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}
#endregion Don't touch this