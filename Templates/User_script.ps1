<#

.SYNOPSIS


.DESCRIPTION


.NOTES
You need to run this script in the USER context in Intune.

#>

$AppName = 'User_Set-LocalUserCulture'
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
    Import-Module -Name International
    $CurrentCulture = Get-Culture
    #Exit if the culture is not English or Norwegian
    If ($CurrentCulture.Name -eq 'nb-NO' -or $CurrentCulture.Name -eq 'en-US') {
        #If English, set new culture
        if ($CurrentCulture.Name -eq 'en-US') {
            $RegInstallDate = (get-itemproperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion').InstallDate
            $Installdate = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($RegInstallDate))
            $CurrentDate = (Get-date )
            $Timespan = New-Timespan -Start $Installdate -End $CurrentDate
            [string]$HumanTimespan = ('Days: {0}. Hours: {1}' -f $Timespan.days, $Timespan.hours)
      
            if ($timespan.days -lt 1) {
                Write-Output -InputObject ('Setting culture to 1044')
                Set-Culture -CultureInfo 1044
            }
            else {
                Write-Output -InputObject ('Timespan is outside the allowed range of one day. Timespan is [{0}].' -f $HumanTimespan)
            }
        }
        else {
            Write-Output -InputObject ('Culture is [{0}], exiting.' -f $CurrentCulture)
        }
    }
    else {
        Write-Output -InputObject ('Culture is [{0}], exiting.' -f $CurrentCulture)
    }
}
Catch {
    # Construct Message
    $ErrorMessage = 'Unable to set users culture to 1044'
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
