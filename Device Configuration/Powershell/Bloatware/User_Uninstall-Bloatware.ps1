<#

.SYNOPSIS
Removes all specified pre-installed applications from the users profile.

.DESCRIPTION
Removes all specified pre-installed applications from the users profile. This script MUST be deployed together with Device_Uninstall-Bloatware.ps1, else the apps will come back.

.NOTES
You need to run this script in the USER context in Intune.

#>
$AppName = 'User_Uninstall_Bloatware'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f $env:APPData)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
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
        }else{
            &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file ('{0}' -f $myInvocation.InvocationName) $args
        }
      exit $lastexitcode
    }

    #Remove bloatware
    $Installdate = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($(get-itemproperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion').InstallDate))
    $CurrentDate = Get-date 
    $Timespan = New-Timespan -Start $Installdate -End $CurrentDate
    [string]$HumanTimespan = ('Days: {0}. Hours: {1}' -f $Timespan.days, $Timespan.hours)
    
    if ($timespan.days -lt 1) {
        $BloatWares = '*D5EA27B7.Duolingo-LearnLanguagesforFree*','*Microsoft.BingNews*','*46928bounde.EclipseManager*','Microsoft.Office.OneNote','*Minecraft*','*DrawboardPDF*','*FarmVille2CountryEscape*','*Asphalt8Airborne*','*PandoraMediaInc*','*CandyCrushSodaSaga*','*MicrosoftSolitaireCollection*','*Twitter*','*bingsports*','*bingfinance*','*BingNews*','*windowsphone*','*Netflix*','*ZuneVideo*','*Facebook*','*Microsoft.SkypeApp','*ZuneMusic*','*Microsoft.MinecraftUWP*,*OneNote*','*MarchofEmpires*','*RoyalRevolt2*','*AdobePhotoshopExpress*','*ActiproSoftwareLLC*','*Duolingo-LearnLanguagesforFree*','*EclipseManager*','*KeeperSecurityInc.Keeper*','*king.com.BubbleWitch3Sag*','*89006A2E.AutodeskSketchBook*','*CAF9E577.Plex*'
        Foreach ($BloatWare in $BloatWares) {
            Write-Output -InputObject ('Removing AppxPackage [{0}].' -f $BloatWare)
            Get-AppxPackage -Name $bloatware | Remove-AppxPackage
        }
    }
    else {
        Write-Output -InputObject ('Timespan is outside the allowed range of one day. Timespan is [{0}].' -f $HumanTimespan)
    }
}
Catch {
    # Construct Message
    $ErrorMessage = 'Unable to uninstall all apps'
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
Finally
{
    Stop-Transcript
}
