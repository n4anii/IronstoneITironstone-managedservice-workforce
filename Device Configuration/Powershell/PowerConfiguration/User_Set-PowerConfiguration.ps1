<#

.SYNOPSIS
Configures powercfg "lid" action to "Do nothing" for DC and AC power.

.DESCRIPTION
Configures powercfg "lid" action to "Do nothing" for DC and AC power.

.NOTES
You need to run this script in the USER context in Intune.

#>
$AppName = 'User_Set-PowerConfiguration'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f $env:APPData)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$RegistryPath = 'HKCU:\SOFTWARE\IronstoneIT\Intune\DeviceConfiguration'
$RegistryKey = 'UserSetPowerConfiguration'
$ErrorActionPreference = 'continue'

if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname


#Wrap in a try/catch, so we can always end the transcript
Try {
    if (!(Test-Path -Path ('{0}\{1}' -f $RegistryPath, $RegistryKey))) {
        Write-Output 'Setting PowerCFG config'
        & "$env:windir\system32\powercfg.exe" -SETACVALUEINDEX "381b4222-f694-41f0-9685-ff5bb260df2e" "4f971e89-eebd-4455-a8de-9e59040e7347" "5ca83367-6e45-459f-a27b-476b1d01c936" 000
        & "$env:windir\system32\powercfg.exe" -SETDCVALUEINDEX "381b4222-f694-41f0-9685-ff5bb260df2e" "4f971e89-eebd-4455-a8de-9e59040e7347" "5ca83367-6e45-459f-a27b-476b1d01c936" 000
        Write-Output -InputObject ('Creating registry path {0} key {1}' -f $RegistryPath, $RegistryKey)
        $null = New-Item -Path ('{0}\{1}' -f $RegistryPath, $RegistryKey) -force
    }
    else {
        Write-Output -InputObject ('Registry {0} already set' -f $RegistryKey)
    }
}
Catch {
    # Construct Message
    $ErrorMessage = 'Unable to change powercfg configuration'
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
