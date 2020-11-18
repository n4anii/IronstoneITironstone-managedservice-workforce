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


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Set-IEDefaultSearchProvider(Google)'

# Settings - PowerShell - Output Preferences
$DebugPreference       = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'Continue'


#region    Don't Touch This
# Settings - PowerShell - Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'

# Settings - PowerShell - Behaviour
$ErrorActionPreference = 'Continue'

# Dynamic Variables - Process & Environment
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'})

# Dynamic Variables - User
[string] $StrIsAdmin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
[string] $StrUserName      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
[string] $SidCurrentUser   = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
[string] $SidSystemUser    = 'S-1-5-18'
[bool] $CurrentUserCorrect = $(
    if($DeviceContext -and $SIDCurrentUser -eq $SIDSystemUser){$true}
    elseif (-not($DeviceContext) -and $SIDCurrentUser -ne $SIDSystemUser){$true}
    else {$false}
)

# Dynamic Logging Variables
$Timestamp    = [DateTime]::Now.ToString('yyMMdd-HHmmssffff')
$PathDirLog   = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($(if($DeviceContext -and $CurrentUserCorrect){$env:ProgramW6432}else{$env:APPDATA})))
$PathFileLog  = ('{0}{1}-{2}bit-{3}.txt' -f ($PathDirLog,$NameScriptFull,$ProcessArchitecture,$Timestamp))

# Start Transcript
if (-not(Test-Path -Path $PathDirLog)) {New-Item -ItemType 'Directory' -Path $PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog

# Output User Info, Exit if not $CurrentUserCorrect
Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}. Running as correct user? {3}.' -f ($StrUserName,$StrIsAdmin,$DeviceContext.ToString(),$CurrentUserCorrect.ToString()))
if (-not($CurrentUserCorrect)){Throw 'Not running as correct user!'} 

# Output Process and OS Architecture Info
Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($ProcessArchitecture,$OSArchitecture))


# Wrap in Try/Catch, so we can always end the transcript
Try {    
    # If OS is 64 bit, and PowerShell got launched as x86, relaunch as x64
    if ( (-not([System.Environment]::Is64BitProcess))  -and [System.Environment]::Is64BitOperatingSystem) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args
        }
        exit $lastexitcode
    }
    
    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################


    #region    Settings
        $VerbosePreference = 'Continue'
    #endregion Settings



    #region    Get Current User + New PS Drive for HKU
        # Get Current User as SecurityIdentifier
        [string] $PathDirRootCU = ('HKU:\{0}\' -f ([System.Security.Principal.NTAccount]::new((Get-Process -Name 'Explorer' -IncludeUserName).UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value))
        # Add HKU:\ as PSDrive if not already
        if ((Get-PSDrive -Name 'HKU' -ErrorAction 'SilentlyContinue') -eq $null) {$null = New-PSDrive -PSProvider 'Registry' -Name 'HKU' -Root 'HKEY_USERS'}
    #endregion Get Current User + New PS Drive for HKU



    #region    Main
        # Google as search provider
        [string] $IDGoogle = '{AAAE0891-8409-4828-8996-7F83B5C9A6F3}'
        [string[]] $Dir = @(('HKLM:\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\'),
                            ('HKLM:\SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0}' -f ($IDGoogle)),
                            ('{0}Software\Microsoft\Internet Explorer\SearchScopes' -f ($PathDirRootCU)),
                            ('{0}Software\Microsoft\Internet Explorer\SearchScopes\{1}' -f ($PathDirRootCU,$IDGoogle))
                           )
        [PSCustomObject[]] $RegValues = @(
            # HKEY_LOCAL_MACHINE
                # Default Search Provider: Google
                [PSCustomObject]@{Dir=$Dir[0];Key=[string]'DefaultScope';         Type=[string]'String';Val=[string]'{AAAE0891-8409-4828-8996-7F83B5C9A6F3}';},
                # Add Search Provider: Google
                [PSCustomObject]@{Dir=$Dir[1];Key=[string]'DisplayName';          Type=[string]'String';Val=[string]'Google'},
                [PSCustomObject]@{Dir=$Dir[1];Key=[string]'FaviconPath';          Type=[string]'String';Val=[string]('C:\Users\{0}\AppData\LocalLow\Microsoft\Internet Explorer\Services\search_{1}.ico' -f ($CurrentUserName,$IDGoogle));},
                [PSCustomObject]@{Dir=$Dir[1];Key=[string]'FaviconURL';           Type=[string]'String';Val=[string]'https://www.google.com/favicon.ico';},
                [PSCustomObject]@{Dir=$Dir[1];Key=[string]'OSDFileURL';           Type=[string]'String';Val=[string]'https://www.microsoft.com/cms/api/am/binary/RWilsM';},
                [PSCustomObject]@{Dir=$Dir[1];Key=[string]'ShowSearchSuggestions';Type=[string]'DWord'; Val=[byte]1;},
                [PSCustomObject]@{Dir=$Dir[1];Key=[string]'SortIndex';            Type=[string]'DWord'; Val=[byte]1;},
                [PSCustomObject]@{Dir=$Dir[1];Key=[string]'SuggestionsURL';       Type=[string]'String';Val=[string]'https://www.google.com/complete/search?q={searchTerms}&client=ie8&mw={ie:maxWidth}&sh={ie:sectionHeight}&rh={ie:rowHeight}&inputencoding={inputEncoding}&outputencoding={outputEncoding}';},
                [PSCustomObject]@{Dir=$Dir[1];Key=[string]'URL';                  Type=[string]'String';Val=[string]'https://www.google.com/search?q={searchTerms}&sourceid=ie7&rls=com.microsoft:{language}:{referrer:source}&ie={inputEncoding?}&oe={outputEncoding?}';},
            # HKEY_CURRENT_USER
                # Default Search Provider: Google
                [PSCustomObject]@{Dir=$Dir[2];Key=[string]'DefaultScope';         Type=[string]'String';Val=[string]'{AAAE0891-8409-4828-8996-7F83B5C9A6F3}';}               
        )


        #region    Remove other search providers
            # HKEY_LOCAL_MACHINE
                Get-ChildItem -Path $Dir[0] | Where-Object {$_.PSChildName -ne $IDGoogle} | ForEach-Object {Remove-Item -Path $_.Name.Replace('HKEY_LOCAL_MACHINE','HKLM:') -Recurse}
            # HKEY_CURRENT_USER
                Get-ChildItem -Path $Dir[2] | Select-Object -Property * | ForEach-Object {Remove-Item -Path ('{0}\{1}' -f ($Dir[2],$_.PSChildName)) -Recurse}         
        #endregion Remove other search providers



        #region    Set Registry Values
        foreach ($Item in $RegValues) {
            # Create path variable, switch HKCU: with HKU:
            [string] $TempPath = $Item.Dir
            if ($TempPath -like 'HKCU:\*') {
                $TempPath = $TempPath.Replace('HKCU:\',$PathDirRootCU)
            }
            Write-Verbose -Message ('{0}' -f ($TempPath))

            # Create path if it does not exist
            if (-Not(Test-Path -Path $TempPath)) {                
                $null = New-Item -Path $TempPath -ItemType 'Directory' -Force
                Write-Verbose -Message ('   Path does not exist, creating it. Success? {0}' -f ($?))
            }
            
            # Create key and set value
            Set-ItemProperty -Path $TempPath -Name $Item.Key -Value $Item.Val -Type $Item.Type -Force
            Write-Verbose -Message ('   Key: {0} | Value: {1} | Type: {2} | Success? {3}' -f ($Item.Key,$Item.Val,$Item.Type,$?))
        }
        #endregion Set Registry Values
    #endregion Main


################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
    $ErrorMessage += " `n"
    $ErrorMessage += 'Exception: '
    $ErrorMessage += $_.Exception
    $ErrorMessage += " `n"
    $ErrorMessage += 'Activity: '
    $ErrorMessage += $_.CategoryInfo.Activity
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Category: '
    $ErrorMessage += $_.CategoryInfo.Category
    $ErrorMessage += " `n"
    $ErrorMessage += 'Error Reason: '
    $ErrorMessage += $_.CategoryInfo.Reason
    Write-Error -Message $ErrorMessage
}
Finally {
    Stop-Transcript
}
#endregion Don't touch this