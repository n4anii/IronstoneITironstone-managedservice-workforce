<#

.SYNOPSIS
Configures screen saver timeout value to 15, and enables secure lockscreen

.DESCRIPTION
Configures screen saver timeout value to 15, and enables secure lockscreen

.NOTES
You need to run this script in the USER context in Intune.

#>
$AppName = 'User_Set-ScreenSaverWait'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f $env:APPData)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$RegistryPath = 'HKCU:\SOFTWARE\IronstoneIT\Intune\DeviceConfiguration'
$RegistryKey = 'ConfigureScreenSaverWait'
$ErrorActionPreference = 'continue'

if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname


#Wrap in a try/catch, so we can always end the transcript
Try {

    #64-bit invocation
    if ($env:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
        write-Output -InputObject "Y'arg Matey, we're off to the 64-bit land....."
        if ($myInvocation.Line) {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
        }
        else {
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
        }
        exit $lastexitcode
    }


    #Secure the lockscreen
    if (!(Test-Path -Path ('{0}\{1}' -f $RegistryPath, $RegistryKey))) {
        #Secure the lockscreen
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop"  -Name "ScreenSaverIsSecure" -Value 1

        #Alter the time for the screensaver
        $signature = @"
[DllImport("user32.dll")]
public static extern bool SystemParametersInfo(int uAction, int uParam, ref int lpvParam, int flags );
"@
        $systemParamInfo = Add-Type -memberDefinition  $signature -Name ScreenSaver -passThru
 
        Function Get-ScreenSaverTimeout {
            [Int32]$value = 0
            $Null = $systemParamInfo::SystemParametersInfo(14, 0, [REF]$value, 0)
            $($value / 60)
        }
        Function Set-ScreenSaverTimeout {
            Param ([Int32]$value)
            $seconds = $value * 60
            [Int32]$nullVar = 0
            $systemParamInfo::SystemParametersInfo(15, $seconds, [REF]$nullVar, 2)
        }
        $Out = Set-ScreenSaverTimeout 15
        if ($out) {
            Write-Output -InputObject 'Successfully SatScreenSaverWait'
            $null = New-Item -Path ('{0}\{1}' -f $RegistryPath, $RegistryKey) -force
        }
        else {
            Write-Output -InputObject 'Failed to set ScreenSaverWait'
        }      
    }
    else {
        Write-Output -InputObject 'ScreenSaverWait already sat'
    }



}
Catch {
    # Construct Message
    $ErrorMessage = 'Unable to set screenSaverWait'
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
