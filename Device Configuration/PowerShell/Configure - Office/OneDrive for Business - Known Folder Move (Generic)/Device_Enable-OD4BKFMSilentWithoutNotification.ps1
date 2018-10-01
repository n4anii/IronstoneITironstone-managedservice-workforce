<#
Device_Enable-OD4BKFMSilentWithoutNotification.ps1

.SYNAPSIS
Will enable OneDrive for Business Known Folder Move. Silent config without notifications.

.NOTES
    * In Intune, remember to set "Run this script using the logged in credentials"  according to the $DeviceContext variable.
        * Intune -> Device Configuration -> PowerShell Scripts -> $NameScriptFull -> Properties -> "Run this script using the logged in credentials"
        * DEVICE (Local System) or USER (Logged in user).
    * Only edit $NameScript and add your code in the #region Your Code Here.
    * You might want to touch "Settings - PowerShell - Output Preferences" for testing / development. 
        * $VerbosePreference, eventually $DebugPreference, to 'Continue' will print much more details.

#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Enable-OD4BKFMSilentWithoutNotification'

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
[bool] $BoolIsAdmin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
[string] $StrIsAdmin       = $BoolIsAdmin.ToString()
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
    if ([System.Environment]::Is64BitOperatingSystem -and -not [System.Environment]::Is64BitProcess) {
        write-Output -InputObject (' * Will restart this PowerShell session as x64.')
        if ($myInvocation.Line) {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile $myInvocation.Line}
        else {& ('{0}\sysnative\WindowsPowerShell\v1.0\powershell.exe' -f ($env:windir)) -NonInteractive -NoProfile -File ('{0}' -f ($myInvocation.InvocationName)) $args}
        exit $LASTEXITCODE
    } 
 
    # End the Initialize Region
    Write-Output -InputObject ('**********************')
#endregion Don't Touch This
################################################
#region    Your Code Here
################################################


#region    Assets
    # Generic
    [string] $TenantId   = Get-ItemProperty -Path ('Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\{0}' -f ((Get-ChildItem -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo\' -ErrorAction 'SilentlyContinue' | Select-Object -First 1 -ExpandProperty Name).Split('\')[-1])) -Name 'TenantId' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'TenantId'
    [string] $PathDirReg = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
    
    # Registry Values - Silent without Notification
    [PSCustomObject[]] $RegValues = @(
        [PSCustomObject]@{Path=[string]$PathDirReg;Name=[string]'KFMSilentOptIn';                Value=[string]$TenantId;Type=[string]'String'},
        [PSCustomObject]@{Path=[string]$PathDirReg;Name=[string]'KFMSilentOptInWithNotification';Value=[byte]0;          Type=[string]'DWord'}
    )

    # Registry Values - Remove
    [PSCustomObject[]] $RegValuesRemove = @(
        [PSCustomObject]@{Path=[string]$PathDirReg;Name=[string]'KFMOptInWithWizard'}
    )
#endregion Assets


#region    Set Registry Values from SYSTEM / DEVICE context
    #region    Remove
        foreach ($Item in $RegValuesRemove) {
            if (-not([string]::IsNullOrEmpty((Get-ItemProperty -Path $Item.Path -Name $Item.Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'PSPath')))) {               
                $null = Remove-ItemProperty -Path $Item.Path -Name $Item.Name -Force
                Write-Verbose -Message ('Found item "{0}\{1}". Removing. Success? {2}.' -f ($Item.Path,$Item.Name,$?.ToString()))
            }
        }
    #endregion Remove


    #region    Add
        foreach ($Item in $RegValues) {
            # Create $Path variable, switch HKCU: with HKU:
            [string] $Path = $Item.Path
            if ($Path -like 'HKCU:\*') {$Path = $Path.Replace('HKCU:\',$Script:PathDirRootCU)}
            $Path = $Path.Replace('\\','\')
            Write-Verbose -Message ('Path: "{0}".' -f ($Path))

            # Check if $Path is valid
            [bool] $SuccessValidPath = $true
            if ($Path -like 'HKCU:\*') {$SuccessValidPath = $false}
            elseif ($Path -like 'HKLM:\*' -or $Path -like 'HKU:\') {
                $SuccessValidPath = -not ($Path -notlike 'HK*:\*' -or $Path -like '*:*:*' -or $Path -like '*\\*' -or $Path.Split(':')[0].Length -gt 4)       
            }
            elseif ($Path -like 'Registry::HKU\*') {
                $SuccessValidPath = -not ($Path -like '*\\*')
            }
            else {$SuccessValidPath = $false}
            if (-not($SuccessValidPath)){Throw 'Not a valid path! Will not continue.'}


            # Check if $Path exist, create it if not
            if (-not(Test-Path -Path $Path)){
                $null = New-Item -Path $Path -ItemType 'Directory' -Force
                Write-Verbose -Message ('   Path did not exist. Successfully created it? {0}.' -f (([bool] $Local:SuccessCreatePath = $?).ToString()))
                if (-not($Local:SuccessCreatePath)){Continue}
            }
        
            # Set Value / ItemPropery
            Set-ItemProperty -Path $Path -Name $Item.Name -Value $Item.Value -Type $Item.Type -Force
            Write-Verbose -Message ('   Name: {0} | Value: {1} | Type: {2} | Success? {3}' -f ($Item.Name,$Item.Value,$Item.Type,$?.ToString()))
        }
    #endregion Add
#endregion Set Registry Values from SYSTEM / DEVICE context


################################################
#endregion Your Code Here
################################################   
#region    Don't touch this
}
Catch {
    # Construct Message
    [string] $ErrorMessage = ('{0} finished with errors:' -f ($NameScriptFull))
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