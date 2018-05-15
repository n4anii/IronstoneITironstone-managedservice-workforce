<#

.SYNOPSIS
Set's the current users Culture to NB-NO, if the current culture is English. 

.DESCRIPTION
Set's the current users Culture to NB-NO, if the current culture is English.  There's a small check that will make sure the script is only ran on new computers. 

.NOTES
You need to run this script in the USER context in Intune.

#>

$AppName = 'User_Set-LocalUserCulture'
$Timestamp = Get-Date -Format 'HHmmssffff'
$LogDirectory = ('{0}\IronstoneIT\Intune\DeviceConfiguration' -f $env:APPData)
$Transcriptname = ('{2}\{0}_{1}.txt' -f $AppName, $Timestamp, $LogDirectory)
$RegistryPath = 'HKCU:\SOFTWARE\IronstoneIT\Intune\DeviceConfiguration'
$RegistryKey = 'UserSetCultureLanguage'
$ErrorActionPreference = 'continue'

if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -ErrorAction Stop
}

Start-Transcript -Path $Transcriptname


#Wrap in a try/catch, so we can always end the transcript
Try {
    if (!(Test-Path -Path ('{0}\{1}' -f $RegistryPath, $RegistryKey))) {
        Import-Module -Name International
        $CurrentCulture = Get-Culture
        #Exit if the culture is not English or Norwegian
        If ($CurrentCulture.Name -eq 'nb-NO' -or $CurrentCulture.Name -eq 'en-US') {
            #If English, set new culture
            if ($CurrentCulture.Name -eq 'en-US') {
                    Write-Output -InputObject ('Setting culture to 1044')
                    Set-Culture -CultureInfo 1044
                    Write-Output -InputObject ('Creating registry path {0} key {1}' -f $RegistryPath, $RegistryKey)
                    $null = New-Item -Path ('{0}\{1}' -f $RegistryPath, $RegistryKey) -force
            }
            else {
                Write-Output -InputObject ('Culture is [{0}], exiting.' -f $CurrentCulture)
            }
        }
        else {
            Write-Output -InputObject ('Culture is [{0}], exiting.' -f $CurrentCulture)
        }
	         
    }
    else {
        Write-Output -InputObject 'Registry culture already set, exiting'
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
