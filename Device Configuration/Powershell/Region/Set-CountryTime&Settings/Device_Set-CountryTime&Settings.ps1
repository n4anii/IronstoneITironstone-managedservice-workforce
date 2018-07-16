<# 
.NAME
    Device_Set-CountryTime&Settings

.SYNAPSIS
    Sets culture, locale, time zone, enables automatic time sync and adjustment of time zone, and forces time resync.

.RESOURCES
    http://www.thewindowsclub.com/windows-10-clock-time-wrong-fix
#>


# Script Variables
[bool]   $DeviceContext = $true
[string] $NameScript    = 'Set-CountryTime&Settings'

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


    $CultureNameWanted = 'nb-NO'
    $LocaleLCIDWanted  = '1044'
    $TimeZoneIdWanted  = 'W. Europe Standard Time'


    # Culture - Format for time, date etc
    Write-Output -InputObject ('Current Culture:   {0}' -f (($CultureCurrent = Get-Culture).DisplayName))
    if ($CultureCurrent.Name -ne $CultureNameWanted) {
        Set-Culture -CultureInfo $CultureNameWanted
        Write-Output -InputObject ('   Changed to {0}' -f ($CultureNameWanted))
    }


    # Locale - Format for time, date etc
    Write-Output -InputObject ('Current Locale:    {0}' -f (($LocaleCurrent = Get-WinSystemLocale).DisplayName))
    if ($LocaleCurrent.LCID -ne $LocaleLCIDWanted) {
        Set-WinSystemLocale -SystemLocale $CultureNameWanted
        Write-Output -InputObject ('   Changed to {0}' -f ($CultureNameWanted))
    }


    # TimeZone
    Write-Output -InputObject ('Current TimeZone:  {0}' -f (($TimeZoneCurrent = Get-TimeZone).Id))
    if ($TimeZoneCurrent.Id -ne $TimeZoneIdWanted) {
        Set-TimeZone -Id $TimeZoneIdWanted
        Write-Output -InputObject ('   Changed to {0}' -f ($TimeZoneIdWanted))
    }


    # NTP Servers - Set default Microsoft NTP Servers & Add 'no.pool.ntp.org' and 'time.google.com' as backup servers
    $PathDirReg    = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers'
    $URLNTPServers = @('time.windows.com','time.nist.gov','no.pool.ntp.org','time.google.com')
    $C = [byte]::MinValue + 1
    foreach ($URL in $URLNTPServers) {
        Set-ItemProperty -Path $PathDirReg -Name $C.ToString() -Value $URL -Type 'String'
        Write-Output -InputObject ('Adding "{0}" as time server number {1}.' -f ($URL,($C++).ToString()))
    }


    # Make sure "Set time automatically" is enabled
    $null = Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters' -Name 'Type' -Value 'NTP' -Type 'String' -Force

    # Make sure "Set time zone automatically" is disabled                    (3 = Enabled, 4 = Disabled)
    $null = Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate' -Name 'Start' -Value 4 -Type 'DWord' -Force

    # Make sure "Adjust for daylight saving time automatically" is enabled   (0 = Enabled, 1 = Disabled)
    $null = Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'DynamicDaylightTimeDisabled' -Value 0 -Type 'DWord' -Force


    # Resync time
    $null = Start-Process -FilePath ('{0}\w32tm.exe' -f ([System.Environment]::SystemDirectory)) -ArgumentList ('/resync /force') -NoNewWindow


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