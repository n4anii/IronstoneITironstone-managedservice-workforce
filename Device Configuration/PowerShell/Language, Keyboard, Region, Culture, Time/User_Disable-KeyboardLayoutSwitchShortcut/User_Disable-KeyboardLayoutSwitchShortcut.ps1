<#

.SYNOPSIS
    Disables Hotkeys for Layout and Language Switch/ Toggle (ctrl+shift etc). WIN+SPACE is still functional.


.DESCRIPTION


.NOTES
    * You need to run this script in the USER context in Intune.
    * Only edit $NameScript and add your code in the #region Your Code Here

#>


# Script Variables
$NameScript  = 'User_Disable-KeyboardLayoutSwitchShortcut'
$Timestamp   = [DateTime]::Now.ToString('yyMMdd-HHmmssffff')
$PathDirLog  = ('{0}\IronstoneIT\Intune\DeviceConfiguration\' -f ($env:APPData))
$PathFileLog = ('{0}{1}-{2}.txt' -f ($PathDirLog,$NameScript,$Timestamp))


# Settings - PowerShell Preferences - Interaction
$ConfirmPreference     = 'None'
$ProgressPreference    = 'SilentlyContinue'
# PowerShell Settings - Output Variables
$DebugPreference       = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'
$InformationPreference = 'SilentlyContinue'
$VerbosePreference     = 'SilentlyContinue'
$WarningPreference     = 'SilentlyContinue'


# Start Transcript
if (-not(Test-Path -Path $PathDirLog)) {New-Item -ItemType 'Directory' -Path $PathDirLog -ErrorAction 'Stop'}
Start-Transcript -Path $PathFileLog


# Wrap in Try/Catch, so we can always end the transcript
Try {
################################################
#region    Your Code Here
################################################


# Disables Layout and Language Hotkeys (ctrl+shift etc).       WILL NOT DISABLE WIN+SPACE
[PSCustomObject[]] $Keys = @(
    [PSCustomObject]@{Name=[string]'Hotkey';         Val=[string]'3';Type=[string]'String'},
    [PSCustomObject]@{Name=[string]'Language Hotkey';Val=[string]'3';Type=[string]'String'},
    [PSCustomObject]@{Name=[string]'Layout Hotkey';  Val=[string]'3';Type=[string]'String'}
)

foreach ($Key in $Keys) {
    $null = Set-ItemProperty -Path 'HKCU:\Keyboard Layout\Toggle' -Name $Key.Name -Value $Key.Val -Type $Key.Type -Force
    Write-Output -InputObject ('Success setting {0}? {1}.' -f ($Key.Name,$?))
}



################################################
#endregion Your Code Here
################################################   
}
Catch {
    # Construct Message
    $ErrorMessage = ('"{0}" finished with errors.' -f ($NameScript))
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