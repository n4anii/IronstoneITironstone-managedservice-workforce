<#
    .SYNOPSIS
        Surpress Windows 10 Toast Notifications for some applications and Windows 10 features.


    .DESCRIPTION
        Surpress Windows 10 Toast Notifications for some applications and Windows 10 features.
            * Lenovo Vantage
            * Microsoft Cortana
            * Microsoft Edge
            * Microsoft News
            * Microsoft Store
            * Microsoft Skype for Business
            * Windows 10 \ BitLocker
            * Windows 10 \ Settings
            * Windows 10 \ Settings \ Display Settings
            * Windows 10 \ Settings \ Mobility Experience


    .NOTES
        Resources
          * https://blogs.technet.microsoft.com/platforms_lync_cloud/2017/05/05/disabling-windows-10-action-center-notifications/
#>

# Script Variables
[bool]   $DeviceContext = [bool]   $false
[string] $NameScript    = [string] 'Surpress-ToastNotifications'

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
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptFull' -Value ([string]('{0}_{1}' -f ($(if($DeviceContext){'Device'}else{'User'}),$NameScript)))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptVerb' -Value ([string]$NameScript.Split('-')[0])
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'NameScriptNoun' -Value ([string]$NameScript.Split('-')[-1])
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureProcess' -Value ([string]$(if([System.Environment]::Is64BitProcess){'64'}else{'32'}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrArchitectureOS' -Value ([string]$(if([System.Environment]::Is64BitOperatingSystem){'64'}else{'32'}))

# Dynamic Variables - User
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsAdmin'  -Value ([bool]$([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsSystem' -Value ([bool]$(([string]([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)) -eq ([string]('S-1-5-18'))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'BoolIsCorrectUser' -Value ([bool]$(if($DeviceContext -and $BoolIsSystem){$true}elseif(-not($DeviceContext) -and (-not($BoolIsSystem))){$true}else{$false}))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserNameRunningAs' -Value ([string]$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'StrUserNameSignedIn' -Value ([string]$(if($BoolIsSystem){if($BoolIsAdmin){Get-Process -Name 'explorer' -IncludeUserName | Select-Object -First 1 -ExpandProperty 'UserName'}}else{$StrUserNameRunningAs}))

# Dynamic Variables - Logging
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'Timestamp' -Value ([string]$([datetime]::Now.ToString('yyMMdd-HHmmssffff')))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathDirLog' -Value ([string]$('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($(if($DeviceContext -and $BoolIsCorrectUser){$env:ProgramW6432}else{$env:APPDATA}))))
$null = New-Variable -Option 'ReadOnly' -Scope 'Script' -Force -Name 'PathFileLog' -Value ([string]$('{0}{1}-{2}bit-{3}.txt' -f ($PathDirLog,$NameScriptFull,$StrArchitectureProcess,$Timestamp)))

# Start Transcript
if (-not(Test-Path -Path $PathDirLog)) {$null = New-Item -ItemType 'Directory' -Path $PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog

# Output User Info, Exit if not $BoolIsCorrectUser
Write-Output -InputObject ('Running as user "{0}". Has admin privileges? {1}. $DeviceContext = {2}. Running as correct user? {3}.' -f ($StrUserNameRunningAs,$BoolIsAdmin.ToString(),$DeviceContext.ToString(),$BoolIsCorrectUser.ToString()))
if (-not($BoolIsCorrectUser)){Throw 'Not running as correct user!'; Break}

# Output Process and OS Architecture Info
Write-Output -InputObject ('PowerShell is running as a {0} bit process on a {1} bit OS.' -f ($StrArchitectureProcess,$StrArchitectureOS))


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
        $PathRoot = [string]'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings'
        $Paths    = [string[]]@(
            [string]('{0}\E046963F.LenovoCompanion_k1h2ywk1493x8!App' -f $PathRoot),                                             # Lenovo Vantage
            [string]('{0}\Microsoft.Windows.Cortana_cw5n1h2txyewy!CortanaUI' -f $PathRoot),                                      # Microsoft Cortana
            [string]('{0}\Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge' -f $PathRoot),                                    # Microsoft Edge
            [string]('{0}\Microsoft.BingNews_8wekyb3d8bbwe!AppexNews' -f $PathRoot),                                             # Microsoft News
            [string]('{0}\Microsoft.WindowsStore_8wekyb3d8bbwe!App' -f $PathRoot),                                               # Microsoft Store
            [string]('{0}\Microsoft.Office.lync.exe.15' -f $PathRoot),                                                           # Microsoft Skype for Business
            [string]('{0}\Windows.SystemToast.BdeUnlock' -f $PathRoot),                                                          # Windows 10 \ BitLocker
            [string]('{0}\Windows.SystemToast.BitLockerPolicyRefresh' -f $PathRoot),                                             # Windows 10 \ BitLocker
            [string]('{0}\windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel' -f $PathRoot),    # Windows 10 \ Settings (aka Windows Immersive Control Panel)
            [string]('{0}\Windows.SystemToast.DisplaySettings' -f $PathRoot),                                                    # Windows 10 \ Settings \ Display Settings
            [string]('{0}\Windows.SystemToast.MobilityExperience' -f $PathRoot)                                                  # Windows 10 \ Settings \ Mobility Experience
        )
    #endregion Assets


    #region    Set Registry Values
        foreach ($Path in $Paths) {
            if (-not(Test-Path -Path $Path)) {$null = New-Item -Path $Path -ItemType 'Directory' -Force}
            $null = Set-ItemProperty -Path $Path -Name 'Enabled' -Value 0 -Type 'DWord' -Force
            Write-Verbose -Message ('   Success? {0}' -f ($?))
        }
    #endregion Set Registry Values




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