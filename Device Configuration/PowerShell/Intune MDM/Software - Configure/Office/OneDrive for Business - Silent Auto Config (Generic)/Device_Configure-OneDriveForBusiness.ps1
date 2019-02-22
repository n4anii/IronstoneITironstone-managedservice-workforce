<#
.NAME
Configure-OneDriveForBusiness

.SYNOPSIS
Auto configures OneDrive for Business. Enables "FilesOnDemand","ADAL", and "SilentAutoConfig".

.DESCRIPTION
Auto configures OneDrive for Business
- Enables ADAL             (HKCU:\) User
- ENables FilesOnDemand    (HKLM:\) Device
- Enables SilentAutoConfig (HKLM:\) Device

.NOTES
You need to run this script in the DEVICE context in Intune.
#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Configure-OneDriveForBusiness'

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
[string] $NameScriptFull      = ('{0}_{1}' -f ($(if($DeviceContext){'Device'}Else{'User'}),$NameScript))
[string] $NameScriptVerb      = $NameScript.Split('-')[0]
[string] $NameScriptNoun      = $NameScript.Split('-')[-1]
[string] $ProcessArchitecture = $(if([System.Environment]::Is64BitProcess){'64'}Else{'32'})
[string] $OSArchitecture      = $(if([System.Environment]::Is64BitOperatingSystem){'64'}Else{'32'})

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



    #region    Get HKU\ path for current user 
        # Get Current User as SecurityIdentifier
        if (-not($Script:PathDirRootCU)){
            [string] $Script:PathDirRootCU = ('Registry::HKU\{0}\' -f ([System.Security.Principal.NTAccount]::new(@(Get-Process -Name 'explorer' -IncludeUserName)[0].UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value))
            if((-not($?)) -or [string]::IsNullOrEmpty($Script:PathDirRootCU) -or $Script:PathDirRootCU -like '*\\*'){Throw 'ERROR: Must be admin to get username from "Get-Process -IncludeUserName".';Break}
        }
    #endregion Get HKU\ path for current user 



    #region    Registry Variables
    [PSCustomObject[]] $RegValues = @(
        [PSCustomObject]@{Path=[string]'HKCU:\SOFTWARE\Microsoft\OneDrive';          Name=[string]'EnableADAL';           Value=[byte]1; Type=[string]'DWord'},
        [PSCustomObject]@{Path=[string]'HKLM:\Software\Policies\Microsoft\OneDrive'; Name=[string]'FilesOnDemandEnabled'; Value=[byte]1; Type=[string]'DWord'},
        [PSCustomObject]@{Path=[string]'HKLM:\Software\Policies\Microsoft\OneDrive'; Name=[string]'SilentAccountConfig';  Value=[byte]1; Type=[string]'DWord'}
    )
    #endregion Registry Variables



    #region    Set Registry Values from SYSTEM / DEVICE context
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
    #endregion Set Registry Values from SYSTEM / DEVICE context


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