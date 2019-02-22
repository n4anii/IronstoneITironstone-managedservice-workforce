<#

.SYNOPSIS
Configures screen saver timeout value to 10, and enables secure lockscreen.

.DESCRIPTION
Configures screen saver timeout value to 10, and enables secure lockscreen.

.NOTES
You need to run this script in the USER context in Intune.

#>


# Script Variables
[bool]   $DeviceContext = $false
[string] $NameScript    = 'Set-PowerConfiguration_ScreenSaverWait(10min)'

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


    #region    EDIT THESE VALUES ONLY
        # Settings
        [uint16] $ScreenSaverTimoutInMinutes = 10
    #endregion EDIT THESE VALUES ONLY


    # Registry Value to Check / Write
    [string] $RegistryPath = 'HKCU:\SOFTWARE\IronstoneIT\Intune\DeviceConfiguration'
    [string] $RegistryKey  = 'UserSetPowerConfigurationScreenSaverWait'


    # Continue only if it's not been done earlier    
    if (Test-Path -Path ('{0}\{1}' -f ($RegistryPath,$RegistryKey))) {
        Write-Output -InputObject ('Registry {0} already set.' -f ($RegistryKey))
    }
    

    else {
        #Secure the lockscreen
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop'  -Name 'ScreenSaverIsSecure' -Value 1 -Type 'DWord' -Force
        Write-Output -InputObject ('Securing the lockscreen. Success? {0}.' -f ($?.ToString()))


        # Set screensaver to 15 minutes
        Write-Output -InputObject ('Setting screensaver to {0} min.' -f ($ScreenSaverTimoutInMinutes.ToString()))
                        
        Function Get-ScreenSaverTimeout {
            [Int32]$value = 0
            $null = $SystemParamInfo::SystemParametersInfo(14, 0, [REF]$value, 0)
            $($value / 60)
        }
        
        Function Set-ScreenSaverTimeout {
            Param ([Int32]$value)
            $seconds = $value * 60
            [Int32]$nullVar = 0
            $SystemParamInfo::SystemParametersInfo(15, $seconds, [REF]$nullVar, 2)
        }

        [string] $Signature = ('[DllImport("user32.dll")]{0}public static extern bool SystemParametersInfo(int uAction, int uParam, ref int lpvParam, int flags );' -f ("`r`n"))
        $SystemParamInfo = Add-Type -MemberDefinition  $Signature -Name 'ScreenSaver' -PassThru

        [bool] $Out = Set-ScreenSaverTimeout 15
        

        # If success, write to registry that settings were set.
        if ($Out) {
            Write-Output -InputObject ('Creating registry path "{0}" key "{1}".' -f $RegistryPath, $RegistryKey)
            $null = New-Item -Path ('{0}\{1}' -f ($RegistryPath,$RegistryKey)) -Force
        }
        else {
            Write-Output -InputObject ('Failed to set ScreenSaverWait.')
        }      
    }


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